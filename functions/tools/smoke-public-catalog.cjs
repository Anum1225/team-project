// Read-only production check. Prints counts only, never customer records/tokens.
const assert = require('node:assert/strict');
const url = 'https://script.google.com/macros/s/AKfycbzrVxOkY9A-HQHLRCSSUdPxepUHUp-yy4H619oIe-gWZaGNXWoBxfRTvvq2L57gVi2I/exec';
const allowed = {
  products: ['id','name','category','farmId','price','stock','image','unit','description'],
  farms: ['id','name','location','market','description','image','pickupSlots','lat','lng'],
  categories: ['id','name'],
  markets: ['id','name','location','hours','lat','lng'],
};
async function call(action, data = {}) {
  const response = await fetch(url, {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({action, data}), signal: AbortSignal.timeout(60000),
  });
  assert.equal(response.status, 200);
  return response.json();
}
(async () => {
  const totals = Object.fromEntries(Object.keys(allowed).map(k => [k, 0]));
  const records = Object.fromEntries(Object.keys(allowed).map(k => [k, new Set()]));
  let cursors = {}, pages = 0;
  do {
    const result = await call('publicCatalog', {cursors});
    assert.ok(!result.error, 'Catalog returned an application error: ' + result.error?.code);
    for (const [key, fields] of Object.entries(allowed)) {
      assert.ok(Array.isArray(result.data[key]));
      for (const row of result.data[key]) {
        assert.ok(Object.keys(row).every(field => fields.includes(field)), 'Unexpected public field');
        assert.ok(!records[key].has(row.id), 'Duplicate catalog page');
        records[key].add(row.id);
      }
      totals[key] += result.data[key].length;
    }
    cursors = result.data.cursors;
    assert.ok(++pages <= 100);
  } while (Object.values(cursors).some(v => v !== null));
  assert.ok(totals.products > 0 && totals.farms > 0, 'Expected the existing live catalog');
  const protectedResult = await call('verifyEmailCode');
  assert.equal(protectedResult.error?.code, 'unauthenticated');
  console.log(JSON.stringify({publicCatalog: 'passed', pages, counts: totals, protectedActions: 'require authentication'}));
})().catch(error => { console.error(error.message, error.cause?.code || ''); process.exitCode = 1; });
