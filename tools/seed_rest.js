/**
 * CPApp Firestore seed script — uses Firebase CLI OAuth token (no service account needed)
 * Usage: node seed_rest.js
 *
 * Requires: firebase CLI logged in (firebase login)
 * Project:  cpapp-ace05
 * Owner UID: C4YkwVWEjqbIZ0O810WSEKtbHvT2
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const PROJECT_ID = 'cpapp-ace05';
const OWNER_UID  = 'C4YkwVWEjqbIZ0O810WSEKtbHvT2';
const BASE_URL   = `firestore.googleapis.com`;
const DB_PATH    = `projects/${PROJECT_ID}/databases/(default)/documents`;

// ── Read access token from Firebase CLI config ────────────────────────────────
function getAccessToken() {
  const configPath = path.join(
    process.env.HOME,
    '.config/configstore/firebase-tools.json',
  );
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config?.tokens?.access_token;
  if (!token) throw new Error('No access token found. Run: firebase login');
  return token;
}

// ── REST helpers ──────────────────────────────────────────────────────────────

let ACCESS_TOKEN;

function apiRequest(method, urlPath, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: BASE_URL,
      path: `/v1/${urlPath}`,
      method,
      headers: {
        Authorization: `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let raw = '';
      res.on('data', (c) => (raw += c));
      res.on('end', () => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode}: ${raw.slice(0, 300)}`));
        } else {
          resolve(raw ? JSON.parse(raw) : {});
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// Convert a JS value to a Firestore Value proto
function v(val) {
  if (val === null || val === undefined)     return { nullValue: null };
  if (typeof val === 'boolean')              return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val))               return { integerValue: String(val) };
                                             return { doubleValue: val };
  }
  if (typeof val === 'string')               return { stringValue: val };
  if (val instanceof Date)                   return { timestampValue: val.toISOString() };
  if (Array.isArray(val))                    return { arrayValue: { values: val.map(v) } };
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, vv] of Object.entries(val)) {
      if (vv !== undefined) fields[k] = v(vv);
    }
    return { mapValue: { fields } };
  }
  return { nullValue: null };
}

// Build a Firestore document body from a plain JS object
function doc(obj) {
  const fields = {};
  for (const [k, val] of Object.entries(obj)) {
    if (val !== undefined) fields[k] = v(val);
  }
  return { fields };
}

async function setDoc(collection, docId, data) {
  const urlPath = `${DB_PATH}/${collection}/${docId}`;
  await apiRequest('PATCH', `${urlPath}`, doc(data));
}

async function setSubDoc(collection, docId, subCollection, subId, data) {
  const urlPath = `${DB_PATH}/${collection}/${docId}/${subCollection}/${subId}`;
  await apiRequest('PATCH', urlPath, doc(data));
}

// ── Seed data ─────────────────────────────────────────────────────────────────

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

const brokers = [
  { name: 'Rahul Sharma',    city: 'Mumbai',     mobile: '9876543210', rera: 'MH/RERA/A12345', verified: true  },
  { name: 'Priya Mehta',     city: 'Pune',       mobile: '9845123456', rera: null,              verified: true  },
  { name: 'Arjun Reddy',     city: 'Hyderabad',  mobile: '9912345678', rera: 'TS/RERA/B67890',  verified: true  },
  { name: 'Sneha Kapoor',    city: 'Delhi',      mobile: '9911234567', rera: null,              verified: true  },
  { name: 'Vikram Singh',    city: 'Bangalore',  mobile: '9900123456', rera: 'KA/RERA/C11111',  verified: true  },
  { name: 'Anita Joshi',     city: 'Chennai',    mobile: '9887654321', rera: null,              verified: false },
  { name: 'Ravi Patel',      city: 'Ahmedabad',  mobile: '9823456789', rera: 'GJ/RERA/D22222',  verified: false },
  { name: 'Kavya Nair',      city: 'Kochi',      mobile: '9847654321', rera: null,              verified: false },
  { name: 'Suresh Kumar',    city: 'Jaipur',     mobile: '9802345678', rera: 'RJ/RERA/E33333',  verified: false },
  { name: 'Deepika Gupta',   city: 'Kolkata',    mobile: '9733456789', rera: null,              verified: false },
  { name: 'Manish Agarwal',  city: 'Noida',      mobile: '9711234567', rera: 'UP/RERA/F44444',  verified: false },
  { name: 'Pooja Shah',      city: 'Surat',      mobile: '9712345678', rera: null,              verified: false },
  { name: 'Kiran Rao',       city: 'Gurgaon',    mobile: '9699876543', rera: 'HR/RERA/G55555',  verified: false },
  { name: 'Neeraj Verma',    city: 'Thane',      mobile: '9687654321', rera: null,              verified: false },
  { name: 'Sunita Pillai',   city: 'Nashik',     mobile: '9665432109', rera: 'MH/RERA/H66666',  verified: false },
  { name: 'Ajay Mishra',     city: 'Lucknow',    mobile: '9654321098', rera: null,              verified: false },
  { name: 'Neha Chavan',     city: 'Nagpur',     mobile: '9643210987', rera: 'MH/RERA/I77777',  verified: false },
  { name: 'Rohit Jain',      city: 'Indore',     mobile: '9632109876', rera: null,              verified: false },
  { name: 'Meera Krishnan',  city: 'Coimbatore', mobile: '9621098765', rera: 'TN/RERA/J88888',  verified: false },
  { name: 'Sanjay Tiwari',   city: 'Bhopal',     mobile: '9610987654', rera: null,              verified: false },
];

const listings = [
  { category: 'urgentSale', location: 'Andheri West',      city: 'Mumbai',     area: 750,  price: 9500000,  desc: '2BHK urgent sale due to relocation. Ready to move, fully furnished. No brokerage from buyer. Society approved.' },
  { category: 'barter',     location: 'Koregaon Park',     city: 'Pune',       area: 1200, price: 15000000, desc: 'Premium 3BHK open for barter against commercial property in Pune or Mumbai. Clear title. Motivated seller.' },
  { category: 'investor',   location: 'Whitefield',        city: 'Bangalore',  area: 950,  price: 8500000,  desc: 'Pre-launch investment. 18% appreciation in 24 months. RERA registered. Limited units available.' },
  { category: 'discount',   location: 'Banjara Hills',     city: 'Hyderabad',  area: 2200, price: 32000000, desc: '4BHK luxury flat at 15% below market. Developer distress sale. Modular kitchen, 2 car parks. Gated community.' },
  { category: 'rental',     location: 'Sector 62',         city: 'Noida',      area: 850,  price: 28000,    desc: 'Semi-furnished 2BHK for immediate possession. Preferred IT professionals. Gym & pool included.' },
  { category: 'commercial', location: 'Connaught Place',   city: 'Delhi',      area: 500,  price: 12000000, desc: 'Prime office space in CP. Ground floor corner unit. 24/7 access, power backup. Ideal for showroom or bank.' },
  { category: 'project',    location: 'Manikonda',         city: 'Hyderabad',  area: 1450, price: 12000000, desc: 'New launch 3BHK. Swimming pool, clubhouse, landscaped gardens. 5% booking amount. RERA approved.' },
  { category: 'urgentSale', location: 'Malad East',        city: 'Mumbai',     area: 550,  price: 6800000,  desc: '1BHK prime location. Owner in USA, 72-hr deal. Bank loan approved property. Possession immediate.' },
  { category: 'barter',     location: 'Hinjewadi Phase 2', city: 'Pune',       area: 1100, price: 9800000,  desc: 'IT corridor flat open for barter against plots in Pune periphery or Goa. Great rental yield.' },
  { category: 'investor',   location: 'Electronic City',   city: 'Bangalore',  area: 800,  price: 6500000,  desc: 'Under-construction 2BHK near Infosys campus. Possession Dec 2025. 10% assured returns for 2 years.' },
  { category: 'discount',   location: 'Powai',             city: 'Mumbai',     area: 1650, price: 28000000, desc: '3BHK with lake view at 12% discount. Developer clearing inventory. Bank pre-approved. OC received.' },
  { category: 'rental',     location: 'Baner',             city: 'Pune',       area: 1050, price: 35000,    desc: 'Fully furnished 3BHK for rent. All appliances included. 2 covered parking. Pet-friendly society.' },
  { category: 'commercial', location: 'Koramangala',       city: 'Bangalore',  area: 2000, price: 85000,    desc: 'Premium co-working space for 50 seats. Plug-and-play. High-speed internet, meeting rooms included.' },
  { category: 'project',    location: 'Thane West',        city: 'Thane',      area: 620,  price: 7200000,  desc: 'Affordable luxury 2BHK. Township with school, hospital within campus. 80% loan eligible.' },
  { category: 'urgentSale', location: 'Gachibowli',        city: 'Hyderabad',  area: 1800, price: 22000000, desc: '4BHK villa-style apartment. Owner shifting abroad in 30 days. Includes all furniture and appliances.' },
  { category: 'investor',   location: 'Dwarka Expressway', city: 'Gurgaon',    area: 1200, price: 11500000, desc: 'Emerging corridor. Metro connectivity confirmed. 500+ families moved in. Strong rental demand.' },
  { category: 'barter',     location: 'Vile Parle',        city: 'Mumbai',     area: 700,  price: 16500000, desc: '2BHK near airport. Open for barter with commercial property. Owner is builder with multiple assets.' },
  { category: 'discount',   location: 'Kharadi',           city: 'Pune',       area: 1350, price: 14500000, desc: 'Ready-to-move 3BHK with 20% discount. Builder liquidating last 5 units. EON IT Park walkable.' },
  { category: 'rental',     location: 'Indiranagar',       city: 'Bangalore',  area: 1100, price: 55000,    desc: 'Luxury 3BHK on 100 Feet Road. Fully furnished. Netflix, maintenance included. Available from 1st.' },
  { category: 'commercial', location: 'SG Highway',        city: 'Ahmedabad',  area: 1500, price: 40000,    desc: 'Grade-A office in Prahlad Nagar. CCTV, pantry, reception included. Ideal for MNC branch.' },
  { category: 'project',    location: 'Sarjapur Road',     city: 'Bangalore',  area: 1600, price: 18000000, desc: 'Ultra-luxury 3BHK with smart home features. AI-enabled security, EV charging. Launch price.' },
  { category: 'urgentSale', location: 'Chembur',           city: 'Mumbai',     area: 900,  price: 13500000, desc: 'Inherited property, quick sale. Court-cleared 3BHK. Stamp duty paid. Possession immediate on registration.' },
  { category: 'investor',   location: 'Rajarhat New Town', city: 'Kolkata',    area: 1000, price: 7500000,  desc: 'New Town township. IT hub. 12% rental yield. Bulk deal available for 5+ units. Developer direct.' },
  { category: 'barter',     location: 'Jubilee Hills',     city: 'Hyderabad',  area: 3500, price: 65000000, desc: 'Prestigious 5BHK open villa for barter with commercial in Hyderabad CBD or Bangalore.' },
  { category: 'discount',   location: 'Navi Mumbai',       city: 'Navi Mumbai', area: 650, price: 7800000,  desc: '1.5BHK at 18% below market. Developer going into new project needs capital. CIDCO scheme. Loan approved.' },
];

const heroImages = [
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
  'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800',
  'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
  'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800',
  'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
  'https://images.unsplash.com/photo-1576941089067-2de3c901e126?w=800',
  'https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=800',
];

const avatarPhotos = [
  'https://i.pravatar.cc/200?img=1',
  'https://i.pravatar.cc/200?img=2',
  'https://i.pravatar.cc/200?img=3',
  'https://i.pravatar.cc/200?img=4',
  'https://i.pravatar.cc/200?img=5',
  'https://i.pravatar.cc/200?img=6',
  'https://i.pravatar.cc/200?img=7',
  'https://i.pravatar.cc/200?img=8',
  'https://i.pravatar.cc/200?img=9',
  'https://i.pravatar.cc/200?img=10',
];

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {
  ACCESS_TOKEN = getAccessToken();
  console.log(`\n🌱  Seeding CPApp (project: ${PROJECT_ID})\n`);

  // ── 1. Broker profiles ────────────────────────────────────────────────────
  console.log('👤  Creating 20 broker profiles...');
  const brokerIds = [];

  for (let i = 0; i < brokers.length; i++) {
    const b = brokers[i];
    const id = uuidv4();
    brokerIds.push(id);

    await setDoc('users', id, {
      uid:               id,
      name:              b.name,
      email:             `${b.name.toLowerCase().replace(/\s+/g, '.')}@example.com`,
      photoUrl:          avatarPhotos[i % avatarPhotos.length],
      mobile:            b.mobile,
      city:              b.city,
      reraNumber:        b.rera,
      isProfileComplete: true,
      isVerified:        b.verified,
      listingsCount:     randInt(1, 8),
      connectionsCount:  randInt(5, 60),
      createdAt:         daysAgo(randInt(30, 180)),
    });
    process.stdout.write(`  ✓ ${b.name} (${b.city})\n`);
  }

  // ── 2. Listings ────────────────────────────────────────────────────────────
  console.log('\n🏠  Creating 25 listings...');
  const listingIds = [];

  for (let i = 0; i < listings.length; i++) {
    const t = listings[i];
    const brokerId = brokerIds[i % brokerIds.length];
    const broker   = brokers[i % brokers.length];
    const id       = uuidv4();
    listingIds.push(id);

    await setDoc('listings', id, {
      brokerUid:           brokerId,
      brokerName:          broker.name,
      brokerPhotoUrl:      avatarPhotos[i % avatarPhotos.length],
      brokerPhone:         broker.mobile,
      category:            t.category,
      city:                t.city,
      location:            t.location,
      area:                t.area,
      price:               t.price,
      description:         t.desc,
      heroImageUrl:        heroImages[i % heroImages.length],
      additionalImageUrls: [heroImages[(i + 1) % heroImages.length]],
      posterUrl:           null,
      status:              'active',
      likesCount:          randInt(0, 45),
      commentsCount:       randInt(0, 12),
      viewsCount:          randInt(10, 300),
      createdAt:           daysAgo(randInt(1, 60)),
    });
    process.stdout.write(`  ✓ [${t.category}] ${t.location}, ${t.city}\n`);
  }

  // ── 3. CRM leads for the owner ────────────────────────────────────────────
  console.log('\n📋  Creating 5 CRM leads...');
  const stages     = ['prospect', 'contacted', 'site_visit', 'negotiation', 'closed_won'];
  const priorities = ['high', 'medium', 'low'];
  const clients    = [
    { name: 'Amit Verma',   phone: '9812345678' },
    { name: 'Preeti Bose',  phone: '9734567890' },
    { name: 'Raj Malhotra', phone: '9645678901' },
    { name: 'Nisha Pillai', phone: '9556789012' },
    { name: 'Tarun Saxena', phone: '9467890123' },
  ];
  const estValues = [5000000, 8000000, 12000000, 20000000, 35000000];

  for (let i = 0; i < clients.length; i++) {
    const c  = clients[i];
    const id = uuidv4();
    const noteId = uuidv4();
    const createdAt = daysAgo(randInt(3, 45));
    const noteDate  = new Date(createdAt.getTime() + 3600000);

    await setDoc('leads', id, {
      ownerUid:          OWNER_UID,
      clientName:        c.name,
      clientPhone:       c.phone,
      stage:             stages[i],
      priority:          priorities[i % priorities.length],
      estimatedValue:    estValues[i],
      linkedListingId:   listingIds[i],
      linkedListingCity: listings[i].city,
      linkedListingPrice:`₹${(listings[i].price / 100000).toFixed(0)}L`,
      notes: [
        {
          id:        noteId,
          text:      `Initial call done. ${c.name} is interested in the property. Budget confirmed.`,
          createdAt: noteDate,
        },
      ],
      createdAt:  createdAt,
      updatedAt:  daysAgo(randInt(0, 5)),
    });
    process.stdout.write(`  ✓ ${c.name} → ${stages[i]}\n`);
  }

  // ── 4. Notifications for the owner ───────────────────────────────────────
  console.log('\n🔔  Creating 5 notifications...');
  const notifs = [
    { type: 'connection_request',  title: 'New Connection Request', body: `${brokers[0].name} wants to connect with you`,                   actorUid: brokerIds[0], targetId: null,        isRead: false, age: 0 },
    { type: 'connection_accepted', title: 'Connection Accepted',    body: `${brokers[1].name} accepted your connection request`,            actorUid: brokerIds[1], targetId: null,        isRead: false, age: 1 },
    { type: 'listing_inquiry',     title: 'New Inquiry',            body: `${brokers[2].name} inquired about your ${listings[0].location} listing`, actorUid: brokerIds[2], targetId: listingIds[0], isRead: true, age: 2 },
    { type: 'connection_request',  title: 'New Connection Request', body: `${brokers[3].name} wants to connect with you`,                   actorUid: brokerIds[3], targetId: null,        isRead: true, age: 3 },
    { type: 'general',             title: 'Welcome to CPApp!',      body: 'Start posting deals and growing your broker network today.',      actorUid: null,         targetId: null,        isRead: true, age: 5 },
  ];

  for (const n of notifs) {
    const id = uuidv4();
    await setSubDoc('notifications', OWNER_UID, 'items', id, {
      type:      n.type,
      title:     n.title,
      body:      n.body,
      actorUid:  n.actorUid,
      targetId:  n.targetId,
      isRead:    n.isRead,
      createdAt: daysAgo(n.age),
    });
    process.stdout.write(`  ✓ ${n.title}\n`);
  }

  // ── 5. Sample connections ─────────────────────────────────────────────────
  console.log('\n🤝  Creating 3 connections...');

  for (let i = 0; i < 2; i++) {
    const otherId = brokerIds[i];
    const sorted  = [OWNER_UID, otherId].sort();
    await setDoc('connections', `${sorted[0]}_${sorted[1]}`, {
      senderId:    OWNER_UID,
      participants:[OWNER_UID, otherId],
      status:      'connected',
      createdAt:   daysAgo(randInt(5, 20)),
    });
    process.stdout.write(`  ✓ Connected: ${brokers[i].name}\n`);
  }

  const pendingOther  = brokerIds[2];
  const sortedP       = [OWNER_UID, pendingOther].sort();
  await setDoc('connections', `${sortedP[0]}_${sortedP[1]}`, {
    senderId:    pendingOther,
    participants:[OWNER_UID, pendingOther],
    status:      'pending',
    createdAt:   daysAgo(1),
  });
  process.stdout.write(`  ✓ Pending request from ${brokers[2].name}\n`);

  console.log('\n✅  Done!\n');
  console.log('  • 20 broker profiles');
  console.log('  • 25 listings (all 7 categories)');
  console.log('  • 5 CRM leads');
  console.log('  • 5 notifications');
  console.log('  • 3 connections (2 connected, 1 pending)\n');
}

seed().catch((err) => {
  console.error('\n❌ Seed failed:', err.message);
  if (err.message.includes('401') || err.message.includes('403')) {
    console.error('   Token may be expired. Run: firebase login --reauth');
  }
  process.exit(1);
});
