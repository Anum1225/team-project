'use strict';
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { makeEmailSecurity } = require('../src/security/email-security-service');
const domain = require('../src/security/email-security-domain');
let app, db;
before(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Run these security tests with both Auth and Firestore emulators.');
  }
  app = initializeApp({ projectId: 'demo-harvesthub' }, 'email-security-tests');
  db = getFirestore(app);
});
after(async () => { if (app) await deleteApp(app); });

test('email codes: enrollment, single use, resend, lockout, session binding and expiry', async () => {
  const uid = 'email-security-test';
  let instant = 1700000000000;
  const sent = [];
  await db.doc(`users/${uid}`).set({ active: true, role: 'customer', securityVersion: 0, email: 'email-security@example.test' });
  await db.doc(`emailSecurityChallenges/${uid}`).delete();
  await db.doc(`emailSecurityLimits/${uid}`).delete();
  const user = { uid, email: 'email-security@example.test', emailVerified: false };
  const service = makeEmailSecurity({ db, now: () => instant, secret: () => 'emulator-only-pepper',
    auth: { getUser: async () => user, updateUser: async () => {},
      createCustomToken: async (_, claims) => JSON.stringify(claims) },
    sendMail: async message => sent.push(message),
    verifyPassword: async (_, __, password) => { assert.equal(password, 'TestOnly123!'); },
  });
  const request = data => ({ auth: { uid, token: { auth_time: 1700000000, firebase: { sign_in_provider: 'password' } } }, data });
  const first = await service.start(request({ purpose: 'enroll', password: 'TestOnly123!' }));
  const firstCode = sent.at(-1).code;
  assert.equal(first.maskedEmail, 'e***@example.test');
  const persisted = (await db.doc(`emailSecurityChallenges/${uid}`).get()).data();
  assert.equal(persisted.code, undefined);
  assert.notEqual(persisted.hash, firstCode);
  await assert.rejects(service.start(request({ purpose: 'enroll', password: 'TestOnly123!' })), /one minute/);
  instant += 61000;
  const resend = await service.start(request({ purpose: 'enroll', resendChallengeId: first.challengeId }));
  await assert.rejects(service.verify(request({ challengeId: first.challengeId, code: firstCode })), /no longer valid/);
  const code = sent.at(-1).code;
  const wrong = code === '000000' ? '111111' : '000000';
  await assert.rejects(service.verify(request({ challengeId: resend.challengeId, code: wrong })), /Incorrect code/);
  assert.equal((await db.doc(`emailSecurityChallenges/${uid}`).get()).data().attempts, 1);
  const enrolled = await service.verify(request({ challengeId: resend.challengeId, code }));
  assert.equal(JSON.parse(enrolled.token).hh_security_version, 1);
  assert.equal((await db.doc(`users/${uid}`).get()).data().email2faEnabled, true);
  await assert.rejects(service.verify(request({ challengeId: resend.challengeId, code })), /no longer valid/);
  instant += 61000;
  const login = await service.start(request({ purpose: 'login' }));
  const otherSession = request({ challengeId: login.challengeId, code: sent.at(-1).code });
  otherSession.auth.token.auth_time++;
  await assert.rejects(service.verify(otherSession), /no longer valid/);
  const correct = sent.at(-1).code;
  for (let i = 0; i < 5; i++) await assert.rejects(service.verify(request({
    challengeId: login.challengeId, code: correct === '000000' ? '111111' : '000000',
  })));
  await assert.rejects(service.verify(request({ challengeId: login.challengeId, code: correct })), /no longer valid/);
  instant += 61000;
  const expired = await service.start(request({ purpose: 'login' }));
  instant += domain.CODE_TTL_MS + 1;
  await assert.rejects(service.verify(request({ challengeId: expired.challengeId, code: sent.at(-1).code })), /no longer valid/);
  const fresh = data => {
    const r = request(data);
    r.auth.token.auth_time = Math.floor(instant / 1000);
    return r;
  };
  const validLogin = await service.start(fresh({ purpose: 'login' }));
  const signedIn = await service.verify(fresh({ challengeId: validLogin.challengeId, code: sent.at(-1).code }));
  assert.equal(JSON.parse(signedIn.token).hh_email_2fa, true);
  instant += 61000;
  await assert.rejects(service.start(fresh({ purpose: 'login' })), /Too many codes/);
  instant += 3600000;
  const verified = data => {
    const r = fresh(data);
    r.auth.token.firebase.sign_in_provider = 'custom';
    Object.assign(r.auth.token, JSON.parse(signedIn.token));
    return r;
  };
  const disable = await service.start(verified({ purpose: 'disable', password: 'TestOnly123!' }));
  assert.equal((await db.doc(`users/${uid}`).get()).data().email2faEnabled, true);
  const disabled = await service.verify(verified({challengeId:disable.challengeId,code:sent.at(-1).code}));
  assert.equal(disabled.enabled, false);
  const offProfile = (await db.doc(`users/${uid}`).get()).data();
  assert.equal(offProfile.email2faEnabled, false);
  assert.equal(offProfile.securityVersion, 2);
  assert.equal(domain.verifiedSession(fresh({}).auth.token, offProfile), true);
  instant += 61000;
  const enable = await service.start(fresh({purpose:'enroll',password:'TestOnly123!'}));
  const enabled = await service.verify(fresh({challengeId:enable.challengeId,code:sent.at(-1).code}));
  assert.equal(enabled.enabled, true);
  assert.equal((await db.doc(`users/${uid}`).get()).data().securityVersion, 3);
  assert.equal(domain.verifiedSession({ hh_email_2fa: true, hh_security_version: 1,
    firebase: { sign_in_provider: 'password' } }, { securityVersion: 1 }), false);
  assert.equal(domain.matches('x'.repeat(64), '0'.repeat(64)), false);
});

test('mail failures never report a delivered code', async () => {
  const uid = 'mail-failure-test';
  await db.doc(`users/${uid}`).set({ active: true, email2faEnabled: true });
  await db.doc(`emailSecurityChallenges/${uid}`).delete();
  await db.doc(`emailSecurityLimits/${uid}`).delete();
  const service = makeEmailSecurity({ db, now: () => 1700000000000, secret: () => 'test',
    auth: { getUser: async () => ({ email: 'failure@example.test' }) },
    verifyPassword: async () => {}, sendMail: async () => { throw new Error('offline'); } });
  await assert.rejects(service.start({ auth: { uid, token: { auth_time: 1700000000 } },
    data: { purpose: 'login' } }), /could not be sent/);
  assert.equal((await db.doc(`emailSecurityChallenges/${uid}`).get()).data().state, 'delivery-failed');
});

test('Firebase reset and password change invalidate old credentials', async () => {
  const auth = getAuth(app);
  const uid = 'password-lifecycle-test', email = 'password-lifecycle@example.test';
  await auth.deleteUser(uid).catch(() => {});
  await auth.createUser({ uid, email, password: 'OriginalTest123!' });
  const endpoint = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:`;
  const call = async (method, body) => {
    const r = await fetch(`${endpoint}${method}?key=emulator-only`, { method: 'POST',
      headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    return { ok: r.ok, body: await r.json() };
  };
  const verificationLink = await auth.generateEmailVerificationLink(email);
  const verificationCode = new URL(verificationLink).searchParams.get('oobCode');
  assert.equal((await call('update', { oobCode: verificationCode })).ok, true);
  assert.equal((await auth.getUser(uid)).emailVerified, true);
  assert.equal((await call('update', { oobCode: verificationCode })).ok, false);
  const link = await auth.generatePasswordResetLink(email);
  const oobCode = new URL(link).searchParams.get('oobCode');
  assert.equal((await call('resetPassword', { oobCode: 'invalid', newPassword: 'ChangedTest123!' })).ok, false);
  assert.equal((await call('resetPassword', { oobCode, newPassword: 'ChangedTest123!' })).ok, true);
  assert.equal((await call('resetPassword', { oobCode, newPassword: 'RepeatedTest123!' })).ok, false);
  assert.equal((await call('signInWithPassword', { email, password: 'OriginalTest123!', returnSecureToken: true })).ok, false);
  const signedIn = await call('signInWithPassword', { email, password: 'ChangedTest123!', returnSecureToken: true });
  assert.equal(signedIn.ok, true);
  assert.equal((await call('update', { idToken: signedIn.body.idToken, password: 'FinalTest123!', returnSecureToken: true })).ok, true);
  assert.equal((await call('signInWithPassword', { email, password: 'ChangedTest123!', returnSecureToken: true })).ok, false);
  assert.equal((await call('signInWithPassword', { email, password: 'FinalTest123!', returnSecureToken: true })).ok, true);
  await db.doc(`users/${uid}`).set({ active: true, email2faEnabled: true, securityVersion: 1, email });
  const service = makeEmailSecurity({ db, auth, secret: () => 'emulator-only',
    sendMail: async () => {}, verifyPassword: async (expectedUid, address, password) => {
      const result = await call('signInWithPassword', { email: address, password, returnSecureToken: true });
      if (!result.ok || result.body.localId !== expectedUid) throw new Error('Password proof failed');
    } });
  const change = { auth: { uid, token: { firebase: { sign_in_provider: 'password' } } },
    data: { password: 'FinalTest123!', newPassword: 'ProtectedTest123!' } };
  await assert.rejects(service.changePassword(change), /Complete email/);
  change.auth.token = { firebase: { sign_in_provider: 'custom' }, hh_email_2fa: true, hh_security_version: 1, hh_verified_email: email };
  await assert.rejects(service.changePassword({ ...change, data: { ...change.data, password: 'WrongTest123!' } }), /Password proof failed/);
  await service.changePassword(change);
  assert.equal((await db.doc(`users/${uid}`).get()).data().securityVersion, 2);
  assert.equal((await call('signInWithPassword', { email, password: 'FinalTest123!', returnSecureToken: true })).ok, false);
  assert.equal((await call('signInWithPassword', { email, password: 'ProtectedTest123!', returnSecureToken: true })).ok, true);
  await assert.rejects(service.changePassword(change), /Complete email/);
  await auth.deleteUser(uid);
});
