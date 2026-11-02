const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, writeBatch, serverTimestamp } = require('firebase/firestore');
const { ref, uploadBytes, deleteObject } = require('firebase/storage');
const enabled = !!process.env.FIRESTORE_EMULATOR_HOST;
const projectId = 'demo-harvesthub';
let env, db;
const tokens = {};
before(async()=> {
  if (!enabled) return;
  env=await initializeTestEnvironment({projectId,firestore:{rules:fs.readFileSync('../firestore.rules','utf8')},
    ...(process.env.FIREBASE_STORAGE_EMULATOR_HOST ? {storage:{rules:fs.readFileSync('../storage.rules','utf8')}} : {})});
  const { initializeApp } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  initializeApp({projectId}); db=getFirestore();
  for (const role of ['admin','customer','farmer']) {
    const res=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=test',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:`${role}@test.local`,password:'emulator-only-password',returnSecureToken:true})});
    const data=await res.json(); tokens[role]={token:data.idToken,uid:data.localId};
    await db.doc(`users/${data.localId}`).set({name:role,email:`${role}@test.local`,role,active:true,createdAt:new Date()});
  }
  await db.doc(`farms/${tokens.farmer.uid}`).set({owner:tokens.farmer.uid,name:'Test farm',active:true,market:'Test market'});
});
after(async()=>{if(env) await env.cleanup();});
async function call(role,name,data) {
  const res=await fetch(`http://127.0.0.1:5001/${projectId}/us-central1/${name}`,{method:'POST',headers:{'Content-Type':'application/json',...(role?{Authorization:`Bearer ${tokens[role].token}`}:{})},body:JSON.stringify({data})});
  return res.json();
}
test('rules deny impersonation, direct writes and private reads',{skip:!enabled},async()=> {
  const customer=env.authenticatedContext(tokens.customer.uid).firestore();
  const farmer=env.authenticatedContext(tokens.farmer.uid).firestore();
  const admin=env.authenticatedContext(tokens.admin.uid).firestore();
  await assertSucceeds(getDoc(doc(customer,`users/${tokens.customer.uid}`)));
  await assertFails(setDoc(doc(customer,`users/${tokens.customer.uid}`),{role:'admin'}));
  await assertFails(getDoc(doc(customer,`users/${tokens.admin.uid}`)));
  await assertFails(getDoc(doc(farmer,`users/${tokens.customer.uid}`)));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),`users/${tokens.admin.uid}`)));
  await assertSucceeds(getDoc(doc(admin,`users/${tokens.customer.uid}`)));
  await assertFails(setDoc(doc(admin,'products/direct-write'),{stock:100}));
});
test('existing self-registration and preference rules remain compatible without role escalation',{skip:!enabled},async()=> {
  const customer=env.authenticatedContext('new-customer',{email:'new-customer@test.local'}).firestore();
  const profile={name:'New customer',email:'new-customer@test.local',role:'customer',phone:'',address:'',active:true,createdAt:serverTimestamp()};
  await assertFails(setDoc(doc(customer,'users/new-customer'),{...profile,role:'admin'}));
  await assertFails(setDoc(doc(customer,'users/someone-else'),profile));
  await assertSucceeds(setDoc(doc(customer,'users/new-customer'),profile));
  await assertSucceeds(setDoc(doc(customer,'users/new-customer/private/preferences'),{saved:['test-product'],followed:[],readNotices:[]}));
  await assertFails(setDoc(doc(customer,'users/new-customer/private/preferences'),{role:'admin'}));
  const farmer=env.authenticatedContext('new-farmer',{email:'new-farmer@test.local'}).firestore();
  const batch=writeBatch(farmer);
  batch.set(doc(farmer,'users/new-farmer'),{...profile,name:'New farmer',email:'new-farmer@test.local',role:'farmer'});
  batch.set(doc(farmer,'farms/new-farmer'),{name:'New farmer',owner:'new-farmer',location:'',market:'',description:'',image:'',active:true,createdAt:serverTimestamp()});
  await assertSucceeds(batch.commit());
});
test('authentication accepts correct credentials and rejects a wrong password',{skip:!enabled},async()=> {
  for(const password of ['wrong-password','emulator-only-password']) {
    const response=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=test',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'admin@test.local',password,returnSecureToken:true})});
    const data=await response.json();
    if(password==='wrong-password') assert.ok(data.error); else assert.equal(data.localId,tokens.admin.uid);
  }
});
test('storage permits owner uploads by farmers/admins and rejects unsafe access',{skip:!enabled || !process.env.FIREBASE_STORAGE_EMULATOR_HOST},async()=> {
  const bytes=new Uint8Array([255,216,255,0]);
  for(const role of ['admin','farmer']) {
    const storage=env.authenticatedContext(tokens[role].uid).storage();
    const object=ref(storage,`productImages/${tokens[role].uid}/test/image.jpg`);
    await assertSucceeds(uploadBytes(object,bytes,{contentType:'image/jpeg'}));
    await assertFails(deleteObject(object));
    await assertFails(uploadBytes(ref(storage,`productImages/${tokens[role].uid}/test/unsafe.html`),bytes,{contentType:'text/html'}));
  }
  const customer=env.authenticatedContext(tokens.customer.uid).storage();
  await assertFails(uploadBytes(ref(customer,`productImages/${tokens.customer.uid}/test/image.jpg`),bytes,{contentType:'image/jpeg'}));
  const farmer=env.authenticatedContext(tokens.farmer.uid).storage();
  await assertFails(uploadBytes(ref(farmer,`productImages/${tokens.admin.uid}/test/other.jpg`),bytes,{contentType:'image/jpeg'}));
});
test('callables enforce RBAC and transactional category/order integrity',{skip:!enabled},async()=> {
  for (const role of ['customer','farmer',null]) assert.ok((await call(role,'mutate',{action:'saveCategory',value:{name:'Forbidden'}})).error);
  assert.ok((await call('customer','registerProfile',{role:'admin',name:'Escalation'})).error);
  assert.ok((await call('admin','mutate',{action:'saveCategory',value:{name:'Vegetables'}})).result);
  assert.ok((await call('admin','mutate',{action:'saveCategory',value:{name:'vegetables'}})).error);
  const product={id:'test-product',name:'Tomato',category:'Vegetables',farmId:tokens.farmer.uid,price:18000,stock:2,image:'',unit:'kg',description:''};
  assert.ok((await call('farmer','mutate',{action:'saveProduct',value:{...product,price:-1}})).error);
  assert.ok((await call('farmer','mutate',{action:'saveProduct',value:product})).result);
  assert.ok((await call('admin','mutate',{action:'deleteCategory',value:{name:'Vegetables'}})).error);
  assert.ok((await call('customer','mutate',{action:'saveProduct',value:product})).error);
  const payload={requestId:'checkout-one',address:'Test address',items:[{id:product.id,quantity:2}]};
  const results=await Promise.all([call('customer','checkout',payload),call('customer','checkout',payload)]);
  assert.deepEqual(results[0].result.orderIds,results[1].result.orderIds);
  const orderId=results[0].result.orderIds[0];
  assert.equal((await db.doc('products/test-product').get()).data().stock,0);
  assert.ok((await call('customer','checkout',{...payload,requestId:'checkout-two'})).error);
  assert.ok((await call('admin','mutate',{action:'updateStatus',value:{id:orderId,status:'completed'}})).error);
  const cancellations=await Promise.all([1,2].map(()=>call('admin','mutate',{action:'updateStatus',value:{id:orderId,status:'cancelled'}})));
  assert.equal(cancellations.filter(x=>x.result).length,1);
  assert.equal((await db.doc('products/test-product').get()).data().stock,2);
  assert.equal((await db.doc(`orders/${orderId}`).get()).data().items[0].price,18000);
  assert.ok((await call('admin','mutate',{action:'saveCategory',value:{name:'Garden',previous:'Vegetables'}})).result);
  assert.equal((await db.doc('products/test-product').get()).data().category,'Garden');
  assert.ok((await call('admin','mutate',{action:'deleteProduct',value:{id:product.id}})).result);
  assert.ok((await call('admin','mutate',{action:'deleteCategory',value:{name:'Garden'}})).result);
  assert.ok((await call('admin','mutate',{action:'toggleAccount',value:{id:tokens.farmer.uid,active:false}})).result);
  assert.ok((await call('farmer','platformReport',{days:7})).error);
  const report=await call('admin','platformReport',{days:7});
  assert.equal(report.result.totalOrders,1); assert.equal(report.result.orderValue,36000); assert.equal(report.result.completedValue,0);
});
