'use strict';
const crypto = require('node:crypto');
const { HttpsError } = require('firebase-functions/v2/https');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const d = require('./email-security-domain');
const fail = (code, message) => { throw new HttpsError(code, message); };

// Dependencies are injected so the complete service can run against emulators
// without sending mail or requiring real secrets in tests.
function makeEmailSecurity({ db, auth, sendMail, secret, verifyPassword, now = Date.now }) {
  async function identity(request) {
    if (!request.auth) fail('unauthenticated', 'Sign in again to continue.');
    const uid = request.auth.uid;
    const [user, snap] = await Promise.all([auth.getUser(uid), db.doc(`users/${uid}`).get()]);
    if (user.disabled || !user.email || !snap.exists || snap.data().active !== true) fail('permission-denied', 'This account is unavailable.');
    return { uid, user, profile: snap.data(), ref: snap.ref };
  }

  async function start(request) {
    const { uid, user, profile } = await identity(request);
    const purpose = request.data?.purpose;
    const challengeRef = db.doc(`emailSecurityChallenges/${uid}`);
    let passwordProofAt = now();
    if (!['login', 'enroll', 'disable'].includes(purpose)) fail('invalid-argument', 'Choose a valid verification action.');
    if (purpose === 'disable' && profile.email2faEnabled === false) fail('failed-precondition', 'Email verification is already disabled.');
    if (purpose === 'login') {
      if (now() - Number(request.auth.token.auth_time || 0) * 1000 > d.CODE_TTL_MS) fail('failed-precondition', 'Sign in again before requesting a code.');
    } else {
      if (purpose === 'enroll' && profile.email2faEnabled) fail('already-exists', 'Email verification is already enabled.');
      const prior = (await challengeRef.get()).data();
      const resending = prior && request.data?.resendChallengeId === prior.id &&
        prior.purpose === purpose && prior.email === user.email &&
        prior.authTime === request.auth.token.auth_time &&
        prior.securityVersion === (profile.securityVersion || 0) &&
        Number.isFinite(prior.passwordProofAt) && now() - prior.passwordProofAt < d.CODE_TTL_MS;
      if (resending) passwordProofAt = prior.passwordProofAt;
      else await verifyPassword(uid, user.email, request.data?.password, request.data?.apiKey);
    }
    const id = crypto.randomBytes(24).toString('hex');
    const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    const instant = now();
    const limitRef = db.doc(`emailSecurityLimits/${uid}`);
    await db.runTransaction(async tx => {
      const [old, limit] = await Promise.all([tx.get(challengeRef), tx.get(limitRef)]);
      if (old.exists && instant - old.data().createdAt.toMillis() < d.RESEND_MS) fail('resource-exhausted', 'Wait one minute before requesting another code.');
      const previous = limit.data();
      const inWindow = previous && instant - previous.startedAt.toMillis() < 3600000;
      if (inWindow && previous.count >= d.MAX_SENDS_PER_HOUR) fail('resource-exhausted', 'Too many codes requested. Try again in an hour.');
      tx.set(limitRef, { startedAt: inWindow ? previous.startedAt : Timestamp.fromMillis(instant), count: inWindow ? previous.count + 1 : 1 });
      tx.set(challengeRef, {
        id, purpose, email: user.email, authTime: request.auth.token.auth_time, passwordProofAt,
        hash: d.codeHash(secret(), uid, id, purpose, code), attempts: 0, state: 'sending',
        securityVersion: profile.securityVersion || 0,
        createdAt: Timestamp.fromMillis(instant), expiresAt: Timestamp.fromMillis(instant + d.CODE_TTL_MS),
      });
    });
    try {
      await sendMail({ to: user.email, code, purpose, id });
      await db.runTransaction(async tx => {
        const current = await tx.get(challengeRef);
        if (current.data()?.id === id) tx.update(challengeRef, { state: 'sent' });
      });
    } catch (_) {
      await db.runTransaction(async tx => {
        const current = await tx.get(challengeRef);
        if (current.data()?.id === id) tx.update(challengeRef, { state: 'delivery-failed' });
      });
      fail('unavailable', 'The verification email could not be sent. Please try again later.');
    }
    return { challengeId: id, maskedEmail: d.maskedEmail(user.email), expiresAt: instant + d.CODE_TTL_MS, resendAfter: instant + d.RESEND_MS };
  }

  async function verify(request) {
    const { uid, user, ref } = await identity(request);
    const { challengeId, code } = request.data || {};
    if (typeof challengeId !== 'string' || !/^[a-f0-9]{48}$/.test(challengeId) || typeof code !== 'string' || !/^\d{6}$/.test(code)) fail('invalid-argument', 'Enter the six-digit code from your email.');
    const challengeRef = db.doc(`emailSecurityChallenges/${uid}`);
    const result = await db.runTransaction(async tx => {
      const [snap, profileSnap] = await Promise.all([tx.get(challengeRef), tx.get(ref)]);
      const challenge = snap.data(), profile = profileSnap.data();
      if (!profile || profile.active !== true || !challenge || challenge.id !== challengeId || challenge.state !== 'sent' || challenge.email !== user.email ||
          challenge.authTime !== request.auth.token.auth_time || challenge.securityVersion !== (profile.securityVersion || 0) ||
          challenge.expiresAt.toMillis() <= now() || challenge.attempts >= d.MAX_ATTEMPTS) return { error: 'This code expired or is no longer valid. Request a new code.' };
      if (!d.matches(challenge.hash, d.codeHash(secret(), uid, challengeId, challenge.purpose, code))) {
        tx.update(challengeRef, { attempts: challenge.attempts + 1 });
        return { error: challenge.attempts + 1 >= d.MAX_ATTEMPTS ? 'Too many incorrect attempts. Request a new code.' : 'Incorrect code. Check your email and try again.' };
      }
      const version = (profile.securityVersion || 0) + (challenge.purpose === 'login' ? 0 : 1);
      const enabled = challenge.purpose === 'login' ? profile.email2faEnabled !== false : challenge.purpose === 'enroll';
      tx.update(challengeRef, { state: 'consumed', hash: FieldValue.delete(), consumedAt: Timestamp.fromMillis(now()) });
      tx.update(ref, {
        email2faEnabled: enabled, securityVersion: version, updatedAt: FieldValue.serverTimestamp(),
      });
      return { version, enabled };
    });
    if (result.error) fail('permission-denied', result.error);
    // Verification only changes the verified-email bit after actual mailbox proof.
    if (!user.emailVerified) await auth.updateUser(uid, { emailVerified: true });
    const token = await auth.createCustomToken(uid, { hh_email_2fa: true, hh_security_version: result.version, hh_verified_email: user.email });
    return { token, enabled: result.enabled };
  }

  async function changePassword(request) {
    const { uid, user, profile, ref } = await identity(request);
    if (!d.verifiedSession(request.auth.token, profile)) fail('permission-denied', 'Complete email verification before changing your password.');
    if (!d.validatePassword(request.data?.newPassword)) fail('invalid-argument', 'Use 8–128 characters with uppercase, lowercase and a number.');
    if (request.data?.password === request.data?.newPassword) fail('invalid-argument', 'Choose a different password.');
    await verifyPassword(uid, user.email, request.data?.password, request.data?.apiKey);
    await auth.updateUser(uid, { password: request.data.newPassword });
    await auth.revokeRefreshTokens(uid);
    await ref.update({ securityVersion: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() });
    return { changed: true };
  }
  return { start, verify, changePassword };
}
module.exports = { makeEmailSecurity };
