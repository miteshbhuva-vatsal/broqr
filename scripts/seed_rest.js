// node scripts/seed_rest.js
// Seeds Firestore via REST API (no admin credentials needed).
// Uses anonymous Auth to get a valid ID token.

const https = require('https');

const PROJECT_ID = 'cpapp-ace05';
const API_KEY    = 'AIzaSyCs1uz_dfod3gh0I9m2hpUVcxUhOIBV6XQ';

function post(hostname, path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = https.request(
      { hostname, path, method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(data) } },
      res => {
        let raw = '';
        res.on('data', c => raw += c);
        res.on('end', () => {
          const json = JSON.parse(raw);
          if (res.statusCode >= 400) reject(new Error(`${res.statusCode}: ${JSON.stringify(json)}`));
          else resolve(json);
        });
      }
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function patchDoc(token, docPath, fields) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ fields });
    const path = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
    const req = https.request(
      { hostname: 'firestore.googleapis.com', path, method: 'PATCH',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body),
                   'Authorization': `Bearer ${token}` } },
      res => {
        let raw = '';
        res.on('data', c => raw += c);
        res.on('end', () => {
          const json = JSON.parse(raw);
          if (res.statusCode >= 400) reject(new Error(`${res.statusCode}: ${JSON.stringify(json)}`));
          else resolve(json);
        });
      }
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function strV(v)  { return { stringValue: String(v) }; }
function intV(v)  { return { integerValue: String(Math.round(v)) }; }
function tsV(ms)  { return { timestampValue: new Date(ms).toISOString() }; }
function nullV()  { return { nullValue: null }; }
function arrV(a)  { return { arrayValue: { values: a } }; }

const now = Date.now();
const h = ms => now - ms * 3600000;
const d = ms => now - ms * 86400000;

const listings = [
  // ── Mumbai ────────────────────────────────────────────────────────────────
  {
    id: 'v2-1', posterRole: 'broker',
    brokerName: 'Rajesh Sharma', brokerPhone: '+91 98765 43210',
    category: 'sale', propertyType: 'bhk2',
    city: 'Mumbai', location: 'Andheri West',
    area: 850, price: 9500000, brokerageAmount: '2%',
    description: 'Spacious 2 BHK in prime Andheri West. Ready to move. 24/7 security, parking included.',
    heroImageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    likesCount: 12, commentsCount: 3, viewsCount: 45, createdAt: h(2),
  },
  {
    id: 'v2-8', posterRole: 'builder',
    brokerName: 'Rohit Singh', brokerPhone: '+91 21098 76543',
    category: 'sale', propertyType: 'penthouse',
    city: 'Mumbai', location: 'Lower Parel',
    area: 4500, price: 75000000, brokerageAmount: '1%',
    description: 'Sky-high penthouse with panoramic sea view. Private terrace, jacuzzi, smart home automation.',
    heroImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
    likesCount: 43, commentsCount: 12, viewsCount: 210, createdAt: h(4),
  },
  {
    id: 'v2-9', posterRole: 'owner',
    brokerName: 'Nisha Desai', brokerPhone: '+91 91234 56789',
    category: 'rent', propertyType: 'bhk1',
    city: 'Mumbai', location: 'Malad West',
    area: 460, price: 28000, brokerageAmount: null,
    description: '1 BHK fully furnished. Near Malad station. No deposit. Available immediately.',
    heroImageUrl: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
    likesCount: 7, commentsCount: 0, viewsCount: 22, createdAt: h(1),
  },
  // ── Pune ──────────────────────────────────────────────────────────────────
  {
    id: 'v2-2', posterRole: 'investor',
    brokerName: 'Priya Mehta', brokerPhone: '+91 87654 32109',
    category: 'rent', propertyType: 'bhk3',
    city: 'Pune', location: 'Baner',
    area: 1400, price: 45000, brokerageAmount: '₹25,000',
    description: '3 BHK semi-furnished flat. Gym, swimming pool, covered parking.',
    heroImageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    likesCount: 8, commentsCount: 1, viewsCount: 30, createdAt: h(5),
  },
  {
    id: 'v2-10', posterRole: 'broker',
    brokerName: 'Suresh Kulkarni', brokerPhone: '+91 88001 23456',
    category: 'sale', propertyType: 'bhk4',
    city: 'Pune', location: 'Koregaon Park',
    area: 2100, price: 18500000, brokerageAmount: '1.5%',
    description: 'Premium 4 BHK with terrace. Gated community, club house, EV charging. Near top schools.',
    heroImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
    likesCount: 18, commentsCount: 4, viewsCount: 74, createdAt: h(6),
  },
  // ── Bangalore ─────────────────────────────────────────────────────────────
  {
    id: 'v2-4', posterRole: 'builder',
    brokerName: 'Sneha Joshi', brokerPhone: '+91 65432 10987',
    category: 'sale', propertyType: 'villa',
    city: 'Bangalore', location: 'Whitefield',
    area: 3200, price: 28000000, brokerageAmount: '1.5%',
    description: 'Luxurious independent villa with private pool. 4 bedrooms, home theatre, modular kitchen.',
    heroImageUrl: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800',
    likesCount: 24, commentsCount: 7, viewsCount: 110, createdAt: h(3),
  },
  {
    id: 'v2-11', posterRole: 'investor',
    brokerName: 'Anand Rao', brokerPhone: '+91 99887 65432',
    category: 'sale', propertyType: 'plot',
    city: 'Bangalore', location: 'Sarjapur Road',
    area: 1800, price: 9800000, brokerageAmount: null,
    description: 'Residential plot in fast-developing Sarjapur. BMRDA approved. Loan facility available.',
    heroImageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
    likesCount: 11, commentsCount: 2, viewsCount: 41, createdAt: d(1),
  },
  // ── Hyderabad ─────────────────────────────────────────────────────────────
  {
    id: 'v2-5', posterRole: 'broker',
    brokerName: 'Karan Verma', brokerPhone: '+91 54321 09876',
    category: 'rent', propertyType: 'studio',
    city: 'Hyderabad', location: 'Hitech City',
    area: 480, price: 22000, brokerageAmount: '1 month rent',
    description: 'Modern studio fully furnished. Walking distance to tech park. Ideal for IT professionals.',
    heroImageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
    likesCount: 15, commentsCount: 2, viewsCount: 62, createdAt: h(0.5),
  },
  {
    id: 'v2-12', posterRole: 'owner',
    brokerName: 'Lavanya Reddy', brokerPhone: '+91 77889 00112',
    category: 'rent', propertyType: 'bhk2',
    city: 'Hyderabad', location: 'Gachibowli',
    area: 1050, price: 32000, brokerageAmount: '₹10,000',
    description: '2 BHK in tech corridor. Air-conditioned, power backup, gym, parking. Pet friendly.',
    heroImageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800',
    likesCount: 14, commentsCount: 3, viewsCount: 58, createdAt: h(8),
  },
  // ── Delhi ─────────────────────────────────────────────────────────────────
  {
    id: 'v2-7', posterRole: 'owner',
    brokerName: 'Meera Kapoor', brokerPhone: '+91 32109 87654',
    category: 'sale', propertyType: 'bhk1',
    city: 'Delhi', location: 'Dwarka Sector 12',
    area: 520, price: 5800000, brokerageAmount: '₹50,000',
    description: 'Cozy 1 BHK in well-maintained society. Metro connectivity. Suitable for first-time buyers.',
    heroImageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800',
    likesCount: 9, commentsCount: 1, viewsCount: 38, createdAt: h(7),
  },
  {
    id: 'v2-13', posterRole: 'builder',
    brokerName: 'Pankaj Sharma', brokerPhone: '+91 98112 33445',
    category: 'sale', propertyType: 'bhk3',
    city: 'Delhi', location: 'Rohini Sector 9',
    area: 1350, price: 13500000, brokerageAmount: '2%',
    description: 'New construction 3 BHK. Modular kitchen, vitrified flooring, lift. OC received. Home loan tie-up.',
    heroImageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    likesCount: 20, commentsCount: 5, viewsCount: 88, createdAt: h(10),
  },
  // ── Ahmedabad ─────────────────────────────────────────────────────────────
  {
    id: 'v2-3', posterRole: 'owner',
    brokerName: 'Amit Patel', brokerPhone: '+91 76543 21098',
    category: 'sale', propertyType: 'plot',
    city: 'Ahmedabad', location: 'SG Highway',
    area: 2400, price: 7200000, brokerageAmount: null,
    description: 'Corner plot in gated township. All amenities nearby. Clear title. Immediate registration.',
    heroImageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
    likesCount: 5, commentsCount: 0, viewsCount: 18, createdAt: d(1),
  },
  // ── Chennai ───────────────────────────────────────────────────────────────
  {
    id: 'v2-6', posterRole: 'investor',
    brokerName: 'Deepak Nair', brokerPhone: '+91 43210 98765',
    category: 'barter', propertyType: 'shopOffice',
    city: 'Chennai', location: 'Anna Nagar',
    area: 600, price: 12000000, brokerageAmount: null,
    description: 'Commercial space in high-footfall area. Ground floor. Great for retail or office. Open for barter.',
    heroImageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
    likesCount: 6, commentsCount: 0, viewsCount: 27, createdAt: d(2),
  },
  {
    id: 'v2-14', posterRole: 'broker',
    brokerName: 'Tamil Selvi', brokerPhone: '+91 94456 78901',
    category: 'rent', propertyType: 'shopOffice',
    city: 'Chennai', location: 'T Nagar',
    area: 800, price: 75000, brokerageAmount: '2 months rent',
    description: 'Prime retail space in T Nagar shopping district. Ground floor with high footfall. Immediate occupation.',
    heroImageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
    likesCount: 9, commentsCount: 2, viewsCount: 34, createdAt: h(12),
  },
  // ── Jaipur ────────────────────────────────────────────────────────────────
  {
    id: 'v2-15', posterRole: 'builder',
    brokerName: 'Vikram Singh', brokerPhone: '+91 98001 23456',
    category: 'sale', propertyType: 'villa',
    city: 'Jaipur', location: 'Vaishali Nagar',
    area: 2800, price: 14500000, brokerageAmount: '1%',
    description: 'Heritage-inspired villa in premium township. 3 BHK + servant room, Rajasthani architecture. Gated.',
    heroImageUrl: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=800',
    likesCount: 16, commentsCount: 3, viewsCount: 67, createdAt: h(14),
  },
  // ── Surat ─────────────────────────────────────────────────────────────────
  {
    id: 'v2-16', posterRole: 'investor',
    brokerName: 'Hitesh Shah', brokerPhone: '+91 95559 12345',
    category: 'sale', propertyType: 'bhk2',
    city: 'Surat', location: 'Vesu',
    area: 920, price: 6500000, brokerageAmount: '₹40,000',
    description: '2 BHK in upcoming smart city zone. RERA registered. 5-year builder warranty. Return guarantee.',
    heroImageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    likesCount: 10, commentsCount: 1, viewsCount: 43, createdAt: d(3),
  },
];

function toFields(l, uid) {
  return {
    id:              strV(l.id),
    brokerUid:       strV(uid),
    brokerName:      strV(l.brokerName),
    brokerPhotoUrl:  nullV(),
    brokerPhone:     strV(l.brokerPhone),
    posterRole:      strV(l.posterRole),
    category:        strV(l.category),
    propertyType:    strV(l.propertyType),
    city:            strV(l.city),
    location:        strV(l.location),
    area:            intV(l.area),
    price:           intV(l.price),
    brokerageAmount: l.brokerageAmount ? strV(l.brokerageAmount) : nullV(),
    description:     strV(l.description),
    heroImageUrl:    strV(l.heroImageUrl),
    additionalImageUrls: arrV([]),
    posterUrl:       nullV(),
    status:          strV('active'),
    likesCount:      intV(l.likesCount),
    commentsCount:   intV(l.commentsCount),
    viewsCount:      intV(l.viewsCount),
    createdAt:       tsV(l.createdAt),
    updatedAt:       tsV(now),
  };
}

async function seed() {
  console.log('Signing in anonymously…');
  const authRes = await post(
    'identitytoolkit.googleapis.com',
    `/v1/accounts:signUp?key=${API_KEY}`,
    { returnSecureToken: true },
  );
  const token  = authRes.idToken;
  const uid    = authRes.localId;
  console.log(`Got token (uid: ${uid}). Writing ${listings.length} listings…\n`);

  for (const l of listings) {
    await patchDoc(token, `listings/${l.id}`, toFields(l, uid));
    const brok = l.brokerageAmount ? `brokerage: ${l.brokerageAmount}` : 'no brokerage';
    console.log(`  ✓ [${l.posterRole.padEnd(8)}] ${l.propertyType.padEnd(12)} ${l.city.padEnd(12)} ${l.location}  (${brok})`);
  }
  console.log(`\n✅  ${listings.length} listings seeded successfully!`);
}

seed().catch(e => { console.error('SEED ERROR:', e.message); process.exit(1); });
