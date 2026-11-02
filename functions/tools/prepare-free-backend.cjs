'use strict';
// Local operator utility. Uses the existing Firebase CLI login and only the
// named HarvestHub project. Output contains status, never credentials.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const project = 'harvesthub-80047';
async function main() {
  const root = path.resolve(__dirname, '../..');
  const secretPath = path.join(root, '.local-backups/backend.secrets.json');
  const config = JSON.parse(fs.readFileSync(secretPath, 'utf8'));
  config.OTP_SECRET ||= crypto.randomBytes(32).toString('hex');
  config.FIREBASE_WEB_API_KEY ||= fs.readFileSync(path.join(root, 'lib/firebase_options.dart'), 'utf8').match(/apiKey: '([^']+)'/)[1];
  const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw Error('Sign into the Firebase CLI first.');
  const token = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const call = async (url, method = 'GET', body) => {
    const r = await fetch(url, { method, headers: { Authorization: `Bearer ${token.access_token}`, 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined });
    const result = await r.json();
    if (!r.ok) throw Error(`Google API ${r.status}: ${result.error?.status || 'failed'}`);
    return result;
  };
  const accounts = await call(`https://iam.googleapis.com/v1/projects/${project}/serviceAccounts`);
  const signer = accounts.accounts?.find(a => a.email.startsWith('firebase-adminsdk-'));
  if (!signer) throw Error('No Firebase service account is available for custom token signing.');
  config.SIGNER_SERVICE_ACCOUNT = signer.email;
  fs.writeFileSync(secretPath, JSON.stringify(config, null, 2));
  const billing = await call(`https://cloudbilling.googleapis.com/v1/projects/${project}/billingInfo`);
  const keyResponse = await fetch('https://generativelanguage.googleapis.com/v1beta/models', { headers: { 'x-goog-api-key': config.GEMINI_API_KEY } });
  const models = await keyResponse.json();
  const available = models.models?.some(m => m.name === 'models/gemini-3.5-flash-lite');
  if (process.argv.includes('--list-models')) console.log(JSON.stringify({ flashModels: models.models?.filter(m => m.name.includes('flash') && m.supportedGenerationMethods?.includes('generateContent')).map(m => m.name) }));
  console.log(JSON.stringify({ billingEnabled: billing.billingEnabled, signerFound: true, geminiKeyStatus: keyResponse.status, modelAvailable: !!available }));
  if (process.argv.includes('--grant-signing')) {
    // Only JWT signing, scoped to the existing Firebase signer; no keys,
    // project-wide grant, or OAuth access-token impersonation permission.
    const email = account.user?.email;
    if (email !== 'noobgamerabduljabber@gmail.com') throw Error('Unexpected deployment account.');
    const roleId = 'harvestHubJwtSigner';
    const roleName = `projects/${project}/roles/${roleId}`;
    const roles = await call(`https://iam.googleapis.com/v1/projects/${project}/roles`);
    const existing = roles.roles?.find(r => r.name === roleName);
    if (!existing) await call(`https://iam.googleapis.com/v1/projects/${project}/roles`, 'POST', { roleId, role: { title: 'HarvestHub JWT signer', description: 'Sign Firebase custom authentication tokens for HarvestHub email verification.', includedPermissions: ['iam.serviceAccounts.signJwt'], stage: 'GA' } });
    const role = await call(`https://iam.googleapis.com/v1/${roleName}`);
    if (role.includedPermissions?.length !== 1 || role.includedPermissions[0] !== 'iam.serviceAccounts.signJwt') throw Error('Unexpected signing role permissions.');
    const resource = `https://iam.googleapis.com/v1/projects/${project}/serviceAccounts/${encodeURIComponent(signer.email)}`;
    const policy = await call(`${resource}:getIamPolicy`, 'POST', { options: { requestedPolicyVersion: 3 } });
    const member = `user:${email}`;
    policy.bindings ||= [];
    let binding = policy.bindings.find(b => b.role === roleName && !b.condition);
    if (!binding) { binding = { role: roleName, members: [] }; policy.bindings.push(binding); }
    if (!binding.members.includes(member)) {
      binding.members.push(member);
      await call(`${resource}:setIamPolicy`, 'POST', { policy });
    }
    console.log(JSON.stringify({ scopedJwtSigningGranted: true }));
  }
  if (process.argv.includes('--check-signing')) {
    const api = await call(`https://serviceusage.googleapis.com/v1/projects/${project}/services/iamcredentials.googleapis.com`);
    const permission = await call(`https://iam.googleapis.com/v1/projects/${project}/serviceAccounts/${encodeURIComponent(config.SIGNER_SERVICE_ACCOUNT)}:testIamPermissions`, 'POST', { permissions: ['iam.serviceAccounts.signJwt'] });
    console.log(JSON.stringify({ signingApiState: api.state, canSignJwt: permission.permissions?.includes('iam.serviceAccounts.signJwt') === true }));
  }
  if (process.argv.includes('--test-gemini')) {
    const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent', {
      method: 'POST', headers: { 'x-goog-api-key': config.GEMINI_API_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents: [{ role: 'user', parts: [{ text: 'Reply with HARVEST_OK only.' }] }], generationConfig: { maxOutputTokens: 32 } }),
    });
    const answer = await response.json();
    console.log(JSON.stringify({ generationStatus: response.status, expectedReply: answer.candidates?.some(c => c.content?.parts?.some(p => p.text?.includes('HARVEST_OK'))) === true }));
  }
  if (process.argv.includes('--test-examples')) {
    const questions = ['Which fruits are rich in Vitamin C?', 'How should tomatoes be stored?', 'Which vegetables are seasonal?', 'What are the health benefits of spinach?', 'Suggest vegetables for a healthy salad.'];
    for (const question of questions) {
      const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent', {
        method: 'POST', headers: { 'x-goog-api-key': config.GEMINI_API_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ systemInstruction: { parts: [{ text: 'You are Ola, a farm produce assistant. Give concise general food information, not personalized medical treatment. Do not invent local seasons or marketplace stock. Ask for location when it affects the answer.' }] }, contents: [{ role: 'user', parts: [{ text: question }] }], generationConfig: { maxOutputTokens: 350 } }),
      });
      const answer = await response.json();
      console.log(JSON.stringify({ question, status: response.status, answer: answer.candidates?.[0]?.content?.parts?.filter(p => !p.thought).map(p => p.text || '').join('') || '' }));
    }
  }
  if (process.argv.includes('--enable-signing')) {
    const result = await call(`https://serviceusage.googleapis.com/v1/projects/${project}/services/iamcredentials.googleapis.com:enable`, 'POST', {});
    console.log(JSON.stringify({ signingApiEnableRequested: true, done: result.done === true }));
  }
}
main().catch(() => { console.error('Backend preparation failed. Check Google project access and local configuration. No credentials were logged.'); process.exitCode = 1; });
