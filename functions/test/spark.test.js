const {test,before,after}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,getDocs,collection,query,where,orderBy,documentId,updateDoc,writeBatch,serverTimestamp,runTransaction,arrayUnion,arrayRemove}=require('firebase/firestore');
let env; const now=()=>serverTimestamp();
before(async()=>{
 env=await initializeTestEnvironment({projectId:'demo-harvesthub',firestore:{rules:fs.readFileSync(path.join(__dirname,'../../config/firebase/firestore.rules'),'utf8')}});
 await env.clearFirestore();
 await env.withSecurityRulesDisabled(async c=>{
 const db=c.firestore();
 for(const role of ['admin','farmer','customer']) await setDoc(doc(db,`users/${role}`),{name:role[0].toUpperCase()+role.slice(1),email:`${role}@test.local`,role,active:true,phone:'',address:'',createdAt:now()});
 await setDoc(doc(db,'farms/farmer'),{owner:'farmer',name:'Farm',pickupSlots:['11 AM - 1 PM'],location:'',market:'Market',description:'',image:'',active:true,createdAt:now()});
 await setDoc(doc(db,'categories/VmVn'),{name:'Vegetables',productCount:0,createdAt:now()});
 });
});
after(async()=>env?.cleanup());
const proof=email=>({firebase:{sign_in_provider:'custom'},hh_email_2fa:true,hh_security_version:0,hh_verified_email:email});
const db=role=>env.authenticatedContext(role,{email:`${role}@test.local`,...proof(`${role}@test.local`)}).firestore();
const product=()=>({name:'Carrot',farmId:'farmer',farmName:'Farm',category:'Vegetables',categoryId:'VmVn',price:250,stock:10,image:'',unit:'kg',description:'Fresh',archived:false,createdAt:now(),updatedAt:now()});

test('product catalog queries load for all roles', async () => {
 await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'products/catalog-check'),product()));
 for(const role of ['admin','farmer','customer']) {
  const products=collection(db(role),'products');
  const q=role==='admin' ? query(products,orderBy(documentId())) : query(products,where('archived','==',false),orderBy(documentId()));
  const rows=await assertSucceeds(getDocs(q));
  assert.ok(rows.docs.some(row=>row.id==='catalog-check'));
 }
});

test('farm-banner ownership and image size are enforced', async () => {
 await env.withSecurityRulesDisabled(async c => {
  await setDoc(doc(c.firestore(),'users/otherfarmer'),{name:'Other',role:'farmer',active:true});
 });
 const image='data:image/jpeg;base64,'+'A'.repeat(130000);
 await assertSucceeds(updateDoc(doc(db('farmer'),'farms/farmer'),{image,updatedAt:now()}));
 assert.equal((await getDoc(doc(db('customer'),'farms/farmer'))).data().image,image);
 await assertFails(updateDoc(doc(db('customer'),'farms/farmer'),{image:'forged',updatedAt:now()}));
 await assertFails(updateDoc(doc(db('otherfarmer'),'farms/farmer'),{image:'forged',updatedAt:now()}));
 await assertFails(updateDoc(doc(db('farmer'),'farms/farmer'),{image:'A'.repeat(140001),updatedAt:now()}));
 await assertFails(updateDoc(doc(db('farmer'),'farms/farmer'),{owner:'otherfarmer',image:'changed',updatedAt:now()}));
});

test('all roles honor server 2FA setting and cannot edit it directly', async () => {
 for (const role of ['admin','customer','farmer']) {
  for (const flag of [undefined,false,true]) {
   const uid=`mandatory-${role}-${String(flag)}`, email=`${uid}@test.local`;
   await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),`users/${uid}`),{name:role,email,role,active:true,...(flag===undefined?{}:{email2faEnabled:flag})}));
   const password=env.authenticatedContext(uid,{email,firebase:{sign_in_provider:'password'},email_verified:true}).firestore();
   await assertSucceeds(getDoc(doc(password,`users/${uid}`)));
   await (flag === false ? assertSucceeds : assertFails)(getDoc(doc(password,'categories/VmVn')));
   await assertFails(updateDoc(doc(password,`users/${uid}`),{email2faEnabled:flag === false,updatedAt:now()}));
   const verified=env.authenticatedContext(uid,{email,...proof(email)}).firestore();
   await assertSucceeds(getDoc(doc(verified,'categories/VmVn')));
   await assertFails(updateDoc(doc(verified,`users/${uid}`),{email2faEnabled:flag === false,updatedAt:now()}));
   const wrong=env.authenticatedContext(uid,{email,...proof('wrong@test.local')}).firestore();
   await (flag === false ? assertSucceeds : assertFails)(getDoc(doc(wrong,'categories/VmVn')));
  }
 }
});

test('password sessions can register a customer or farmer but must verify before browsing', async () => {
 for(const role of ['customer','farmer']) {
  const uid=`register-${role}`, email=`${uid}@test.local`;
  const d=env.authenticatedContext(uid,{email,firebase:{sign_in_provider:'password'}}).firestore();
  const b=writeBatch(d);
  b.set(doc(d,`users/${uid}`),{name:'New account',email,role,phone:'',address:'',active:false,approvalStatus:'pending',createdAt:now()});
  if(role==='farmer') b.set(doc(d,`farms/${uid}`),{name:'New account',owner:uid,location:'',market:'',description:'',image:'',active:false,createdAt:now()});
  await assertSucceeds(b.commit());
  await assertSucceeds(getDoc(doc(d,`users/${uid}`)));
  const pending=(await assertSucceeds(getDocs(query(collection(db('admin'),'users'),orderBy(documentId()))))).docs.find(row=>row.id===uid);
  assert.equal(pending?.data().approvalStatus,'pending');
  assert.equal(pending?.data().active,false);
  const notification=(await assertSucceeds(getDocs(query(collection(db('admin'),'users'),where('approvalStatus','==','pending'))))).docs.find(row=>row.id===uid);
  assert.equal(notification?.id,uid);
  await assertFails(getDoc(doc(d,'categories/VmVn')));
  await assertFails(updateDoc(doc(d,`users/${uid}`),{active:true,updatedAt:now()}));
  const adminDb=db('admin'), approval=writeBatch(adminDb);
  approval.update(doc(adminDb,`users/${uid}`),{active:true,approvalStatus:'approved',updatedAt:now()});
  if(role==='farmer') approval.update(doc(adminDb,`farms/${uid}`),{active:true,updatedAt:now()});
  await assertSucceeds(approval.commit());
  const approved=env.authenticatedContext(uid,{email,...proof(email)}).firestore();
  await assertSucceeds(getDoc(doc(approved,'categories/VmVn')));
 }
});
test('free-plan registration and roles',async()=>{
 const d=db('new');const p={name:'New',email:'new@test.local',role:'customer',phone:'',address:'',active:false,approvalStatus:'pending',createdAt:now()};
 await assertFails(setDoc(doc(d,'users/new'),{...p,role:'admin'}));
 await assertSucceeds(setDoc(doc(d,'users/new'),p));
 await assertFails(updateDoc(doc(d,'users/new'),{role:'admin'}));
 await assertFails(getDoc(doc(d,'users/admin')));
 await assertFails(updateDoc(doc(d,'users/new'),{avatar:'preset:2',updatedAt:now()}));
 await assertSucceeds(updateDoc(doc(db('admin'),'users/new'),{active:true,approvalStatus:'approved',updatedAt:now()}));
 await assertSucceeds(updateDoc(doc(d,'users/new'),{avatar:'preset:2',updatedAt:now()}));
 await assertFails(updateDoc(doc(db('admin'),'users/admin'),{active:false,updatedAt:now()}));
});
test('admin contact edits and suspension; farmer own catalog transaction',async()=>{
 const a=db('admin');
 await assertSucceeds(updateDoc(doc(a,'users/customer'),{name:'Customer',updatedAt:now()}));
 await assertSucceeds(updateDoc(doc(a,'users/customer'),{active:false,updatedAt:now()}));
 await assertFails(getDoc(doc(db('customer'),'categories/VmVn')));
 await assertSucceeds(updateDoc(doc(a,'users/customer'),{active:true,updatedAt:now()}));
 await assertFails(updateDoc(doc(a,'users/admin'),{active:false,updatedAt:now()}));
 const f=db('farmer');
 await assertFails(setDoc(doc(f,'products/missing-counter'),product()));
 await assertSucceeds(setDoc(doc(f,'products/carrot'),{...product(),archived:true,approvalStatus:'pending'}));
 await assertFails(getDoc(doc(db('customer'),'products/carrot')));
 await assertFails(updateDoc(doc(f,'products/carrot'),{archived:false,approvalStatus:'approved',updatedAt:now()}));
 const b=writeBatch(a);
 b.update(doc(a,'products/carrot'),{archived:false,approvalStatus:'approved',updatedAt:now()});
 b.update(doc(a,'categories/VmVn'),{productCount:1,lastProductId:'carrot'});
 await assertSucceeds(b.commit());
 await assertFails(updateDoc(doc(db('customer'),'products/carrot'),{price:1,updatedAt:now()}));
 await assertFails(updateDoc(doc(f,'products/carrot'),{price:-1,updatedAt:now()}));
 await assertFails(updateDoc(doc(f,'categories/VmVn'),{productCount:99,lastProductId:'carrot'}));
});
test('farmer can create and read a pending product through the app transaction flow',async()=>{
 const f=db('farmer'), ref=doc(f,'products/farmer-pending');
 await assertSucceeds(runTransaction(f,async tx=>{
  const prior=await tx.get(ref);
  assert.equal(prior.exists(),false);
  const farm=await tx.get(doc(f,'farms/farmer'));
  const category=await tx.get(doc(f,'categories/VmVn'));
  assert.equal(farm.data().owner,'farmer');
  assert.equal(category.data().name,'Vegetables');
  tx.set(ref,{...product(),archived:true,approvalStatus:'pending'});
 }));
 const pending=await assertSucceeds(getDoc(ref));
 assert.equal(pending.data().approvalStatus,'pending');
 await assertFails(getDoc(doc(db('customer'),'products/farmer-pending')));
});
test('admin product transaction can read a missing product before creation', async()=>{
 const a=db('admin'), ref=doc(a,'products/admin-new');
 await assertSucceeds(runTransaction(a,async tx=>{
  assert.equal((await tx.get(ref)).exists(),false);
  assert.equal((await tx.get(doc(a,'farms/farmer'))).exists(),true);
  assert.equal((await tx.get(doc(a,'categories/VmVn'))).exists(),true);
  tx.set(ref,{...product(),initialStock:10});
  tx.update(doc(a,'categories/VmVn'),{productCount:1,lastProductId:'admin-new'});
 }));
});
test('farmer markets need admin approval and customer feedback is visible to the farmer',async()=>{
 const f=db('farmer'), a=db('admin'), c=db('customer');
 const market=doc(f,'farmersMarkets/farmer-new');
 await assertSucceeds(setDoc(market,{name:'Farm Market',location:'Street',hours:'Sat',lat:24.9,lng:67.0,active:false,owner:'farmer',approvalStatus:'pending',updatedAt:now()}));
 await assertFails(updateDoc(market,{active:true,approvalStatus:'approved',updatedAt:now()}));
 await assertSucceeds(updateDoc(doc(a,'farmersMarkets/farmer-new'),{active:true,approvalStatus:'approved',updatedAt:now()}));
 const feedback=doc(c,'farmerFeedback/first');
 await assertSucceeds(setDoc(feedback,{farmId:'farmer',customerId:'customer',name:'Customer',email:'customer@test.local',message:'Great produce',createdAt:now()}));
 await assertSucceeds(getDoc(doc(f,'farmerFeedback/first')));
 await assertFails(getDoc(doc(db('otherfarmer'),'farmerFeedback/first')));
});
test('administrator can deliver an approval notice to the farmer inbox',async()=>{
 const a=db('admin'), f=db('farmer');
 const notice=doc(a,'users/farmer/notifications/approval_product_carrot');
 await assertSucceeds(setDoc(notice,{title:'Product approved',body:'Carrot was approved.',target:'product:carrot',pushDelivered:false,createdAt:now()}));
 await assertSucceeds(getDoc(doc(f,'users/farmer/notifications/approval_product_carrot')));
 await assertFails(setDoc(doc(f,'users/farmer/notifications/forged'),{title:'Fake',body:'Fake',createdAt:now()}));
});
async function purchase(id,{price=250,qty=2,stock=8,contact={}}={}){
 const d=db('customer'), b=writeBatch(d);
 b.set(doc(d,`orders/${id}`),{customerId:'customer',customerName:'Customer',farmId:'farmer',farmerId:'',farmName:'Farm',market:'Market',items:[{productId:'carrot',name:'Carrot',image:'',unit:'kg',price,quantity:qty}],quantities:{carrot:qty},total:price*qty,address:'Test address',status:'pending',approvalStatus:'pending',createdAt:now(),...contact});
 b.update(doc(d,'products/carrot'),{stock,lastOrderId:id,updatedAt:now()});
 return b.commit();
}
test('checkout validates snapshots and commits stock with order atomically',async()=>{
 await assertFails(purchase('tampered',{price:1}));
 await assertFails(purchase('wrong-stock',{stock:9}));
 await assertFails(purchase('bad-name',{contact:{recipientName:''}}));
 await assertFails(purchase('long-note',{contact:{note:'x'.repeat(1001)}}));
 await assertFails(purchase('long-phone',{contact:{phone:'1'.repeat(41)}}));
 await assertFails(purchase('forged-account',{contact:{customerName:'Another customer'}}));
 await assertFails(purchase('unsupported-payment',{contact:{paymentMethod:'paid'}}));
 const contact={recipientName:'Pickup recipient',phone:'+923001234567',note:'Please pack separately',paymentMethod:'cashOnDelivery'};
 await assertSucceeds(purchase('valid',{contact}));
 const saved=(await getDoc(doc(db('customer'),'orders/valid'))).data();
 for(const [key,value] of Object.entries(contact)) assert.equal(saved[key],value);
 await assertFails(updateDoc(doc(db('customer'),'orders/valid'),{phone:'+923009999999'}));
 await assertSucceeds(setDoc(doc(db('customer'),'users/customer/pickups/valid'),{slot:'11 AM - 1 PM',updatedAt:now()}));
 await assertFails(setDoc(doc(db('customer'),'users/customer/pickups/valid'),{slot:'Not published',updatedAt:now()}));
 await assertFails(getDoc(doc(db('farmer'),'orders/valid')));
 await assertFails(updateDoc(doc(db('farmer'),'orders/valid'),{status:'confirmed',updatedAt:now()}));
 await assertFails(getDoc(doc(db('farmer'),'users/customer/pickups/valid')));
 await assertSucceeds(updateDoc(doc(db('admin'),'orders/valid'),{farmerId:'farmer',approvalStatus:'approved',updatedAt:now()}));
 await assertSucceeds(getDoc(doc(db('farmer'),'users/customer/pickups/valid')));
 await assertFails(setDoc(doc(db('customer'),'users/customer/pickups/orphan'),{slot:'11 AM - 1 PM',updatedAt:now()}));
 assert.equal((await getDoc(doc(db('admin'),'products/carrot'))).data().stock,8);
 await assertFails(updateDoc(doc(db('customer'),'products/carrot'),{stock:6,lastOrderId:'valid',updatedAt:now()}));
});
test('order lifecycle, immutable snapshots and exactly-once cancellation',async()=>{
 const f=db('farmer'); const ref=doc(f,'orders/valid');
 await assertFails(updateDoc(ref,{status:'completed',updatedAt:now()}));
 await assertFails(updateDoc(ref,{total:1,status:'confirmed',updatedAt:now()}));
 await assertSucceeds(updateDoc(ref,{status:'confirmed',updatedAt:now()}));
 await assertSucceeds(runTransaction(f,async tx=>{
  const order=(await tx.get(ref)).data();const pr=doc(f,'products/carrot');const p=(await tx.get(pr)).data();
  if(order.status==='cancelled') return;
  tx.update(pr,{stock:p.stock+order.items[0].quantity,updatedAt:now()});tx.update(ref,{status:'cancelled',updatedAt:now()});
 }));
 await assertFails(updateDoc(ref,{status:'ready',updatedAt:now()}));
 assert.equal((await getDoc(doc(f,'products/carrot'))).data().stock,10);
});
test('customer feedback is private and immutable',async()=>{
 const c=db('customer');await assertSucceeds(setDoc(doc(c,'feedback/test'),{userId:'customer',email:'customer@test.local',message:'Helpful app',read:false,createdAt:now()}));
 await assertFails(getDoc(doc(c,'feedback/test')));await assertSucceeds(getDoc(doc(db('admin'),'feedback/test')));
});

test('four-farm checkout is accepted without the old three-order limit',async()=>{
 await env.withSecurityRulesDisabled(async c=>{
  const d=c.firestore();
  for(let i=1;i<=4;i++) {
   await setDoc(doc(d,`farms/f${i}`),{owner:`f${i}`,name:`Farm ${i}`,market:'Market',active:true});
   await setDoc(doc(d,`products/p${i}`),{...product(),farmId:`f${i}`,farmName:`Farm ${i}`});
  }
 });
 const d=db('customer'),b=writeBatch(d);
 for(let i=1;i<=4;i++) {
  b.set(doc(d,`orders/multi${i}`),{customerId:'customer',customerName:'Customer',farmId:`f${i}`,farmerId:'',farmName:`Farm ${i}`,market:'Market',items:[{productId:`p${i}`,name:'Carrot',image:'',unit:'kg',price:250,quantity:2}],quantities:{[`p${i}`]:2},total:500,address:'Test',status:'pending',approvalStatus:'pending',createdAt:now()});
  b.update(doc(d,`products/p${i}`),{stock:8,lastOrderId:`multi${i}`,updatedAt:now()});
 }
 b.set(doc(d,'checkoutRequests/customer_multi'),{userId:'customer',orderIds:['multi1','multi2','multi3','multi4'],createdAt:now()});
 await assertSucceeds(b.commit());
});

test('one order can contain four products from the same farm',async()=>{
 await env.withSecurityRulesDisabled(async c=>{
  const d=c.firestore();
  for(let i=1;i<=4;i++) await setDoc(doc(d,`products/group${i}`),{...product(),name:`Crop ${i}`});
 });
 const d=db('customer'), b=writeBatch(d);
 b.set(doc(d,'orders/grouped'),{customerId:'customer',customerName:'Customer',farmId:'farmer',farmerId:'',farmName:'Farm',market:'Market',items:[1,2,3,4].map(i=>({productId:`group${i}`,name:`Crop ${i}`,image:'',unit:'kg',price:250,quantity:2})),quantities:{group1:2,group2:2,group3:2,group4:2},total:2000,address:'Test',status:'pending',approvalStatus:'pending',createdAt:now()});
 for(let i=1;i<=4;i++) b.update(doc(d,`products/group${i}`),{stock:8,lastOrderId:'grouped',updatedAt:now()});
 b.set(doc(d,'checkoutRequests/customer_grouped'),{userId:'customer',orderIds:['grouped'],createdAt:now()});
 await assertSucceeds(b.commit());
 assert.equal((await getDoc(doc(d,'orders/grouped'))).data().items.length,4);
});

test('one order can contain eight products from the same farm',async()=>{
 await env.withSecurityRulesDisabled(async c=>{
  const d=c.firestore();
  for(let i=1;i<=8;i++) await setDoc(doc(d,`products/bulk${i}`),{...product(),name:`Bulk crop ${i}`});
 });
 const d=db('customer'), b=writeBatch(d);
 const ids=[1,2,3,4,5,6,7,8];
 b.set(doc(d,'orders/bulk'),{customerId:'customer',customerName:'Customer',farmId:'farmer',farmerId:'',farmName:'Farm',market:'Market',items:ids.map(i=>({productId:`bulk${i}`,name:`Bulk crop ${i}`,image:'',unit:'kg',price:250,quantity:1})),quantities:Object.fromEntries(ids.map(i=>[`bulk${i}`,1])),total:2000,address:'Test',status:'pending',approvalStatus:'pending',createdAt:now()});
 for(const i of ids) b.update(doc(d,`products/bulk${i}`),{stock:9,lastOrderId:'bulk',updatedAt:now()});
 b.set(doc(d,'users/customer/pickups/bulk'),{slot:'11 AM - 1 PM',updatedAt:now()});
 b.set(doc(d,'checkoutRequests/customer_bulk'),{userId:'customer',orderIds:['bulk'],createdAt:now()});
 await assertSucceeds(b.commit());
});


test('farm availability and markets are role protected; notifications cannot be forged', async()=>{
 const f=db('farmer'), c=db('customer'), a=db('admin');
 await assertSucceeds(updateDoc(doc(f,'farms/farmer'),{pickupSlots:['Sat 10:00-12:00'],lat:24.86,lng:67.01,updatedAt:now()}));
 await assertFails(updateDoc(doc(c,'farms/farmer'),{pickupSlots:['fake'],updatedAt:now()}));
 await assertFails(updateDoc(doc(f,'farms/farmer'),{lat:200,updatedAt:now()}));
 await assertFails(setDoc(doc(c,'users/customer/notifications/forged'),{title:'Fake',body:'Fake',createdAt:now()}));
 await assertSucceeds(setDoc(doc(c,'users/customer/devices/test-token'),{platform:'android',updatedAt:now()}));
 await assertFails(getDoc(doc(f,'users/customer/devices/test-token')));
 const market={name:'Test market',location:'Test address',hours:'Saturday 10-12',lat:24.86,lng:67.01,active:true,updatedAt:now()};
 await assertFails(setDoc(doc(f,'farmersMarkets/test'),market));
 await assertSucceeds(setDoc(doc(a,'farmersMarkets/test'),market));
 await assertSucceeds(getDoc(doc(c,'farmersMarkets/test')));
});

 test('email two-step blocks password sessions and stale proofs',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    await setDoc(doc(c.firestore(),'users/secured'),{name:'Secured',email:'secured@test.local',role:'customer',active:true,email2faEnabled:true,securityVersion:2});
  });
  const plain=env.authenticatedContext('secured',{email:'secured@test.local',firebase:{sign_in_provider:'password'}}).firestore();
  await assertSucceeds(getDoc(doc(plain,'users/secured')));
  await assertFails(getDoc(doc(plain,'categories/VmVn')));
  await assertFails(updateDoc(doc(plain,'users/secured'),{email2faEnabled:false}));
  const stale=env.authenticatedContext('secured',{firebase:{sign_in_provider:'custom'},hh_email_2fa:true,hh_security_version:1}).firestore();
  await assertFails(getDoc(doc(stale,'categories/VmVn')));
  const verified=env.authenticatedContext('secured',{firebase:{sign_in_provider:'custom'},hh_email_2fa:true,hh_security_version:2,hh_verified_email:'secured@test.local'}).firestore();
  await assertSucceeds(getDoc(doc(verified,'categories/VmVn')));
  await assertFails(getDoc(doc(verified,'emailSecurityChallenges/secured')));
  await assertFails(updateDoc(doc(verified,'users/secured'),{email2faEnabled:false,updatedAt:now()}));
 });

test('farmer follows persist independently of saved products and stay private', async () => {
 const f = db('farmer'), preferences = doc(f, 'users/farmer/private/preferences');
 await assertSucceeds(setDoc(preferences, { saved: ['carrot'], followed: [] }));
 await assertSucceeds(updateDoc(preferences, { followed: arrayUnion('f1') }));
 assert.deepEqual((await getDoc(preferences)).data(), { saved: ['carrot'], followed: ['f1'] });
 await assertFails(getDoc(doc(db('customer'), 'users/farmer/private/preferences')));
 await assertFails(updateDoc(doc(db('customer'), 'users/farmer/private/preferences'), { followed: [] }));
 await assertSucceeds(updateDoc(preferences, { followed: arrayRemove('f1') }));
 assert.deepEqual((await getDoc(preferences)).data().followed, []);
});

test('only administrators can publish the public About page; merging preserves other settings',async()=>{
 const path='appConfig/public';
 await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),path),{contactEmail:'support@test.local',retainedSetting:true}));
 const content={aboutVersion:1,aboutHeadline:'Our updated story',about:'Published by the administrator',aboutCommunityBody:'',updatedAt:now()};
 await assertFails(setDoc(doc(db('customer'),path),content,{merge:true}));
 await assertFails(setDoc(doc(db('farmer'),path),content,{merge:true}));
 await assertSucceeds(setDoc(doc(db('admin'),path),content,{merge:true}));
 const data=(await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(),path)))).data();
 assert.equal(data.aboutHeadline,'Our updated story');
 assert.equal(data.aboutCommunityBody,'');
 assert.equal(data.contactEmail,'support@test.local');
 assert.equal(data.retainedSetting,true);
});

test('notification recipients can mark read but cannot forge, edit or read others notices', async () => {
 await env.withSecurityRulesDisabled(async c => {
  await setDoc(doc(c.firestore(), 'users/customer/notifications/server-created'), { title: 'Order update', body: 'Ready', target: 'order:valid', createdAt: now() });
 });
 const ref = doc(db('customer'), 'users/customer/notifications/server-created');
 await assertSucceeds(updateDoc(ref, { readAt: now() }));
 await assertFails(updateDoc(ref, { title: 'Forged', readAt: now() }));
 await assertFails(getDoc(doc(db('farmer'), 'users/customer/notifications/server-created')));
});

test('email synchronization requires verified ownership and preserves security fields', async () => {
 const verified = env.authenticatedContext('customer', { email: 'new@test.local', email_verified: true, ...proof('customer@test.local') }).firestore();
 const unverified = env.authenticatedContext('customer', { email: 'new@test.local', email_verified: false }).firestore();
 await assertFails(updateDoc(doc(unverified, 'users/customer'), { email: 'new@test.local', updatedAt: now() }));
 await assertFails(updateDoc(doc(verified, 'users/customer'), { email: 'other@test.local', updatedAt: now() }));
 await assertFails(updateDoc(doc(verified, 'users/customer'), { email: 'new@test.local', email2faEnabled: false, updatedAt: now() }));
 await assertSucceeds(updateDoc(doc(verified, 'users/customer'), { email: 'new@test.local', updatedAt: now() }));
 const passwordOnly = env.authenticatedContext('secured', { email: 'attacker@test.local', email_verified: true, firebase: { sign_in_provider: 'password' } }).firestore();
 await assertFails(updateDoc(doc(passwordOnly, 'users/secured'), { email: 'attacker@test.local', updatedAt: now() }));
});
