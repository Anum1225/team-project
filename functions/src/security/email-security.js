'use strict';
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { makeEmailSecurity } = require('./email-security-service');

const senderConfig = defineSecret('HARVESTHUB_EMAIL_SENDER');
const pepper = defineSecret('HARVESTHUB_EMAIL_CODE_SECRET');
async function sendMail({ to, code, purpose }) {
  const config = JSON.parse(senderConfig.value());
  const action = purpose === 'disable' ? 'disable two-step verification' : purpose === 'enroll' ? 'enable two-step verification' : 'sign in';
  const message = {
    from: config.from, to, subject: `${code} is your HarvestHub verification code`,
    text: `Your HarvestHub code is ${code}.\n\nUse it to ${action}. It expires in 30 minutes and can be used once.\n\nIf you did not request this code, do not share it. No change is made unless the code is verified.`,
    html: `<div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:28px;color:#163e29"><h1>HarvestHub</h1><h2>Verify it’s you</h2><p>Enter this code to ${action}:</p><p style="font-size:34px;letter-spacing:8px;font-weight:bold">${code}</p><p>Expires in 30 minutes. Use this code only in HarvestHub.</p><p>If you did not request it, do not share it. Your account settings stay unchanged until verification.</p></div>`,
  };
  if (config.provider === 'smtp') {
    const transport = require('nodemailer').createTransport({
      host: config.host, port: config.port || 587, secure: config.secure === true,
      requireTLS: config.secure !== true, auth: { user: config.user, pass: config.password },
      connectionTimeout: 10000, socketTimeout: 20000,
    });
    try {
      await transport.sendMail(message);
    } finally {
      transport.close();
    }
  } else { throw new Error('Configure a supported email provider.'); }
}

async function verifyPassword(uid, email, password, apiKey) {
  if (typeof password !== 'string' || !password || password.length > 4096 || typeof apiKey !== 'string' || apiKey.length > 200) throw new HttpsError('invalid-argument', 'Enter your current password.');
  const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST', signal: AbortSignal.timeout(15000), headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  if (!response.ok) throw new HttpsError('unauthenticated', 'The current password could not be verified.');
  const result = await response.json();
  const decoded = await getAuth().verifyIdToken(result.idToken);
  if (decoded.uid !== uid) throw new HttpsError('permission-denied', 'Account verification failed.');
}
const service = () => makeEmailSecurity({ db: getFirestore(), auth: getAuth(), sendMail, secret: () => pepper.value(), verifyPassword });
const options = { region: 'us-central1', maxInstances: 3, timeoutSeconds: 60, secrets: [senderConfig, pepper] };
// These endpoints require Firebase Auth, fresh password proof and strict per-user
// limits. They must remain usable before a second-step token is issued.
function endpoint(method) {
  return onCall(options, async request => {
    try { return await service()[method](request); }
    catch (e) {
      if (e instanceof HttpsError) throw e;
      // Never log request bodies, OTPs, passwords, or provider credentials.
      throw new HttpsError('internal', 'Account verification could not finish. Please retry.');
    }
  });
}
exports.startEmailVerification = endpoint('start');
exports.verifyEmailCode = endpoint('verify');
exports.changeVerifiedPassword = endpoint('changePassword');

