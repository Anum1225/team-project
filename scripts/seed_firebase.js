const apiKey = 'AIzaSyChJHpQMVHz5fyX20nwyGb7i-IVZvE_1vE';
const projectId = 'harvesthub-80047';
const baseUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

async function getAdminToken() {
  const authRes = await fetch('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + apiKey, {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email: 'admin@harvesthub.com', password: 'Admin1234!', returnSecureToken: true})
  });
  const data = await authRes.json();
  if (!data.idToken) throw new Error('Failed to get admin token: ' + JSON.stringify(data));
  return data.idToken;
}

async function setDoc(token, collection, docId, fields) {
  const url = `${baseUrl}/${collection}/${docId}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': 'Bearer ' + token,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ fields })
  });
  const json = await res.json();
  if (json.error) {
    console.error(`Error saving ${collection}/${docId}:`, json.error.message);
  } else {
    console.log(`Saved ${collection}/${docId}`);
  }
}

async function main() {
  const token = await getAdminToken();
  console.log('Authenticated as Admin');

  const now = new Date().toISOString();

  // 1. Users
  await setDoc(token, 'users', 'G9B1eBkINKXuTgwK3QGWv36lP8C2', {
    name: { stringValue: 'Sarah Jenkins' },
    email: { stringValue: 'customer@harvesthub.com' },
    role: { stringValue: 'customer' },
    phone: { stringValue: '0331 7274333' },
    address: { stringValue: 'Apartment 4B, Sunflower Valley, Karachi' },
    active: { booleanValue: true },
    createdAt: { timestampValue: now }
  });

  await setDoc(token, 'users', 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2', {
    name: { stringValue: 'Marcus Rivera' },
    email: { stringValue: 'farmer@harvesthub.com' },
    role: { stringValue: 'farmer' },
    phone: { stringValue: '0300 7654321' },
    address: { stringValue: 'Stall #14 • Greenwood Market' },
    active: { booleanValue: true },
    createdAt: { timestampValue: now }
  });

  // 2. Categories
  const categories = [
    { name: 'Vegetables', id: 'dmVnZXRhYmxlcw', count: 3 },
    { name: 'Fruits', id: 'ZnJ1aXRz', count: 2 },
    { name: 'Dairy', id: 'ZGFpcnk', count: 2 },
    { name: 'Grains', id: 'Z3JhaW5z', count: 1 },
    { name: 'Herbs', id: 'aGVyYnM', count: 2 },
    { name: 'Organic', id: 'b3JnYW5pYw', count: 1 },
    { name: 'Pulses', id: 'cHVsc2Vz', count: 1 },
    { name: 'Pantry', id: 'cGFudHJ5', count: 1 },
  ];

  for (const cat of categories) {
    await setDoc(token, 'categories', cat.id, {
      name: { stringValue: cat.name },
      productCount: { integerValue: String(cat.count) },
      createdAt: { timestampValue: now },
      updatedAt: { timestampValue: now }
    });
  }

  // 3. Farms
  const farms = [
    {
      id: 'green',
      name: 'Greenwood Organic Farm',
      owner: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      location: 'Stall #14 • Greenwood Market',
      market: 'Greenwood Farmers Market',
      description: 'Marcus Rivera · 8 yrs regenerative certified. Growing vine-ripened heirloom beefsteaks and fresh baby greens.',
      image: 'farmer_marcus'
    },
    {
      id: 'sun',
      name: 'Sunny Brook Farm',
      owner: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      location: '2.1 mi away · Greenwood Market',
      market: 'Greenwood Farmers Market',
      description: 'Certified organic vegetables, crisp greens and heritage berries harvested fresh daily.',
      image: 'farmer_sunny'
    },
    {
      id: 'highland',
      name: 'Highland Orchards',
      owner: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      location: '3.8 mi away · Hillside',
      market: 'Hillside Farmers Market',
      description: 'Fresh crisp Honeycrisp apples, Asian pears, and orchard cider.',
      image: 'farm'
    },
    {
      id: 'golden',
      name: 'Golden Hen Homestead',
      owner: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      location: '1.4 mi away · Valley Pastures',
      market: 'Valley Farmers Market',
      description: 'Pasture-raised farm eggs from happy, roaming hens.',
      image: 'eggs'
    },
    {
      id: 'willow',
      name: 'Willow Creek Farms',
      owner: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      location: '2.9 mi away · Riverside',
      market: 'Riverside Farmers Market',
      description: 'Naturally grown seasonal root vegetables and stone fruits.',
      image: 'farm'
    }
  ];

  for (const f of farms) {
    await setDoc(token, 'farms', f.id, {
      name: { stringValue: f.name },
      owner: { stringValue: f.owner },
      location: { stringValue: f.location },
      market: { stringValue: f.market },
      description: { stringValue: f.description },
      image: { stringValue: f.image },
      active: { booleanValue: true },
      createdAt: { timestampValue: now },
      updatedAt: { timestampValue: now }
    });
  }

  // 4. Products
  const products = [
    {
      id: 'p1',
      name: 'Vine-Ripened Heirloom Tomatoes',
      category: 'Vegetables',
      categoryId: 'dmVnZXRhYmxlcw',
      farmId: 'green',
      farmName: 'Greenwood Organic Farm',
      price: 180,
      stock: 45,
      unit: 'kg',
      image: 'tomatoes',
      description: 'Vine-ripened heirloom beefsteaks with rich umami flavor. Picked fresh this morning.'
    },
    {
      id: 'p2',
      name: 'Crisp Gala Apples',
      category: 'Fruits',
      categoryId: 'ZnJ1aXRz',
      farmId: 'highland',
      farmName: 'Highland Orchards',
      price: 240,
      stock: 60,
      unit: 'kg',
      image: 'apples',
      description: 'Crunchy, sweet Gala apples grown without synthetic pesticides.'
    },
    {
      id: 'p3',
      name: 'Organic Baby Spinach',
      category: 'Vegetables',
      categoryId: 'dmVnZXRhYmxlcw',
      farmId: 'green',
      farmName: 'Greenwood Organic Farm',
      price: 120,
      stock: 28,
      unit: 'bunch',
      image: 'spinach',
      description: 'Tender, vitamin-packed baby spinach leaves washed and bunched fresh.'
    },
    {
      id: 'p4',
      name: 'Fresh Farm Raw Milk',
      category: 'Dairy',
      categoryId: 'ZGFpcnk',
      farmId: 'golden',
      farmName: 'Golden Hen Homestead',
      price: 220,
      stock: 35,
      unit: 'L',
      image: 'milk',
      description: '100% pure, unpasteurized A2 whole milk from grass-fed dairy cows.'
    },
    {
      id: 'p5',
      name: 'Pasture-Raised Brown Eggs',
      category: 'Dairy',
      categoryId: 'ZGFpcnk',
      farmId: 'golden',
      farmName: 'Golden Hen Homestead',
      price: 340,
      stock: 50,
      unit: 'dozen',
      image: 'eggs',
      description: 'Golden-yolk eggs from free-ranging hens enjoying sunshine and clover.'
    },
    {
      id: 'p6',
      name: 'Sweet Golden Corn',
      category: 'Vegetables',
      categoryId: 'dmVnZXRhYmxlcw',
      farmId: 'sun',
      farmName: 'Sunny Brook Farm',
      price: 150,
      stock: 40,
      unit: 'kg',
      image: 'corn',
      description: 'Naturally sweet bicolored corn, tender kernels bursting with flavor.'
    },
    {
      id: 'p7',
      name: 'Fresh Italian Basil',
      category: 'Herbs',
      categoryId: 'aGVyYnM',
      farmId: 'green',
      farmName: 'Greenwood Organic Farm',
      price: 80,
      stock: 22,
      unit: 'bunch',
      image: 'basil',
      description: 'Aromatic Genovese basil leaves, perfect for fresh pesto and caprese salads.'
    },
    {
      id: 'p8',
      name: 'Organic Hass Avocados',
      category: 'Fruits',
      categoryId: 'ZnJ1aXRz',
      farmId: 'highland',
      farmName: 'Highland Orchards',
      price: 320,
      stock: 30,
      unit: 'kg',
      image: 'avocados',
      description: 'Creamy Hass avocados with rich nutty flavor, packed with healthy fats.'
    },
    {
      id: 'p9',
      name: 'Pure Raw Wildflower Honey',
      category: 'Pantry',
      categoryId: 'cGFudHJ5',
      farmId: 'sun',
      farmName: 'Sunny Brook Farm',
      price: 850,
      stock: 18,
      unit: 'jar',
      image: 'honey',
      description: 'Cold-extracted unpasteurized honey from wild meadows and citrus blooms.'
    },
    {
      id: 'p10',
      name: 'Organic Red Lentils',
      category: 'Pulses',
      categoryId: 'cHVsc2Vz',
      farmId: 'sun',
      farmName: 'Sunny Brook Farm',
      price: 210,
      stock: 55,
      unit: 'kg',
      image: 'lentils',
      description: 'High-protein split red lentils, fast-cooking and hearty for soups.'
    },
    {
      id: 'p11',
      name: 'Whole Grain Heritage Wheat',
      category: 'Grains',
      categoryId: 'Z3JhaW5z',
      farmId: 'sun',
      farmName: 'Sunny Brook Farm',
      price: 160,
      stock: 70,
      unit: 'kg',
      image: 'wheat',
      description: 'Stone-ground heritage whole wheat flour, rich in natural fiber and germ.'
    },
    {
      id: 'p12',
      name: 'Fresh Mountain Mint',
      category: 'Herbs',
      categoryId: 'aGVyYnM',
      farmId: 'green',
      farmName: 'Greenwood Organic Farm',
      price: 70,
      stock: 25,
      unit: 'bunch',
      image: 'mint',
      description: 'Crisp, fragrant spearmint sprigs for teas, lemonades, and marinades.'
    }
  ];

  for (const p of products) {
    await setDoc(token, 'products', p.id, {
      name: { stringValue: p.name },
      category: { stringValue: p.category },
      categoryId: { stringValue: p.categoryId },
      farmId: { stringValue: p.farmId },
      farmName: { stringValue: p.farmName },
      price: { integerValue: String(p.price) },
      stock: { integerValue: String(p.stock) },
      unit: { stringValue: p.unit },
      image: { stringValue: p.image },
      description: { stringValue: p.description },
      archived: { booleanValue: false },
      createdAt: { timestampValue: now },
      updatedAt: { timestampValue: now }
    });
  }

  // 5. Orders
  const customerId = 'G9B1eBkINKXuTgwK3QGWv36lP8C2';
  const customerName = 'Sarah Jenkins';

  const orders = [
    {
      id: 'ORD-7001',
      farmId: 'green',
      farmerId: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      farmName: 'Greenwood Organic Farm',
      market: 'Greenwood Farmers Market',
      status: 'pending',
      address: 'Apartment 4B, Sunflower Valley, Karachi',
      items: [
        { productId: 'p1', name: 'Vine-Ripened Heirloom Tomatoes', image: 'tomatoes', unit: 'kg', price: 180, quantity: 2 },
        { productId: 'p3', name: 'Organic Baby Spinach', image: 'spinach', unit: 'bunch', price: 120, quantity: 1 }
      ],
      total: 480
    },
    {
      id: 'ORD-7002',
      farmId: 'golden',
      farmerId: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      farmName: 'Golden Hen Homestead',
      market: 'Valley Farmers Market',
      status: 'confirmed',
      address: 'Apartment 4B, Sunflower Valley, Karachi',
      items: [
        { productId: 'p4', name: 'Fresh Farm Raw Milk', image: 'milk', unit: 'L', price: 220, quantity: 2 },
        { productId: 'p5', name: 'Pasture-Raised Brown Eggs', image: 'eggs', unit: 'dozen', price: 340, quantity: 1 }
      ],
      total: 780
    },
    {
      id: 'ORD-7003',
      farmId: 'highland',
      farmerId: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      farmName: 'Highland Orchards',
      market: 'Hillside Farmers Market',
      status: 'ready',
      address: 'Apartment 4B, Sunflower Valley, Karachi',
      items: [
        { productId: 'p2', name: 'Crisp Gala Apples', image: 'apples', unit: 'kg', price: 240, quantity: 3 },
        { productId: 'p8', name: 'Organic Hass Avocados', image: 'avocados', unit: 'kg', price: 320, quantity: 1 }
      ],
      total: 1040
    },
    {
      id: 'ORD-7004',
      farmId: 'sun',
      farmerId: 'xRTnTF4Yo7fcpPuDtLZtVFUiTUZ2',
      farmName: 'Sunny Brook Farm',
      market: 'Greenwood Farmers Market',
      status: 'completed',
      address: 'Apartment 4B, Sunflower Valley, Karachi',
      items: [
        { productId: 'p9', name: 'Pure Raw Wildflower Honey', image: 'honey', unit: 'jar', price: 850, quantity: 1 },
        { productId: 'p6', name: 'Sweet Golden Corn', image: 'corn', unit: 'kg', price: 150, quantity: 2 }
      ],
      total: 1150
    }
  ];

  for (const o of orders) {
    await setDoc(token, 'orders', o.id, {
      customerId: { stringValue: customerId },
      customerName: { stringValue: customerName },
      farmId: { stringValue: o.farmId },
      farmerId: { stringValue: o.farmerId },
      farmName: { stringValue: o.farmName },
      market: { stringValue: o.market },
      status: { stringValue: o.status },
      address: { stringValue: o.address },
      total: { integerValue: String(o.total) },
      createdAt: { timestampValue: now },
      updatedAt: { timestampValue: now },
      items: {
        arrayValue: {
          values: o.items.map(i => ({
            mapValue: {
              fields: {
                productId: { stringValue: i.productId },
                name: { stringValue: i.name },
                image: { stringValue: i.image },
                unit: { stringValue: i.unit },
                price: { integerValue: String(i.price) },
                quantity: { integerValue: String(i.quantity) }
              }
            }
          }))
        }
      }
    });
  }

  // 6. Markets
  const markets = [
    {
      id: 'm1',
      name: 'Greenwood Farmers Market',
      address: '123 Orchard Way, North Valley',
      gps: '24.8607° N, 67.0011° E',
      hours: 'Wed-Sun, 7:00 AM - 2:00 PM',
      active: true
    },
    {
      id: 'm2',
      name: 'Hillside Fresh Market',
      address: '88 Ridge Parkway, Hillside',
      gps: '24.9123° N, 67.0892° E',
      hours: 'Sat-Sun, 8:00 AM - 4:00 PM',
      active: true
    },
    {
      id: 'm3',
      name: 'Valley Organic Bazaar',
      address: '45 River Bend Road, Valley',
      gps: '24.8210° N, 67.0345° E',
      hours: 'Daily, 6:30 AM - 1:00 PM',
      active: true
    }
  ];

  for (const m of markets) {
    await setDoc(token, 'farmersMarkets', m.id, {
      marketName: { stringValue: m.name },
      address: { stringValue: m.address },
      gpsCoordinates: { stringValue: m.gps },
      operatingHours: { stringValue: m.hours },
      activeStatus: { booleanValue: m.active },
      createdAt: { timestampValue: now }
    });
  }

  console.log('Seeding completed successfully!');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
