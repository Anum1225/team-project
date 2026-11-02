'use strict';
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const options = document => ({ document, region: 'us-central1', maxInstances: 3, retry: true });

// Deterministic inbox IDs make retried trigger events idempotent. FCM delivery
// itself is best-effort: inbox records are the durable source of truth.
async function notify(uid, eventId, title, body) {
  if (!uid) return;
  const db = getFirestore();
  const user = await db.doc(`users/${uid}`).get();
  if (!user.exists || user.data().active !== true) return;
  const ref = db.doc(`users/${uid}/notifications/${eventId.replace(/[^a-zA-Z0-9_-]/g, '_')}`);
  try { await ref.create({ title, body, createdAt: FieldValue.serverTimestamp() }); }
  catch (e) { if (e.code !== 6) throw e; if ((await ref.get()).data()?.pushDelivered === true) return; }
  const devices = await db.collection(`users/${uid}/devices`).get();
  for (let offset = 0; offset < devices.size; offset += 500) {
    const batch = devices.docs.slice(offset, offset + 500);
    const result = await getMessaging().sendEachForMulticast({
      tokens: batch.map(d => d.id), notification: { title, body },
      android: { priority: 'high', notification: { tag: ref.id } },
      data: { notificationId: ref.id },
    });
    const retryable = result.responses.some(r => r.error && !['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error.code));
    await Promise.all(result.responses.map((r, i) =>
      ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error?.code)
        ? batch[i].ref.delete() : Promise.resolve()));
    if (retryable) throw new Error('Transient push delivery failure; retry the event.');
  }
  await ref.update({ pushDelivered: true });
}

exports.orderCreated = onDocumentCreated(options('orders/{id}'), async e => {
  const d = e.data.data();
  await notify(d.farmerId, e.id, 'New order', `A new order is ready to review for ${d.farmName}.`);
});
exports.orderUpdated = onDocumentUpdated(options('orders/{id}'), async e => {
  const before = e.data.before.data(), after = e.data.after.data();
  if (before.status !== after.status) await notify(after.customerId, e.id, 'Order update', `Your order is now ${after.status === 'ready' ? 'ready for pickup' : after.status}.`);
});
exports.pickupChanged = onDocumentWritten(options('users/{uid}/pickups/{id}'), async e => {
  const before = e.data.before.data(), after = e.data.after.data();
  if (before?.slot === after?.slot) return;
  const order = await getFirestore().doc(`orders/${e.params.id}`).get();
  if (order.exists) await notify(order.data().farmerId, e.id, 'Pickup booking changed', after?.slot ? `Requested window: ${after.slot}` : 'The customer cancelled the pickup booking.');
});
exports.productStockChanged = onDocumentUpdated(options('products/{id}'), async e => {
  const before = e.data.before.data(), after = e.data.after.data();
  if (after.archived) return;
  const db = getFirestore();
  if (before.stock > 5 && after.stock <= 5) {
    const farm = await db.doc(`farms/${after.farmId}`).get();
    if (farm.exists) await notify(farm.data().owner, e.id, 'Low stock', `${after.name}: ${after.stock} remaining.`);
  }
  if (before.stock > 0 || after.stock <= 0) return;
  const [saved, followed] = await Promise.all([
    db.collectionGroup('private').where('saved', 'array-contains', e.params.id).get(),
    db.collectionGroup('private').where('followed', 'array-contains', after.farmId).get(),
  ]);
  const uids = new Set([...saved.docs, ...followed.docs].map(d => d.ref.parent.parent.id));
  for (const uid of uids) await notify(uid, e.id, 'Back in stock', `${after.name} is available again.`);
});
