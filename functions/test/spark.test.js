const {test,before,after}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,updateDoc,writeBatch,serverTimestamp,runTransaction}=require('firebase/firestore');
let env; const now=()=>serverTimestamp();
before(async()=>{
 env=await initializeTestEnvironment({projectId:'demo-harvesthub',firestore:{rules:fs.readFileSync('../firestore.rules','utf8')}});
 await env.clearFirestore();
 await env.withSecurityRulesDisabled(async c=>{
 const db=c.firestore();
 for(const role of ['admin','farmer','customer']) await setDoc(doc(db,`users/${role}`),{name:role[0].toUpperCase()+role.slice(1),email:`${role}@test.local`,role,active:true,phone:'',address:'',createdAt:now()});
 await setDoc(doc(db,'farms/farmer'),{owner:'farmer',name:'Farm',pickupSlots:['11 AM - 1 PM'],location:'',market:'Market',description:'',image:'',active:true,createdAt:now()});
 await setDoc(doc(db,'categories/VmVn'),{name:'Vegetables',productCount:0,createdAt:now()});
 });
});
after(async()=>env?.cleanup());
const db=role=>env.authenticatedContext(role,{email:`${role}@test.local`}).firestore();
const product=()=>({name:'Carrot',farmId:'farmer',farmName:'Farm',category:'Vegetables',categoryId:'VmVn',price:250,stock:10,image:'',unit:'kg',description:'Fresh',archived:false,createdAt:now(),updatedAt:now()});
test('free-plan registration and roles',async()=>{
 const d=db('new');const p={name:'New',email:'new@test.local',role:'customer',phone:'',address:'',active:true,createdAt:now()};
 await assertFails(setDoc(doc(d,'users/new'),{...p,role:'admin'}));
 await assertSucceeds(setDoc(doc(d,'users/new'),p));
 await assertFails(updateDoc(doc(d,'users/new'),{role:'admin'}));
 await assertFails(getDoc(doc(d,'users/admin')));
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
 const b=writeBatch(f);
 b.set(doc(f,'products/carrot'),product());b.update(doc(f,'categories/VmVn'),{productCount:1,lastProductId:'carrot'});
 await assertSucceeds(b.commit());
 await assertFails(updateDoc(doc(db('customer'),'products/carrot'),{price:1,updatedAt:now()}));
 await assertFails(updateDoc(doc(f,'products/carrot'),{price:-1,updatedAt:now()}));
 await assertFails(updateDoc(doc(f,'categories/VmVn'),{productCount:99,lastProductId:'carrot'}));
});
async function purchase(id,{price=250,qty=2,stock=8}={}){
 const d=db('customer'), b=writeBatch(d);
 b.set(doc(d,`orders/${id}`),{customerId:'customer',customerName:'Customer',farmId:'farmer',farmerId:'farmer',farmName:'Farm',market:'Market',items:[{productId:'carrot',name:'Carrot',image:'',unit:'kg',price,quantity:qty}],total:price*qty,address:'Test address',status:'pending',createdAt:now()});
 b.update(doc(d,'products/carrot'),{stock,lastOrderId:id,updatedAt:now()});
 return b.commit();
}
test('checkout validates snapshots and commits stock with order atomically',async()=>{
 await assertFails(purchase('tampered',{price:1}));
 await assertFails(purchase('wrong-stock',{stock:9}));
 await assertSucceeds(purchase('valid'));
 await assertSucceeds(setDoc(doc(db('customer'),'users/customer/pickups/valid'),{slot:'11 AM - 1 PM',updatedAt:now()}));
 await assertFails(setDoc(doc(db('customer'),'users/customer/pickups/valid'),{slot:'Not published',updatedAt:now()}));
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

test('three-product checkout stays within rule transaction limits',async()=>{
 await env.withSecurityRulesDisabled(async c=>{
  const d=c.firestore();
  for(let i=1;i<=3;i++) {
   await setDoc(doc(d,`farms/f${i}`),{owner:`f${i}`,name:`Farm ${i}`,market:'Market',active:true});
   await setDoc(doc(d,`products/p${i}`),{...product(),farmId:`f${i}`,farmName:`Farm ${i}`});
  }
 });
 const d=db('customer'),b=writeBatch(d);
 for(let i=1;i<=3;i++) {
  b.set(doc(d,`orders/multi${i}`),{customerId:'customer',customerName:'Customer',farmId:`f${i}`,farmerId:`f${i}`,farmName:`Farm ${i}`,market:'Market',items:[{productId:`p${i}`,name:'Carrot',image:'',unit:'kg',price:250,quantity:2}],total:500,address:'Test',status:'pending',createdAt:now()});
  b.update(doc(d,`products/p${i}`),{stock:8,lastOrderId:`multi${i}`,updatedAt:now()});
 }
 b.set(doc(d,'checkoutRequests/customer_multi'),{userId:'customer',orderIds:['multi1','multi2','multi3'],createdAt:now()});
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
