// Run with Application Default Credentials on a trusted administrator machine.
// Create the email/password account in Firebase Console first; no passwords in files.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
async function main() {
  const [projectId, uid] = process.argv.slice(2);
  if (!projectId || !uid) throw new Error('Usage: node provision-admin.js PROJECT_ID EXISTING_AUTH_UID');
  initializeApp({projectId});
  const account = await getAuth().getUser(uid);
  if (!account.email || account.disabled) throw new Error('An active email/password account is required.');
  const ref = getFirestore().doc(`users/${uid}`);
  await getFirestore().runTransaction(async tx => {
    const existing = await tx.get(ref);
    if (existing.exists && existing.data().role !== 'admin') throw new Error('Use a dedicated administrator account; do not promote marketplace profiles.');
    tx.set(ref, {name:account.displayName || 'HarvestHub administrator',email:account.email,role:'admin',active:true,phone:'',address:'',createdAt:existing.data()?.createdAt || FieldValue.serverTimestamp()});
  });
  console.log('Administrator profile provisioned:',uid);
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
