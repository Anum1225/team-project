'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const crypto = require('node:crypto');

function service() {
  let instant = Date.now();
  class Clock extends Date {
    constructor(...args) { super(...(args.length ? args : [instant])); }
    static now() { return instant; }
  }
  const records = new Map(), mail = [];
  const ctx = vm.createContext({ Date: Clock, JSON, Set, Math, Number, Array, String, Error,
    Utilities: { getUuid: crypto.randomUUID,
      formatDate: date => date.toISOString().slice(0, 10),
      computeHmacSha256Signature: (text, secret) => [...crypto.createHmac('sha256', secret).update(text).digest()],
      base64DecodeWebSafe: text => Buffer.from(text, 'base64url'), newBlob: bytes => ({ getDataAsString: () => bytes.toString() }),
    },
    PropertiesService: { getScriptProperties: () => ({ getProperty: () => 'test-only-secret' }) },
    LockService: { getScriptLock: () => ({ tryLock: () => true, releaseLock() {} }) },
    MailApp: { getRemainingDailyQuota: () => 100, sendEmail: message => mail.push(message) },
  });
  vm.runInContext(fs.readFileSync(require.resolve('../apps-script/Code.js'), 'utf8'), ctx);
  ctx.read_ = path => records.has(path) ? { data: structuredClone(records.get(path)), updateTime: 'version' } : null;
  ctx.write_ = (path, value, merge) => records.set(path, merge ? { ...records.get(path), ...value } : structuredClone(value));
  ctx.password_ = (_, password) => { assert.equal(password, 'TestOnly123'); return 'password-token'; };
  ctx.customToken_ = (_, claims) => JSON.stringify(claims);
  ctx.auth_ = () => ({});
  ctx.request_ = (_, __, body) => {
    for (const write of body.writes) {
      const path = write.update.name.split('/documents/')[1];
      ctx.write_(path, ctx.unpack_(write.update), !!write.updateMask);
    }
  };
  const id = { uid: 'test-user', profile: { active: true, email: 'farmer@example.test', securityVersion: 0 }, user: { email: 'farmer@example.test', emailVerified: true }, claims: { auth_time: Math.floor(Date.now() / 1000), firebase: { sign_in_provider: 'password' } } };
  records.set('users/test-user', id.profile);
  return { ctx, records, mail, id, advance: ms => { instant += ms; } };
}
for (const role of ['admin', 'customer', 'farmer']) {
  for (const flag of [undefined, false, true]) {
    test(`email login honors ${role} setting ${flag}`, () => {
      const {ctx, records, mail, id} = service();
      Object.assign(id.profile, {role, email2faEnabled: flag});
      records.set('users/test-user', id.profile);
      if (flag === false) assert.doesNotThrow(() => ctx.requireProof_(id));
      else assert.throws(() => ctx.requireProof_(id), /Complete email/);
      const challenge = ctx.startCode_(id, {purpose:'login'});
      assert.equal(challenge.expiresAt - challenge.serverTime, 30 * 60000);
      const code = mail[0].body.match(/code is (\d{6})/)[1];
      const result = ctx.verifyCode_(id, {challengeId:challenge.challengeId,code});
      assert.equal(result.enabled, flag !== false);
      assert.equal(records.get('users/test-user').email2faEnabled, flag !== false);
      id.claims = {...JSON.parse(result.token), firebase:{sign_in_provider:'custom'}};
      assert.doesNotThrow(() => ctx.requireProof_(id));
    });
  }
}

test('incomplete disable challenges cannot turn verification off', () => {
  const {ctx, records, id} = service();
  const challengeId = 'a'.repeat(48);
  records.set('emailSecurityChallenges/test-user', {id:challengeId, purpose:'disable', state:'sent'});
  assert.throws(() => ctx.verifyCode_(id, {challengeId,code:'123456'}), /no longer valid/);
  assert.equal(records.get('emailSecurityChallenges/test-user').state, 'sent');
});

for (const role of ['admin', 'farmer', 'customer']) {
  test(`${role} can disable and re-enable only after password and mailbox proof`, () => {
    const {ctx, records, mail, id, advance} = service();
    Object.assign(id.profile, {role, email2faEnabled:true});
    assert.throws(() => ctx.startCode_(id, {purpose:'disable',password:'incorrect'}));
    const disable = ctx.startCode_(id, {purpose:'disable',password:'TestOnly123'});
    assert.equal(records.get('users/test-user').email2faEnabled, true);
    const code = mail.at(-1).body.match(/code is (\d{6})/)[1];
    assert.throws(() => ctx.verifyCode_(id, {challengeId:disable.challengeId,code:code==='000000'?'111111':'000000'}), /Incorrect/);
    assert.equal(records.get('users/test-user').email2faEnabled, true);
    const off = ctx.verifyCode_(id, {challengeId:disable.challengeId,code});
    assert.equal(off.enabled, false);
    id.profile = records.get('users/test-user');
    assert.equal(id.profile.securityVersion, 1);
    assert.doesNotThrow(() => ctx.requireProof_(id));
    assert.throws(() => ctx.verifyCode_(id, {challengeId:disable.challengeId,code}), /no longer valid/);
    advance(61000);
    const enable = ctx.startCode_(id, {purpose:'enroll',password:'TestOnly123'});
    assert.equal(records.get('users/test-user').email2faEnabled, false);
    const on = ctx.verifyCode_(id, {challengeId:enable.challengeId,code:mail.at(-1).body.match(/code is (\d{6})/)[1]});
    assert.equal(on.enabled, true);
    id.profile = records.get('users/test-user');
    assert.equal(id.profile.securityVersion, 2);
    assert.throws(() => ctx.requireProof_(id), /Complete email/);
    id.claims = {...JSON.parse(off.token),firebase:{sign_in_provider:'custom'}};
    assert.throws(() => ctx.requireProof_(id), /Complete email/);
    id.claims = {...JSON.parse(on.token),firebase:{sign_in_provider:'custom'}};
    assert.doesNotThrow(() => ctx.requireProof_(id));
  });
}

test('Apps Script code enrollment is single use, expiring, session bound and email bound', () => {
  const { ctx, records, mail, id } = service();
  const challenge = ctx.startCode_(id, { purpose: 'enroll', password: 'TestOnly123' });
  const code = mail[0].body.match(/code is (\d{6})/)[1];
  assert.notEqual(records.get('emailSecurityChallenges/test-user').hash, code);
  assert.throws(() => ctx.startCode_(id, { purpose: 'enroll', resendChallengeId: challenge.challengeId }), /one minute/);
  assert.throws(() => ctx.verifyCode_({ ...id, claims: { ...id.claims, auth_time: id.claims.auth_time + 1 } }, { challengeId: challenge.challengeId, code }), /no longer valid/);
  records.get('users/test-user').email = 'changed@example.test';
  assert.throws(() => ctx.verifyCode_(id, { challengeId: challenge.challengeId, code }), /no longer valid/);
  records.get('users/test-user').email = id.profile.email = 'farmer@example.test';
  const result = ctx.verifyCode_(id, { challengeId: challenge.challengeId, code });
  assert.equal(JSON.parse(result.token).hh_verified_email, 'farmer@example.test');
  assert.equal(records.get('users/test-user').email2faEnabled, true);
  assert.throws(() => ctx.verifyCode_(id, { challengeId: challenge.challengeId, code }), /no longer valid/);
});
test('Apps Script locks out five wrong attempts and rejects expired codes', () => {
  const { ctx, records, mail, id } = service();
  const c = ctx.startCode_(id, { purpose: 'enroll', password: 'TestOnly123' });
  const code = mail[0].body.match(/code is (\d{6})/)[1];
  const wrong = code === '000000' ? '999999' : '000000';
  for (let i = 0; i < 5; i++) assert.throws(() => ctx.verifyCode_(id, { challengeId: c.challengeId, code: wrong }));
  assert.throws(() => ctx.verifyCode_(id, { challengeId: c.challengeId, code }), /no longer valid/);
  records.get('emailSecurityChallenges/test-user').attempts = 0;
  records.get('emailSecurityChallenges/test-user').expiresAt = ctx.Date.now() - 1;
  assert.throws(() => ctx.verifyCode_(id, { challengeId: c.challengeId, code }), /no longer valid/);
});
test('mail failure never makes an unsent code usable', () => {
  const { ctx, records, id } = service();
  ctx.MailApp.sendEmail = () => { throw Error('delivery failed'); };
  assert.throws(() => ctx.startCode_(id, { purpose: 'enroll', password: 'TestOnly123' }), /could not be delivered/);
  assert.equal(records.get('emailSecurityChallenges/test-user').state, 'delivery-failed');
});

test('login code survives screen reopening and remains valid for thirty minutes', () => {
  const {ctx, records, mail, id, advance} = service();
  id.profile.email2faEnabled = true;
  records.set('users/test-user', id.profile);
  const challenge = ctx.startCode_(id, {purpose:'login'});
  const code = mail[0].body.match(/code is (\d{6})/)[1];
  assert.equal(challenge.expiresAt - challenge.serverTime, 30 * 60000);
  assert.match(mail[0].body, /30 minutes/);
  advance(15 * 60000);
  const resumed = ctx.startCode_(id, {purpose:'login'});
  assert.equal(resumed.challengeId, challenge.challengeId);
  assert.equal(resumed.expiresAt, challenge.expiresAt);
  assert.equal(mail.length, 1);
  advance(15 * 60000 - 1);
  assert.ok(ctx.verifyCode_(id, {challengeId:challenge.challengeId, code}).token);
});

test('code expires at thirty minutes and a stale login cannot request a new one', () => {
  const {ctx, records, mail, id, advance} = service();
  id.profile.email2faEnabled = true;
  records.set('users/test-user', id.profile);
  const challenge = ctx.startCode_(id, {purpose:'login'});
  const code = mail[0].body.match(/code is (\d{6})/)[1];
  advance(30 * 60000);
  assert.throws(() => ctx.verifyCode_(id, {challengeId:challenge.challengeId, code}), /no longer valid/);
  advance(1000);
  assert.throws(() => ctx.startCode_(id, {purpose:'login'}), /Sign in again/);
});

test('only explicit resend replaces a login code, with its own full lifetime', () => {
  const {ctx, records, mail, id, advance} = service();
  id.profile.email2faEnabled = true;
  records.set('users/test-user', id.profile);
  const first = ctx.startCode_(id, {purpose:'login'});
  const firstCode = mail[0].body.match(/code is (\d{6})/)[1];
  advance(20 * 60000);
  const second = ctx.startCode_(id, {purpose:'login',resendChallengeId:first.challengeId});
  assert.notEqual(first.challengeId, second.challengeId);
  assert.equal(second.expiresAt - second.serverTime, 30 * 60000);
  assert.throws(() => ctx.verifyCode_(id, {challengeId:first.challengeId,code:firstCode}), /no longer valid/);
  advance(15 * 60000);
  // The resumed challenge remains valid even though password login was 35m ago.
  assert.equal(ctx.startCode_(id, {purpose:'login'}).challengeId, second.challengeId);
  assert.equal(mail.length, 2);
  const secondCode = mail[1].body.match(/code is (\d{6})/)[1];
  assert.ok(ctx.verifyCode_(id, {challengeId:second.challengeId,code:secondCode}).token);
});

test('enrollment resend keeps its original password-proof deadline', () => {
  const {ctx, records, id, advance} = service();
  const first = ctx.startCode_(id, {purpose:'enroll',password:'TestOnly123'});
  const proofAt = records.get('emailSecurityChallenges/test-user').passwordProofAt;
  advance(20 * 60000);
  const second = ctx.startCode_(id, {purpose:'enroll',resendChallengeId:first.challengeId});
  assert.equal(records.get('emailSecurityChallenges/test-user').passwordProofAt, proofAt);
  advance(11 * 60000);
  assert.throws(() => ctx.startCode_(id, {purpose:'enroll',resendChallengeId:second.challengeId}));
});

test('assistant context scopes orders to the caller and strips private fields', () => {
  const { ctx, records, id } = service();
  id.profile.role = 'customer';
  const queries = [];
  ctx.query_ = (collection, filters, limit, group, parent, orderBy) => {
    queries.push({ collection, filters, limit, orderBy });
    const fixtures = {
      products: [{ path: 'products/tomato', data: { farmId: 'farm', name: 'Tomato', stock: 4, price: 12550, description: 'Fresh', secret: 'PRIVATE' } }, { path: 'products/hidden', data: { farmId: 'inactive', name: 'Hidden' } }],
      farms: [{ path: 'farms/farm', data: { name: 'Farm', market: 'Local market', owner: 'PRIVATE', location: 'Town', pickupSlots: ['Morning'] } }],
      farmersMarkets: [{ data: { name: 'Closed market', active: false } }],
      categories: [{ data: { name: 'Vegetables' } }],
      orders: [{ path: 'orders/order', data: { status: 'ready', farmName: 'Farm', address: 'PRIVATE', customerName: 'PRIVATE', total: 12550, items: [{ name: 'Tomato', quantity: 1, unit: 'kg' }] } }],
    };
    return fixtures[collection] || [];
  };
  records.set('appConfig/public', { about: 'Local produce', contactEmail: 'support@example.test', internal: 'PRIVATE' });
  const result = ctx.assistantContext_(id, { basket: [{ productId: 'tomato', quantity: 2 }, { productId: 'hidden', quantity: 1 }, { productId: 'tomato', quantity: -1 }] });
  assert.equal(result.products.length, 1);
  assert.equal(result.products[0].priceMinorUnits, 12550);
  assert.equal(result.basket.length, 1);
  assert.equal(result.markets[0].name, 'Local market');
  assert.equal(result.ownRecentOrders[0].status, 'ready');
  assert.equal(JSON.stringify(result).includes('PRIVATE'), false);
  const orderQuery = queries.find(q => q.collection === 'orders');
  assert.equal(orderQuery.filters[0].fieldFilter.field.fieldPath, 'customerId');
  assert.equal(orderQuery.filters[0].fieldFilter.value.stringValue, id.uid);
  assert.equal(orderQuery.orderBy[0].direction, 'DESCENDING');
  id.profile.role = 'farmer';
  queries.length = 0;
  ctx.assistantContext_(id, {});
  assert.equal(queries.find(q => q.collection === 'orders').filters[0].fieldFilter.field.fieldPath, 'farmerId');
});
test('second-step proof cannot be reused for a different email or security version', () => {
  const { ctx, id } = service();
  id.profile.email2faEnabled = true;
  assert.throws(() => ctx.requireProof_(id), /Complete email/);
  id.claims = { firebase: { sign_in_provider: 'custom' }, hh_email_2fa: true, hh_security_version: 0, hh_verified_email: id.profile.email };
  assert.doesNotThrow(() => ctx.requireProof_(id));
  id.profile.email = 'different@example.test';
  assert.throws(() => ctx.requireProof_(id), /Complete email/);
});

test('notification processing deduplicates updates and fans out genuine restocks', () => {
  const { ctx, records } = service();
  const sent = [];
  ctx.Utilities.DigestAlgorithm = { SHA_256: 'sha256' };
  ctx.Utilities.computeDigest = (_, text) => [...crypto.createHash('sha256').update(text).digest()];
  ctx.notice_ = (...args) => sent.push(args);
  ctx.query_ = (_, filters) => filters[0].fieldFilter.field.fieldPath === 'saved'
    ? [{ path: 'users/customer/private/preferences' }]
    : [{ path: 'users/customer/private/preferences' }, { path: 'users/follower/private/preferences' }];
  const order = { path: 'orders/order', updateTime: 'one', data: { farmerId: 'farmer', customerId: 'customer', farmName: 'Farm', status: 'pending' } };
  ctx.processUpdate_(order, 'orders');
  ctx.processUpdate_(order, 'orders');
  assert.equal(sent.length, 1);
  ctx.processUpdate_({ ...order, updateTime: 'two', data: { ...order.data, status: 'ready' } }, 'orders');
  assert.equal(sent.at(-1)[0], 'customer');
  assert.match(sent.at(-1)[3], /ready for pickup/);
  const product = { path: 'products/product', updateTime: 'one', data: { stock: 0, farmId: 'farm', name: 'Tomato' } };
  ctx.processUpdate_(product, 'products');
  const before = sent.length;
  ctx.processUpdate_({ ...product, updateTime: 'two', data: { ...product.data, stock: 8 } }, 'products');
  assert.equal(sent.length - before, 2);
  assert.deepEqual(sent.slice(-2).map(n => n[0]), ['customer', 'follower']);
  records.set('orders/order', order.data);
  ctx.processUpdate_({ path: 'users/customer/pickups/order', updateTime: 'one', data: { slot: 'Tomorrow' } }, 'pickups');
  ctx.processUpdate_({ path: 'users/customer/pickups/order', updateTime: 'two', data: { slot: null } }, 'pickups');
  assert.match(sent.at(-1)[3], /cancelled/);
});

test('approved orders notify the farmer and customer once', () => {
  const { ctx } = service();
  const sent = [];
  ctx.Utilities.DigestAlgorithm = { SHA_256: 'sha256' };
  ctx.Utilities.computeDigest = (_, value) => [...crypto.createHash('sha256').update(value).digest()];
  ctx.notice_ = (...args) => sent.push(args);
  const pending = { path: 'orders/order', updateTime: 'one', data: { farmerId: '', customerId: 'customer', farmName: 'Farm', status: 'pending', approvalStatus: 'pending' } };
  ctx.processUpdate_(pending, 'orders');
  assert.equal(sent.length, 0);
  const approved = { ...pending, updateTime: 'two', data: { ...pending.data, farmerId: 'farmer', approvalStatus: 'approved' } };
  ctx.processUpdate_(approved, 'orders');
  ctx.processUpdate_(approved, 'orders');
  assert.deepEqual(sent.map(args => [args[0], args[2]]), [['farmer', 'New approved order'], ['customer', 'Order approved']]);
});

test('approval inbox records reach the existing push sender without duplicate order alerts', () => {
  const { ctx, records } = service();
  const sent = [];
  ctx.Utilities.DigestAlgorithm = { SHA_256: 'sha256' };
  ctx.Utilities.computeDigest = (_, value) => [...crypto.createHash('sha256').update(value).digest()];
  ctx.notice_ = (...args) => sent.push(args);
  records.set('farms/farmer', { owner: 'farmer' });
  records.set('users/farmer/notifications/approval_product_crop', { title: 'Product approved', body: 'Crop approved', target: 'product:crop', pushDelivered: false });
  records.set('users/farmer/notifications/approval_market_stall', { title: 'Market rejected', body: 'Stall rejected', target: '', pushDelivered: false });
  records.set('users/customer/notifications/approval_order_order', { title: 'Order approved', body: 'Order approved', target: 'order:order', pushDelivered: false });
  ctx.processUpdate_({ path: 'products/crop', updateTime: 'product-one', data: { stock: 5, farmId: 'farmer', name: 'Crop', archived: false, approvalStatus: 'approved' } }, 'products');
  ctx.processUpdate_({ path: 'farmersMarkets/stall', updateTime: 'market-one', data: { owner: 'farmer', approvalStatus: 'rejected' } }, 'farmersMarkets');
  ctx.processUpdate_({ path: 'orders/order', updateTime: 'order-one', data: { farmerId: 'farmer', customerId: 'customer', farmName: 'Farm', status: 'pending', approvalStatus: 'pending' } }, 'orders');
  ctx.processUpdate_({ path: 'orders/order', updateTime: 'order-two', data: { farmerId: 'farmer', customerId: 'customer', farmName: 'Farm', status: 'pending', approvalStatus: 'approved' } }, 'orders');
  assert.deepEqual(sent.filter(args => args[0] === 'customer').map(args => args[1]), ['approval_order_order']);
  assert.deepEqual(sent.filter(args => args[0] === 'farmer' && args[1].startsWith('approval_')).map(args => args[1]), ['approval_product_crop', 'approval_market_stall']);
});

test('guest catalog exposes only public fields and keeps private actions authenticated', () => {
  const {ctx, records} = service();
  records.set('farms/open', {active:true});
  records.set('farms/closed', {active:false});
  const queries=[];
  ctx.query_ = (collection, filters, size, group, parent, order) => {
    queries.push({collection,filters,size,order});
    if (collection==='products') return [
      {path:'products/tomato', data:{name:'Tomato', farmId:'open', price:10000, stock:5, image:'photo', privateNote:'SECRET', owner:'PRIVATE'}},
      {path:'products/hidden', data:{name:'Hidden', farmId:'closed', privateNote:'SECRET'}},
    ];
    if (collection==='farms') return [{path:'farms/open',data:{name:'Open farm',owner:'PRIVATE',email:'SECRET',location:'Market',image:'banner'}}];
    return [];
  };
  ctx.identity_ = () => { const e=new Error('Sign in again');e.code='unauthenticated';throw e; };
  ctx.json_ = value => value;
  const response=ctx.doPost({postData:{contents:JSON.stringify({action:'publicCatalog',data:{}})}});
  assert.equal(response.data.products.length,1);
  assert.equal(response.data.products[0].image,'photo');
  assert.equal(response.data.farms[0].image,'banner');
  assert.equal(JSON.stringify(response).includes('PRIVATE'),false);
  assert.equal(JSON.stringify(response).includes('SECRET'),false);
  assert.deepEqual(queries.map(q=>q.collection),['products','farms','categories','farmersMarkets']);
  assert.equal(queries[0].filters[0].fieldFilter.field.fieldPath,'archived');
  assert.equal(queries[0].filters[0].fieldFilter.value.booleanValue,false);
  assert.equal(ctx.doPost({postData:{contents:JSON.stringify({action:'verifyEmailCode',data:{}})}}).error.code,'unauthenticated');
  assert.throws(()=>ctx.publicCatalog_({cursors:{products:'../users'}}),/Invalid catalog/);
  queries.length=0;
  ctx.publicCatalog_({cursors:{products:'tomato',farms:null,categories:null,markets:null}});
  assert.equal(queries.length,1);
  assert.match(queries[0].filters[1].fieldFilter.value.referenceValue,/\/products\/tomato$/);
});
