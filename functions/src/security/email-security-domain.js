'use strict';
const crypto = require('node:crypto');

const CODE_TTL_MS = 30 * 60 * 1000;
const RESEND_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;
const MAX_SENDS_PER_HOUR = 5;

function codeHash(secret, uid, id, purpose, code) {
  return crypto.createHmac('sha256', secret).update(JSON.stringify([uid, id, purpose, code])).digest('hex');
}
function matches(expected, actual) {
  if (typeof expected !== 'string' || typeof actual !== 'string' || !/^[a-f0-9]{64}$/.test(expected) || !/^[a-f0-9]{64}$/.test(actual)) return false;
  return crypto.timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(actual, 'hex'));
}
function validatePassword(value) {
  return typeof value === 'string' && value.length >= 8 && value.length <= 128 && /[a-z]/.test(value) && /[A-Z]/.test(value) && /[0-9]/.test(value);
}
function verifiedSession(token, profile) {
  if (profile.email2faEnabled === false) return true;
  return token?.firebase?.sign_in_provider === 'custom' && token.hh_email_2fa === true &&
    token.hh_security_version === (profile.securityVersion || 0) && token.hh_verified_email === profile.email;
}
function maskedEmail(email) {
  const [name, domain] = email.split('@');
  return `${name.slice(0, 1)}***@${domain}`;
}
module.exports = { CODE_TTL_MS, RESEND_MS, MAX_ATTEMPTS, MAX_SENDS_PER_HOUR, codeHash, matches, validatePassword, verifiedSession, maskedEmail };
