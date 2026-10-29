'use strict';
// Operator-only live check. Uses one disposable identity, seeded test challenges
// and no outbound mail. This validates deployed state/rules, not inbox delivery.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const project = 'harvesthub-80047';
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const endpoint = 'https://script.google.com/macros/s/AKfycbzrVxOkY9A-HQHLRCSSUdPxepUHUp-yy4H619oIe-gWZaGNXWoBxfRTvvq2L57gVi2I/exec';
async function main() {
  const config = JSON.parse(fs.readFileSync(path.join(root, '.local-backups/backend.secrets.json'), 'utf8'));
  const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  const access = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const request = async (url, method = 'GET', body, token) => {
    let response;
    for (let attempt = 0; attempt < 4; attempt++) {
      try {
        response = await fetch(url, {method, headers: {'Content-Type':'application/json', ...(token ? {Authorization:`Bearer ${token}`} : {})}, body:body === undefined ? undefined : JSON.stringify(body), signal:AbortSignal.timeout(90000)});
        break;
      } catch (error) {
        // A connection timeout occurs before the request is sent.
        if (error.cause?.code !== 'UND_ERR_CONNECT_TIMEOUT' || attempt === 3) throw error;
      }
    }
    const result = await response.json();
    if (!response.ok) throw Error(`API request failed (${response.status})`);
    return result;
  };
  const owner = (url, method, body) => request(url, method, body, access.access_token);
  const fb = (action, data) => request(`https://identitytoolkit.googleapis.com/v1/accounts:${action}?key=${config.FIREBASE_WEB_API_KEY}`, 'POST', data);
  const api = (action, idToken, data) => request(endpoint, 'POST', {action,idToken,data});
  if (process.argv.includes('--cleanup')) {
    const rows = await owner(`${base}:runQuery`, 'POST', {structuredQuery:{from:[{collectionId:'users'}],where:{fieldFilter:{field:{fieldPath:'testOnly'},op:'EQUAL',value:{booleanValue:true}}},limit:100}});
    let removed = 0;
    for (const row of rows) {
      const doc = row.document;
      if (!doc || doc.fields.name?.stringValue !== 'Disposable 2FA check' || !/^hh-2fa-test-[a-f0-9]{20}@example\.test$/.test(doc.fields.email?.stringValue || '')) continue;
      const fixtureUid = doc.name.split('/').at(-1);
      const found = await owner(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:lookup`,'POST',{localId:[fixtureUid]});
      if (found.users?.length) await owner(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:delete`,'POST',{localId:fixtureUid});
      for (const collection of ['users','emailSecurityChallenges']) await owner(`${base}/${collection}/${fixtureUid}`,'DELETE');
      removed++;
    }
    console.log(JSON.stringify({disposableFixturesRemoved:removed}));
    return;
  }
  const fields = data => Object.fromEntries(Object.entries(data).map(([key, value]) => [key, typeof value === 'boolean' ? {booleanValue:value} : typeof value === 'number' ? {integerValue:String(value)} : {stringValue:value}]));
  const email = `hh-2fa-test-${crypto.randomBytes(10).toString('hex')}@example.test`;
  const password = `Hh9${crypto.randomBytes(24).toString('hex')}`;
  let uid, token, cleaned = false;
  try {
    const created = await fb('signUp', {email,password,returnSecureToken:true});
    uid = created.localId; token = created.idToken;
    console.log('Disposable identity created.');
    await owner(`${base}/users/${uid}`, 'PATCH', {fields:fields({email,active:true,role:'customer',testOnly:true,email2faEnabled:true,securityVersion:0,name:'Disposable 2FA check'})});
    const dataStatus = async idToken => {
      try { await request(`${base}/categories?pageSize=1`, 'GET', undefined, idToken); return 200; }
      catch (error) { if (error.message === 'API request failed (403)') return 403; throw error; }
    };
    assert.equal(await dataStatus(token), 403);
    console.log('Enabled account blocks password-only data access.');
    const bad = await api('startEmailVerification', token, {purpose:'disable',password:'IncorrectTestPassword9'});
    assert.equal(bad.error?.code, 'unauthenticated');
    console.log('Incorrect password rejected without sending mail.');
    const change = async (purpose, version) => {
      const challengeId = crypto.randomBytes(24).toString('hex');
      const code = String(crypto.randomInt(1000000)).padStart(6,'0');
      const now = Date.now();
      const claims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url'));
      await owner(`${base}/emailSecurityChallenges/${uid}`, 'PATCH', {fields:fields({id:challengeId,purpose,email,version,authTime:claims.auth_time,passwordProofAt:now,createdAt:now,expiresAt:now+1800000,attempts:0,state:'sent',hash:crypto.createHmac('sha256',config.OTP_SECRET).update(JSON.stringify([uid,challengeId,purpose,code])).digest('hex')})});
      const wrong = await api('verifyEmailCode',token,{challengeId,code:code==='000000'?'111111':'000000'});
      assert.equal(wrong.error?.code,'permission-denied', `Wrong-code rejection for ${purpose}: ${JSON.stringify({keys:Object.keys(wrong),error:wrong.error?.code,enabled:wrong.data?.enabled})}`);
      const result = await api('verifyEmailCode',token,{challengeId,code});
      if (result.error) throw Error(`Verification failed (${result.error.code})`);
      assert.equal(result.data.enabled,purpose==='enroll');
      const signed = await fb('signInWithCustomToken',{token:result.data.token,returnSecureToken:true});
      token = signed.idToken;
      assert.equal(await dataStatus(token),200);
      const reused = await api('verifyEmailCode',token,{challengeId,code});
      assert.equal(reused.error?.code,'permission-denied', `Reuse rejection for ${purpose}: ${JSON.stringify({keys:Object.keys(reused),error:reused.error?.code,enabled:reused.data?.enabled})}`);
      const profile = await owner(`${base}/users/${uid}`);
      assert.equal(profile.fields.email2faEnabled.booleanValue,purpose==='enroll');
      assert.equal(Number(profile.fields.securityVersion.integerValue),version+1);
    };
    await change('disable',0);
    console.log('Disable verified and saved.');
    token = (await fb('signInWithPassword',{email,password,returnSecureToken:true})).idToken;
    assert.equal(await dataStatus(token),200);
    await change('enroll',1);
    console.log('Enable verified and saved.');
    token = (await fb('signInWithPassword',{email,password,returnSecureToken:true})).idToken;
    assert.equal(await dataStatus(token),403);
    console.log(JSON.stringify({liveDisable:true,passwordSignInWhenDisabled:true,liveReenable:true,passwordOnlyBlockedWhenEnabled:true,wrongPasswordRejected:true,wrongCodeAndReuseRejected:true,mailSent:false}));
  } finally {
    if (uid) {
      // uid was created by this invocation; never accept a caller-selected UID.
      await owner(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:delete`,'POST',{localId:uid});
      for (const collection of ['users','emailSecurityChallenges']) await owner(`${base}/${collection}/${uid}`,'DELETE');
      cleaned = true;
    }
    console.log(JSON.stringify({disposableIdentityRemoved:cleaned}));
  }
}
main().catch(error => { console.error('Live 2FA check failed: ' + error.message + ' ' + (error.cause?.code || '')); process.exitCode=1; });
