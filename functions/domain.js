'use strict';
const statuses = ['pending', 'confirmed', 'ready', 'completed', 'cancelled'];
function transition(from, to) {
  return statuses.includes(from) && statuses.includes(to) &&
    !['completed', 'cancelled'].includes(from) &&
    (to === 'cancelled' || statuses.indexOf(to) === statuses.indexOf(from) + 1);
}
function summarize(orders, farms, counts, days, now = new Date()) {
  const start = new Date(now); start.setUTCHours(0, 0, 0, 0); start.setUTCDate(start.getUTCDate() - days + 1);
  const result = { ...counts, totalOrders: 0, orderValue: 0, completedValue: 0,
    statuses: Object.fromEntries(statuses.map(s => [s, 0])), farmers: [], markets: [], trend: Array(days).fill(0) };
  const byFarm = new Map(); const byMarket = new Map();
  for (const order of orders) {
    const date = order.createdAt?.toDate ? order.createdAt.toDate() : new Date(order.createdAt);
    if (!Number.isFinite(date.getTime()) || date < start || date > now) continue;
    result.totalOrders++; result.orderValue += order.total;
    result.statuses[order.status]++;
    if (order.status === 'completed') result.completedValue += order.total;
    const day = Math.floor((date - start) / 86400000);
    result.trend[day] += order.total;
    const f = byFarm.get(order.farmId) || { id: order.farmId, name: order.farmName, orders: 0, completed: 0, value: 0 };
    f.orders++; f.value += order.total; if (order.status === 'completed') f.completed++;
    byFarm.set(order.farmId, f);
    // Historical market snapshot; legacy records fall back to the current farm.
    const market = order.market || farms.get(order.farmId)?.market || 'Unassigned market';
    const m = byMarket.get(market) || { name: market, orders: 0, completed: 0, value: 0 };
    m.orders++; m.value += order.total; if (order.status === 'completed') m.completed++;
    byMarket.set(market, m);
  }
  result.farmers = [...byFarm.values()].sort((a,b) => b.orders-a.orders || a.id.localeCompare(b.id));
  result.markets = [...byMarket.values()].sort((a,b) => a.name.localeCompare(b.name));
  return result;
}
module.exports = { statuses, transition, summarize };
