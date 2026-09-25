const { test } = require('node:test');
const assert = require('node:assert/strict');
const { statuses, transition, summarize } = require('../domain');
test('only sequential progress or cancellation is permitted', () => {
  for (const from of statuses) for (const to of [...statuses, 'paid', '']) {
    const expected = ['pending','confirmed','ready'].includes(from) && (to === 'cancelled' || statuses.indexOf(to) === statuses.indexOf(from)+1);
    assert.equal(transition(from,to),expected,`${from} -> ${to}`);
  }
  assert.equal(transition('invalid','pending'),false);
});
test('reports preserve totals, date boundaries, farmer ranks and market snapshots', () => {
  const orders = [
    { createdAt:'2026-09-25T01:00:00Z',status:'completed',total:18000,farmId:'f1',farmName:'Farm 1',market:'Historical market' },
    { createdAt:'2026-09-25T02:00:00Z',status:'cancelled',total:10000,farmId:'f1',farmName:'Farm 1',market:'Historical market' },
    { createdAt:'2026-09-24T23:59:59Z',status:'pending',total:500,farmId:'f2',farmName:'Farm 2',market:'Other' },
  ];
  const result=summarize(orders,new Map(),{},1,new Date('2026-09-25T12:00:00Z'));
  assert.equal(result.totalOrders,2); assert.equal(result.orderValue,28000); assert.equal(result.completedValue,18000);
  assert.deepEqual(result.trend,[28000]); assert.equal(result.farmers[0].orders,2);
  assert.equal(result.markets[0].name,'Historical market'); assert.equal(result.markets[0].value,28000);
  assert.equal(result.statuses.cancelled,1);
});
test('empty database yields zeroes, never fabricated records',()=> {
  const r=summarize([],new Map(),{},7); assert.equal(r.totalOrders,0); assert.deepEqual(r.farmers,[]); assert.equal(r.trend.reduce((a,b)=>a+b,0),0);
});
