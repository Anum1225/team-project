'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { transition, summarize } = require('./domain');
initializeApp();
const db = getFirestore();
const stamp = () => FieldValue.serverTimestamp();
const fail = (message, code = 'invalid-argument') => { throw new HttpsError(code, message); };
function text(value, name, optional = false, max = 500) {
  if (typeof value !== 'string' || value.trim().length > max || (!optional && !value.trim())) fail(`Check ${name}.`);
  return value.trim();
}
function id(value) { const v = text(value, 'record ID', false, 160); if (!/^[a-zA-Z0-9_-]+$/.test(v)) fail('Invalid record ID.'); return v; }
function integer(value, name) { if (!Number.isSafeInteger(value) || value < 0 || value > 1000000000) fail(`Check ${name}.`); return value; }
function categoryId(name) { return Buffer.from(name.toLowerCase()).toString('base64url'); }
function image(value) {
  const v = text(value || '', 'image', true, 2048);
  if (v && !v.startsWith('https://firebasestorage.googleapis.com/') && !v.startsWith('http://127.0.0.1:9199/') && !v.startsWith('http://localhost:9199/')) fail('Choose an uploaded image.');
  return v;
}
async function actor(tx, uid, allowed) {
  const snap = await tx.get(db.doc(`users/${uid}`)); const a = snap.data();
  if (!a || a.active !== true || !allowed.includes(a.role)) fail('You do not have permission to perform this action.', 'permission-denied');
  return a;
}
function audit(tx, uid, action, entityId) { tx.create(db.collection('adminActivityLogs').doc(), { adminId: uid, action, entityId, createdAt: stamp() }); }
const callable = fn => onCall({ region: 'us-central1', maxInstances: 10, timeoutSeconds: 120 }, async request => {
  if (!request.auth) fail('Please sign in.', 'unauthenticated');
  try { return await fn(request.auth.uid, request.data || {}); }
  catch (e) { if (e instanceof HttpsError) throw e; console.error('HarvestHub operation failed', e); throw new HttpsError('internal', 'The operation could not be completed. Please retry.'); }
});

exports.registerProfile = callable(async (uid, d) => {
  if (!['customer','farmer'].includes(d.role)) fail('Public administrator registration is not allowed.', 'permission-denied');
  const { getAuth } = require('firebase-admin/auth');
  const user = await getAuth().getUser(uid);
  const name = text(d.name, 'name');
  return db.runTransaction(async tx => {
    const ref = db.doc(`users/${uid}`); const existing = await tx.get(ref);
    if (existing.exists) fail('This profile already exists.', 'already-exists');
    tx.create(ref, { name, email: user.email, role: d.role, phone: text(d.phone || '', 'phone', true), address: text(d.address || '', 'address', true), active: true, createdAt: stamp() });
    if (d.role === 'farmer') tx.create(db.doc(`farms/${uid}`), { name, owner: uid, location: '', market: '', description: '', image: '', active: true, createdAt: stamp() });
    return { id: uid };
  });
});

exports.mutate = callable(async (uid, d) => {
  const action = text(d.action, 'action'); const v = d.value || {};
  return db.runTransaction(async tx => {
    const a = await actor(tx, uid, ['admin','farmer','customer']);
    const admin = a.role === 'admin';
    if (['saveCategory','deleteCategory','toggleAccount'].includes(action) && !admin) fail('Administrator access required.', 'permission-denied');
    if (action === 'saveAccount' || action === 'toggleAccount') {
      const key = id(v.id); const ref = db.doc(`users/${key}`); const snap = await tx.get(ref); const target = snap.data();
      if (!target || (!admin && key !== uid) || (target.role === 'admin' && key !== uid)) fail('Access denied.', 'permission-denied');
      if (action === 'toggleAccount') {
        if (key === uid || target.role === 'admin' || typeof v.active !== 'boolean') fail('Administrator accounts cannot be suspended here.');
        const farm = await tx.get(db.doc(`farms/${key}`));
        tx.update(ref, { active: v.active, updatedAt: stamp() });
        if (farm.exists) tx.update(farm.ref, { active: v.active, updatedAt: stamp() });
      } else tx.update(ref, { name: text(v.name, 'name'), phone: text(v.phone || '', 'phone', true), address: text(v.address || '', 'address', true), updatedAt: stamp() });
    } else if (action === 'saveFarm') {
      const ref = db.doc(`farms/${id(v.id)}`); const snap = await tx.get(ref);
      if (!snap.exists || (!admin && (a.role !== 'farmer' || snap.data().owner !== uid))) fail('Access denied.', 'permission-denied');
      tx.update(ref, { name: text(v.name, 'farm name'), location: text(v.location || '', 'location', true), market: text(v.market || '', 'market', true), description: text(v.description || '', 'description', true, 5000), updatedAt: stamp() });
    } else if (action === 'saveCategory' || action === 'deleteCategory') {
      const name = text(v.name, 'category', false, 100); const previous = v.previous ? text(v.previous, 'previous category', false, 100) : name;
      const ref = db.doc(`categories/${categoryId(previous)}`); const dest = db.doc(`categories/${categoryId(name)}`);
      const old = await tx.get(ref); const next = ref.path === dest.path ? old : await tx.get(dest);
      if (action === 'deleteCategory') {
        if (!old.exists) fail('Category no longer exists.', 'not-found');
        if ((old.data().productCount || 0) !== 0) fail('Move or archive assigned products before removing this category.', 'failed-precondition');
        tx.delete(ref);
      } else {
        if ((!v.previous || ref.path !== dest.path) && next.exists) fail('This category already exists.', 'already-exists');
        if (v.previous && !old.exists) fail('Category no longer exists.', 'not-found');
        // Every product write also reads/updates this category lock, preventing races.
        const products = v.previous ? await tx.get(db.collection('products').where('category', '==', previous).where('archived', '==', false).limit(400)) : null;
        if (products && products.size >= 400) fail('Reassign products in smaller groups before renaming this category.', 'failed-precondition');
        tx.set(dest, { name, productCount: products?.size || 0, createdAt: old.data()?.createdAt || stamp(), updatedAt: stamp() });
        if (ref.path !== dest.path && old.exists && v.previous) tx.delete(ref);
        for (const p of products?.docs || []) tx.update(p.ref, { category: name, updatedAt: stamp() });
      }
    } else if (action === 'saveProduct' || action === 'deleteProduct') {
      if (!admin && a.role !== 'farmer') fail('Access denied.', 'permission-denied');
      const ref = db.doc(`products/${id(v.id)}`); const old = await tx.get(ref); const existing = old.data();
      const farmId = action === 'deleteProduct' ? existing?.farmId : id(v.farmId);
      if (!farmId) fail('Product no longer exists.', 'not-found');
      const f = await tx.get(db.doc(`farms/${farmId}`));
      if (!f.exists || (!admin && (f.data().active !== true || f.data().owner !== uid))) fail('Choose an active farm you can manage.', 'permission-denied');
      if (existing && !admin && existing.farmId !== farmId) fail('Product ownership cannot be changed.', 'permission-denied');
      if (existing?.archived) fail('This product is archived.', 'failed-precondition');
      const name = action === 'deleteProduct' ? existing.category : text(v.category, 'category', false, 100);
      const catRef = db.doc(`categories/${categoryId(name)}`); const cat = await tx.get(catRef);
      if (!cat.exists || cat.data().name !== name) fail('Choose an existing category.', 'failed-precondition');
      const oldRef = existing && existing.category !== name ? db.doc(`categories/${categoryId(existing.category)}`) : null;
      const oldCat = oldRef ? await tx.get(oldRef) : null;
      if (action === 'deleteProduct') {
        tx.update(ref, { archived: true, stock: 0, updatedAt: stamp() });
        tx.update(catRef, { productCount: FieldValue.increment(-1) });
      } else {
        tx.set(ref, { name: text(v.name, 'product name'), farmId, farmName: f.data().name, category: name, price: integer(v.price, 'price'), stock: integer(v.stock, 'stock'), image: image(v.image), unit: text(v.unit, 'unit', false, 60), description: text(v.description || '', 'description', true, 5000), archived: false, createdAt: existing?.createdAt || stamp(), updatedAt: stamp() });
        tx.update(catRef, { productCount: FieldValue.increment(!existing || oldRef ? 1 : 0), updatedAt: stamp() });
        if (oldCat?.exists) tx.update(oldRef, { productCount: FieldValue.increment(-1) });
      }
    } else if (action === 'updateStatus') {
      const ref = db.doc(`orders/${id(v.id)}`); const snap = await tx.get(ref); const order = snap.data();
      if (!order) fail('Order no longer exists.', 'not-found');
      const farm = await tx.get(db.doc(`farms/${order.farmId}`));
      if (!admin && (a.role !== 'farmer' || farm.data()?.owner !== uid)) fail('Access denied.', 'permission-denied');
      if (!transition(order.status, v.status)) fail('Choose the next status. Closed orders cannot be changed.', 'failed-precondition');
      const products = v.status === 'cancelled' ? await Promise.all(order.items.map(line => tx.get(db.doc(`products/${line.productId}`)))) : [];
      products.forEach((p, i) => { if (p.exists && !p.data().archived) tx.update(p.ref, { stock: FieldValue.increment(order.items[i].quantity), updatedAt: stamp() }); });
      tx.update(ref, { status: v.status, updatedAt: stamp() });
    } else fail('Unknown operation.');
    if (admin) audit(tx, uid, action, v.id || v.name || '');
    return { ok: true };
  });
});

exports.checkout = callable(async (uid, d) => {
  const key = id(d.requestId); const address = text(d.address, 'address');
  const items = d.items;
  if (!Array.isArray(items) || !items.length || items.length > 30) fail('Choose between 1 and 30 products.');
  const ids = items.map(x => id(x.id)); if (new Set(ids).size !== ids.length) fail('Duplicate basket item.');
  items.forEach(x => { integer(x.quantity, 'quantity'); if (!x.quantity) fail('Choose a positive quantity.'); });
  return db.runTransaction(async tx => {
    const a = await actor(tx, uid, ['customer']);
    const receipt = db.doc(`checkoutRequests/${uid}_${key}`); const prior = await tx.get(receipt);
    if (prior.exists) return prior.data();
    const products = await Promise.all(ids.map(x => tx.get(db.doc(`products/${x}`))));
    const farmIds = [...new Set(products.map(p => p.data()?.farmId).filter(Boolean))];
    const farmDocs = await Promise.all(farmIds.map(x => tx.get(db.doc(`farms/${x}`))));
    const farms = new Map(farmDocs.map(f => [f.id, f.data()]));
    const groups = new Map();
    products.forEach((snap, i) => {
      const p = snap.data(); const quantity = items[i].quantity;
      if (!p || p.archived || p.stock < quantity || farms.get(p.farmId)?.active !== true) fail('An item is no longer available. Refresh your basket.', 'failed-precondition');
      const lines = groups.get(p.farmId) || [];
      lines.push({ productId: snap.id, name: p.name, image: p.image, unit: p.unit, price: p.price, quantity }); groups.set(p.farmId, lines);
    });
    const orderIds = [];
    for (const [farmId, lines] of groups) {
      const ref = db.collection('orders').doc(); orderIds.push(ref.id);
      tx.create(ref, { customerId: uid, customerName: a.name, farmId, farmerId: farms.get(farmId).owner, farmName: farms.get(farmId).name, market: farms.get(farmId).market, items: lines, total: lines.reduce((n,l) => n+l.price*l.quantity, 0), address, status: 'pending', createdAt: stamp() });
    }
    products.forEach((p,i) => tx.update(p.ref, { stock: FieldValue.increment(-items[i].quantity), updatedAt: stamp() }));
    tx.create(receipt, { orderIds, createdAt: stamp() });
    return { orderIds };
  });
});

exports.platformReport = callable(async (uid, d) => {
  const a = await db.runTransaction(tx => actor(tx, uid, ['admin','farmer']));
  const days = [1,7,30,36500].includes(d.days) ? d.days : 7;
  let q = db.collection('orders'); if (a.role === 'farmer') q = q.where('farmerId', '==', uid);
  const start = new Date(); start.setUTCHours(0,0,0,0); start.setUTCDate(start.getUTCDate()-days+1);
  q = q.where('createdAt', '>=', start).orderBy('createdAt');
  // Bounded server pages; raw orders are never returned to the reporting client.
  const orders = []; let cursor;
  do { const page = await (cursor ? q.startAfter(cursor) : q).limit(500).get(); orders.push(...page.docs.map(x => x.data())); cursor = page.size === 500 ? page.docs.at(-1) : null; } while (cursor);
  const count = async query => (await query.count().get()).data().count;
  const p = a.role === 'admin' ? db.collection('products') : db.collection('products').where('farmId','==',uid);
  const counts = { products: await count(p.where('archived','==',false)), outOfStock: await count(p.where('archived','==',false).where('stock','==',0)), categories: await count(db.collection('categories')) };
  if (a.role === 'admin') {
    counts.customers = await count(db.collection('users').where('role','==','customer'));
    counts.farmers = await count(db.collection('users').where('role','==','farmer'));
    counts.activeFarmers = await count(db.collection('users').where('role','==','farmer').where('active','==',true));
  }
  // Orders snapshot the market at checkout. No per-order farm reads are needed.
  const result = summarize(orders, new Map(), counts, days);
  if (days === 36500) result.trend = [];
  result.farmers = result.farmers.slice(0, 20);
  return result;
});

exports.submitFeedback = callable(async (uid, d) => {
  await db.runTransaction(tx => actor(tx, uid, ['admin','customer','farmer']));
  await db.collection('feedback').add({ userId: uid, email: text(d.email,'email'), message: text(d.message,'message',false,5000), createdAt: stamp(), read: false });
  return { ok: true };
});
