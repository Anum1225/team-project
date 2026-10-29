'use strict';
// Operator-only live checks, restricted to one locally tracked disposable
// fixture. No passwords, Firebase tokens, OTPs or device tokens are printed.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const project = 'harvesthub-80047';
const endpoint = 'https://script.google.com/macros/s/AKfycbzrVxOkY9A-HQHLRCSSUdPxepUHUp-yy4H619oIe-gWZaGNXWoBxfRTvvq2L57gVi2I/exec';
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
const statePath = path.join(root, '.local-backups/backend-smoke.json');
async function main() {
  const config = JSON.parse(fs.readFileSync(path.join(root, '.local-backups/backend.secrets.json'), 'utf8'));
  const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  const access = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const call = async (url, method = 'GET', body, owner = false) => {
    const response = await fetch(url, { method, headers: { 'Content-Type': 'application/json', ...(owner ? { Authorization: `Bearer ${access.access_token}`, 'x-goog-user-project': project } : {}) }, body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(90000) });
    const result = await response.json();
    if (!response.ok) throw Error(`API failed (${response.status}, ${result.error?.status || 'request'})`);
    return result;
  };
  const fbAuth = (action, body) => call(`https://identitytoolkit.googleapis.com/v1/accounts:${action}?key=${config.FIREBASE_WEB_API_KEY}`, 'POST', body);
  const api = (action, idToken, data = {}) => call(endpoint, 'POST', { action, idToken, data });
  const read = async p => {
    const doc = await call(`${base}/${p}`, 'GET', undefined, true);
    return Object.fromEntries(Object.entries(doc.fields || {}).map(([k,v]) => [k, v.stringValue ?? (v.integerValue !== undefined ? Number(v.integerValue) : v.booleanValue)]));
  };
  const save = state => fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
  const fixture = () => {
    const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
    if (!state.email.startsWith('noobgamerabduljabber+harvesthub-smoke-') || !state.uid) throw Error('Invalid test identity.');
    return state;
  };
  if (process.argv.includes('--health')) {
    assert.equal((await call(endpoint)).service, 'HarvestHub');
    assert.equal((await api('assistant', 'invalid', { history: [{ user: true, text: 'Hello' }] })).error.code, 'unauthenticated');
    console.log(JSON.stringify({ health: true, invalidTokenRejected: true }));
  }
  if (process.argv.includes('--create')) {
    if (fs.existsSync(statePath)) throw Error('Test identity already tracked; reuse it.');
    const state = { email: `noobgamerabduljabber+harvesthub-smoke-${Date.now()}@gmail.com`, password: `Hh${crypto.randomBytes(24).toString('hex')}9a` };
    const user = await fbAuth('signUp', { ...state, returnSecureToken: true });
    Object.assign(state, { uid: user.localId, idToken: user.idToken }); save(state);
    await call(`${base}/users/${state.uid}`, 'PATCH', { fields: { name: { stringValue: 'HarvestHub backend verification' }, email: { stringValue: state.email }, role: { stringValue: 'customer' }, active: { booleanValue: true }, testOnly: { booleanValue: true }, securityVersion: { integerValue: '0' }, createdAt: { timestampValue: new Date().toISOString() } } }, true);
    console.log(JSON.stringify({ disposableTestIdentityCreated: true }));
  }
  if (process.argv.includes('--enroll')) {
    const state = fixture();
    const result = await api('startEmailVerification', state.idToken, { purpose: 'enroll', password: state.password });
    if (result.error) throw Error(`Enrollment failed: ${result.error.code}`);
    state.challengeId = result.data.challengeId; save(state);
    console.log(JSON.stringify({ enrollmentEmailSent: true, maskedRecipient: result.data.maskedEmail }));
  }
  if (process.argv.includes('--login')) {
    const state = fixture();
    const signed = await fbAuth('signInWithPassword', { email: state.email, password: state.password, returnSecureToken: true });
    state.idToken = signed.idToken; save(state);
    const blocked = await api('assistant', state.idToken, { history: [{ user: true, text: 'Hello' }] });
    assert.equal(blocked.error.code, 'permission-denied');
    const result = await api('startEmailVerification', state.idToken, { purpose: 'login' });
    if (result.error) throw Error(`Login email failed: ${result.error.code}`);
    state.challengeId = result.data.challengeId; save(state);
    console.log(JSON.stringify({ passwordOnlyAccessRejected: true, loginEmailSent: true }));
  }
  if (process.argv.includes('--check-disable-blocked')) {
    const state = fixture();
    const result = await api('startEmailVerification', state.idToken, { purpose: 'disable', password: state.password });
    assert.equal(result.error?.code, 'permission-denied');
    assert.equal((await read(`users/${state.uid}`)).email2faEnabled, true);
    console.log(JSON.stringify({ disableRejected: true, verificationStillRequired: true }));
  }
  if (process.argv.includes('--check-code-lifetime')) {
    const state = fixture();
    const profile = await read(`users/${state.uid}`);
    assert.equal(profile.testOnly, true); assert.equal(profile.email, state.email);
    const c = await read(`emailSecurityChallenges/${state.uid}`);
    assert.equal(c.id, state.challengeId);
    assert.equal(c.expiresAt - c.createdAt, 30 * 60000);
    const resumed = await api('startEmailVerification', state.idToken, { purpose: c.purpose, ...(c.purpose === 'login' ? {} : { password: state.password }) });
    if (resumed.error) throw Error(`Code resume failed: ${resumed.error.code}`);
    assert.equal(resumed.data.challengeId, c.id);
    assert.equal(resumed.data.expiresAt, c.expiresAt);
    console.log(JSON.stringify({ codeLifetimeMinutes: 30, screenResumeKeepsCode: true }));
  }
  if (process.argv.includes('--verify-fixture')) {
    const state = fixture();
    const profile = await read(`users/${state.uid}`);
    assert.equal(profile.testOnly, true); assert.equal(profile.email, state.email);
    const c = await read(`emailSecurityChallenges/${state.uid}`);
    assert.equal(c.id, state.challengeId); assert.equal(c.email, state.email);
    // White-box verification of this disposable fixture only. MailApp delivery
    // is tested separately; never claim this confirms inbox receipt.
    const code = String(parseInt(crypto.createHmac('sha256', config.OTP_SECRET).update(`otp:${c.id}:${c.createdAt}`).digest('hex').slice(0, 12), 16) % 1000000).padStart(6, '0');
    const result = await api('verifyEmailCode', state.idToken, { challengeId: c.id, code });
    if (result.error) throw Error(`Code verification failed: ${result.error.code}`);
    const signed = await fbAuth('signInWithCustomToken', { token: result.data.token, returnSecureToken: true });
    state.idToken = signed.idToken; save(state);
    const claims = JSON.parse(Buffer.from(signed.idToken.split('.')[1], 'base64url'));
    assert.equal(claims.hh_email_2fa, true); assert.equal(claims.hh_verified_email, state.email);
    const reused = await api('verifyEmailCode', state.idToken, { challengeId: c.id, code });
    assert.equal(reused.error.code, 'permission-denied');
    console.log(JSON.stringify({ emailCodeVerified: true, customTokenAccepted: true, reuseRejected: true, enabled: result.data.enabled }));
  }
  if (process.argv.includes('--assistant')) {
    const state = fixture();
    const result = await api('assistant', state.idToken, { history: [{ user: true, text: 'What products and farms are available in HarvestHub? Include prices in rupees and tell me how to follow a farm.' }] });
    if (result.error) throw Error(`Assistant failed: ${result.error.code}`);
    assert.ok(result.data.text?.length > 30);
    console.log(JSON.stringify({ liveAssistantAnswered: true, answer: result.data.text }));
  }
  if (process.argv.includes('--examples') || process.argv.includes('--quality-prompts')) {
    const state = fixture();
    const questions = process.argv.includes('--quality-prompts') ? ['How should tomatoes be stored?', 'Which vegetables are seasonal right now?'] : ['Which fruits are rich in Vitamin C?', 'How should tomatoes be stored?', 'Which vegetables are seasonal right now?', 'What are the health benefits of spinach?', 'Suggest vegetables for a healthy salad.'];
    for (const question of questions) {
      const result = await api('assistant', state.idToken, { history: [{ user: true, text: question }] });
      if (result.error) throw Error(`Example failed: ${result.error.code}`);
      assert.ok(result.data.text?.length > 30);
      console.log(JSON.stringify({ liveProxyExample: question, answer: result.data.text }));
    }
  }
  if (process.argv.includes('--check-required-data')) {
    const state = fixture();
    const profile = await read(`users/${state.uid}`);
    assert.equal(profile.testOnly, true); assert.equal(profile.email, state.email);
    const passwordOnly = await fbAuth('signInWithPassword', { email: state.email, password: state.password, returnSecureToken: true });
    const status = async token => {
      const response = await fetch(`${base}/categories?pageSize=1`, {headers:{Authorization:`Bearer ${token}`},signal:AbortSignal.timeout(60000)});
      await response.arrayBuffer();
      return response.status;
    };
    assert.equal(await status(passwordOnly.idToken), 403);
    assert.equal(await status(state.idToken), 200);
    console.log(JSON.stringify({ passwordOnlyDataDenied: true, emailVerifiedDataAllowed: true }));
  }
  if (process.argv.includes('--cleanup')) {
    const state = fixture();
    const profile = await read(`users/${state.uid}`);
    assert.equal(profile.testOnly, true); assert.equal(profile.email, state.email);
    await call(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:delete`, 'POST', { localId: state.uid }, true);
    for (const p of [`users/${state.uid}`, `emailSecurityChallenges/${state.uid}`, `emailSecurityLimits/${state.uid}`, `backendLimits/${state.uid}_assistant`, `backendLimits/${state.uid}_sync`]) {
      const response = await fetch(`${base}/${p}`, { method: 'DELETE', headers: { Authorization: `Bearer ${access.access_token}`, 'x-goog-user-project': project } });
      if (!response.ok && response.status !== 404) throw Error('Fixture cleanup failed.');
    }
    fs.unlinkSync(statePath);
    console.log(JSON.stringify({ disposableTestIdentityRemoved: true }));
  }
  if (process.argv.includes('--sync')) {
    const state = fixture(), start = Date.now();
    const result = await api('syncNotifications', state.idToken);
    if (result.error) throw Error(`Notification sync failed: ${result.error.code}`);
    console.log(JSON.stringify({ notificationSync: result.data.synced, elapsedMs: Date.now() - start }));
  }
  if (process.argv.includes('--device-count')) {
    const rows = await call(`${base}:runQuery`, 'POST', { structuredQuery: { from: [{ collectionId: 'devices', allDescendants: true }], limit: 50 } }, true);
    console.log(JSON.stringify({ registeredDevices: rows.filter(r => r.document).length }));
  }
  if (process.argv.includes('--validate-push')) {
    const rows = await call(`${base}:runQuery`, 'POST', { structuredQuery: { from: [{ collectionId: 'devices', allDescendants: true }], limit: 1 } }, true);
    const doc = rows.find(r => r.document)?.document;
    if (!doc) throw Error('No registered device for FCM validation.');
    const token = doc.name.split('/').pop();
    const sent = await call(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`, 'POST', { validate_only: true, message: { token, notification: { title: 'HarvestHub delivery check', body: 'Validation only; this is not sent.' } } }, true);
    console.log(JSON.stringify({ fcmValidationAccepted: !!sent.name }));
  }
  if (process.argv.includes('--match-owner-device')) {
    const rows = await call(`${base}:runQuery`, 'POST', { structuredQuery: { from: [{ collectionId: 'devices', allDescendants: true }], limit: 50 } }, true);
    let matched = 0;
    for (const row of rows.filter(r => r.document)) {
      const uid = row.document.name.split('/documents/users/')[1].split('/')[0];
      const profile = await read(`users/${uid}`);
      if (profile.email?.toLowerCase() === 'noobgamerabduljabber@gmail.com' && profile.active) matched++;
    }
    console.log(JSON.stringify({ registeredDevicesForOwnerEmail: matched }));
  }
  if (process.argv.includes('--push-result')) {
    const request = await call(`${base}/backendChecks/pushDelivery`, 'GET', undefined, true);
    const accepted = !!request.fields.acceptedAt?.timestampValue;
    let persisted = false;
    if (accepted) {
      const notice = await read(`users/${request.fields.uid.stringValue}/notifications/${request.fields.eventId.stringValue}`);
      persisted = notice.pushDelivered === true;
    }
    console.log(JSON.stringify({ deliveryCheckCompleted: accepted, notificationPersistedAndSent: persisted }));
  }
  if (process.argv.includes('--prepare-push-check')) {
    const email = process.argv[process.argv.indexOf('--prepare-push-check') + 1];
    if (!email || email.startsWith('--') || !email.includes('@')) throw Error('Supply the owner-selected notification account email.');
    const users = await call(`${base}:runQuery`, 'POST', { structuredQuery: { from: [{ collectionId: 'users' }], where: { fieldFilter: { field: { fieldPath: 'email' }, op: 'EQUAL', value: { stringValue: email } } }, limit: 2 } }, true);
    const docs = users.filter(r => r.document);
    assert.equal(docs.length, 1, 'The selected account must be unique.');
    const uid = docs[0].document.name.split('/').pop();
    const devices = await call(`${base}/users/${uid}/devices`, 'GET', undefined, true);
    assert.ok(devices.documents?.length, 'Enable notifications on the selected account first.');
    await call(`${base}/backendChecks/pushDelivery`, 'PATCH', { fields: { uid: { stringValue: uid }, eventId: { stringValue: `delivery_check_${crypto.randomBytes(12).toString('hex')}` }, expiresAt: { timestampValue: new Date(Date.now() + 30 * 60000).toISOString() } } }, true);
    console.log(JSON.stringify({ selectedAccountFound: true, registeredDevices: devices.documents.length, ownerDeliveryCheckPrepared: true }));
  }
}
main().catch(e => { console.error(e.message); process.exitCode = 1; });
