/**
 * CPApp Firestore seed script
 * Usage: node seed_data.js <YOUR_UID> <path/to/serviceAccountKey.json>
 *
 * Get serviceAccountKey.json from:
 *   Firebase Console → Project Settings → Service accounts → Generate new private key
 */

const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

const [,, ownerUid, keyPath] = process.argv;

if (!ownerUid || !keyPath) {
  console.error('Usage: node seed_data.js <YOUR_UID> <path/to/serviceAccountKey.json>');
  process.exit(1);
}

const serviceAccount = require(require('path').resolve(keyPath));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

// ── Helpers ───────────────────────────────────────────────────────────────────

const uid = () => uuidv4();

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return Timestamp.fromDate(d);
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// ── Seed data ─────────────────────────────────────────────────────────────────

const cities = [
  'Mumbai', 'Pune', 'Bangalore', 'Hyderabad', 'Delhi',
  'Chennai', 'Ahmedabad', 'Surat', 'Jaipur', 'Kolkata',
  'Noida', 'Gurgaon', 'Navi Mumbai', 'Thane', 'Nashik',
];

const brokers = [
  { name: 'Rahul Sharma',    city: 'Mumbai',    mobile: '9876543210', rera: 'MH/RERA/A12345' },
  { name: 'Priya Mehta',     city: 'Pune',      mobile: '9845123456', rera: null },
  { name: 'Arjun Reddy',     city: 'Hyderabad', mobile: '9912345678', rera: 'TS/RERA/B67890' },
  { name: 'Sneha Kapoor',    city: 'Delhi',     mobile: '9911234567', rera: null },
  { name: 'Vikram Singh',    city: 'Bangalore', mobile: '9900123456', rera: 'KA/RERA/C11111' },
  { name: 'Anita Joshi',     city: 'Chennai',   mobile: '9887654321', rera: null },
  { name: 'Ravi Patel',      city: 'Ahmedabad', mobile: '9823456789', rera: 'GJ/RERA/D22222' },
  { name: 'Kavya Nair',      city: 'Kochi',     mobile: '9847654321', rera: null },
  { name: 'Suresh Kumar',    city: 'Jaipur',    mobile: '9802345678', rera: 'RJ/RERA/E33333' },
  { name: 'Deepika Gupta',   city: 'Kolkata',   mobile: '9733456789', rera: null },
  { name: 'Manish Agarwal',  city: 'Noida',     mobile: '9711234567', rera: 'UP/RERA/F44444' },
  { name: 'Pooja Shah',      city: 'Surat',     mobile: '9712345678', rera: null },
  { name: 'Kiran Rao',       city: 'Gurgaon',   mobile: '9699876543', rera: 'HR/RERA/G55555' },
  { name: 'Neeraj Verma',    city: 'Thane',     mobile: '9687654321', rera: null },
  { name: 'Sunita Pillai',   city: 'Nashik',    mobile: '9665432109', rera: 'MH/RERA/H66666' },
  { name: 'Ajay Mishra',     city: 'Lucknow',   mobile: '9654321098', rera: null },
  { name: 'Neha Chavan',     city: 'Nagpur',    mobile: '9643210987', rera: 'MH/RERA/I77777' },
  { name: 'Rohit Jain',      city: 'Indore',    mobile: '9632109876', rera: null },
  { name: 'Meera Krishnan',  city: 'Coimbatore',mobile: '9621098765', rera: 'TN/RERA/J88888' },
  { name: 'Sanjay Tiwari',   city: 'Bhopal',    mobile: '9610987654', rera: null },
];

const listingTemplates = [
  {
    category: 'urgentSale',
    location: 'Andheri West',
    city: 'Mumbai',
    area: 750,
    price: 9500000,
    description: '2BHK urgent sale due to relocation. Ready to move, fully furnished. No brokerage from buyer side. Society approved.',
  },
  {
    category: 'barter',
    location: 'Koregaon Park',
    city: 'Pune',
    area: 1200,
    price: 15000000,
    description: 'Premium 3BHK open for barter against commercial property in Pune or Mumbai. Clear title. Motivated seller.',
  },
  {
    category: 'investor',
    location: 'Whitefield',
    city: 'Bangalore',
    area: 950,
    price: 8500000,
    description: 'Pre-launch investment opportunity. Expected 18% appreciation in 24 months. RERA registered project. Limited units.',
  },
  {
    category: 'discount',
    location: 'Banjara Hills',
    city: 'Hyderabad',
    area: 2200,
    price: 32000000,
    description: '4BHK luxury flat at 15% below market. Developer distress sale. Modular kitchen, 2 car parks. Gated community.',
  },
  {
    category: 'rental',
    location: 'Sector 62',
    city: 'Noida',
    area: 850,
    price: 28000,
    description: 'Semi-furnished 2BHK available for immediate possession. Preferred IT professionals. 11-month lease. Gym & pool.',
  },
  {
    category: 'commercial',
    location: 'Connaught Place',
    city: 'Delhi',
    area: 500,
    price: 12000000,
    description: 'Prime office space in CP. Ground floor corner unit. 24/7 access, power backup. Ideal for bank or showroom.',
  },
  {
    category: 'project',
    location: 'Manikonda',
    city: 'Hyderabad',
    area: 1450,
    price: 12000000,
    description: 'New launch 3BHK with world-class amenities. Swimming pool, clubhouse, landscaped gardens. 5% booking amount.',
  },
  {
    category: 'urgentSale',
    location: 'Malad East',
    city: 'Mumbai',
    area: 550,
    price: 6800000,
    description: '1BHK in prime location. 72 hours deal. Owner in USA, needs quick liquidation. Bank loan approved property.',
  },
  {
    category: 'barter',
    location: 'Hinjewadi Phase 2',
    city: 'Pune',
    area: 1100,
    price: 9800000,
    description: 'IT corridor flat open for barter against plots in Pune periphery or Goa. Great rental yield potential.',
  },
  {
    category: 'investor',
    location: 'Electronic City',
    city: 'Bangalore',
    area: 800,
    price: 6500000,
    description: 'Under-construction 2BHK near Infosys campus. Possession Dec 2025. 10% assured returns for 2 years. RERA approved.',
  },
  {
    category: 'discount',
    location: 'Powai',
    city: 'Mumbai',
    area: 1650,
    price: 28000000,
    description: '3BHK with lake view at 12% discount. Developer clearing inventory. Bank pre-approved. OC received last month.',
  },
  {
    category: 'rental',
    location: 'Baner',
    city: 'Pune',
    area: 1050,
    price: 35000,
    description: 'Fully furnished 3BHK for rent. All appliances included. 2 covered parking. Pet-friendly society. Metro nearby.',
  },
  {
    category: 'commercial',
    location: 'Koramangala',
    city: 'Bangalore',
    area: 2000,
    price: 85000,
    description: 'Premium co-working space for lease. Plug-and-play setup for 50 seats. High-speed internet, meeting rooms included.',
  },
  {
    category: 'project',
    location: 'Thane West',
    city: 'Thane',
    area: 620,
    price: 7200000,
    description: 'Affordable luxury 2BHK. Township project with school, hospital within campus. 80% loan eligible. Booking open.',
  },
  {
    category: 'urgentSale',
    location: 'Gachibowli',
    city: 'Hyderabad',
    area: 1800,
    price: 22000000,
    description: '4BHK villa-style apartment. Owner shifting abroad in 30 days. Negotiable. Includes all furniture and appliances.',
  },
  {
    category: 'investor',
    location: 'Dwarka Expressway',
    city: 'Gurgaon',
    area: 1200,
    price: 11500000,
    description: 'Emerging corridor investment. Metro connectivity confirmed. 500+ families already moved in. Strong rental demand.',
  },
  {
    category: 'barter',
    location: 'Vile Parle',
    city: 'Mumbai',
    area: 700,
    price: 16500000,
    description: '2BHK near airport. Open for barter with commercial property. Owner is builder with multiple properties.',
  },
  {
    category: 'discount',
    location: 'Kharadi',
    city: 'Pune',
    area: 1350,
    price: 14500000,
    description: 'Ready-to-move 3BHK with 20% discount. Builder liquidating last 5 units. EON IT Park walkable distance.',
  },
  {
    category: 'rental',
    location: 'Indiranagar',
    city: 'Bangalore',
    area: 1100,
    price: 55000,
    description: 'Luxury 3BHK on 100 Feet Road. Fully furnished, Netflix, maintenance included. Available from 1st next month.',
  },
  {
    category: 'commercial',
    location: 'SG Highway',
    city: 'Ahmedabad',
    area: 1500,
    price: 40000,
    description: 'Grade-A office space in Prahlad Nagar. CCTV, pantry, reception included. Ideal for MNC branch office.',
  },
  {
    category: 'project',
    location: 'Sarjapur Road',
    city: 'Bangalore',
    area: 1600,
    price: 18000000,
    description: 'Ultra-luxury 3BHK with smart home features. AI-enabled security, EV charging. Launch price for first 20 buyers.',
  },
  {
    category: 'urgentSale',
    location: 'Chembur',
    city: 'Mumbai',
    area: 900,
    price: 13500000,
    description: 'Inherited property, quick sale needed. Court-cleared, 3BHK. Stamp duty paid. Possession immediate on registration.',
  },
  {
    category: 'investor',
    location: 'Rajarhat New Town',
    city: 'Kolkata',
    area: 1000,
    price: 7500000,
    description: 'New Town township. IT hub location. 12% rental yield. Bulk deal available for 5+ units. Developer direct.',
  },
  {
    category: 'barter',
    location: 'Jubilee Hills',
    city: 'Hyderabad',
    area: 3500,
    price: 65000000,
    description: 'Prestigious 5BHK open villa open for barter with commercial property in Hyderabad CBD or Bangalore.',
  },
  {
    category: 'discount',
    location: 'Navi Mumbai',
    city: 'Navi Mumbai',
    area: 650,
    price: 7800000,
    description: '1.5BHK at 18% below market. Developer going into new project needs capital. CIDCO scheme. Loan approved.',
  },
];

// Picsum photos for property images (will actually render)
const heroImages = [
  'https://picsum.photos/seed/apt1/800/500',
  'https://picsum.photos/seed/apt2/800/500',
  'https://picsum.photos/seed/apt3/800/500',
  'https://picsum.photos/seed/apt4/800/500',
  'https://picsum.photos/seed/apt5/800/500',
  'https://picsum.photos/seed/house1/800/500',
  'https://picsum.photos/seed/house2/800/500',
  'https://picsum.photos/seed/office1/800/500',
  'https://picsum.photos/seed/office2/800/500',
  'https://picsum.photos/seed/villa1/800/500',
];

// Avatar photos for broker profiles
const avatarPhotos = [
  'https://picsum.photos/seed/broker1/200/200',
  'https://picsum.photos/seed/broker2/200/200',
  'https://picsum.photos/seed/broker3/200/200',
  'https://picsum.photos/seed/broker4/200/200',
  'https://picsum.photos/seed/broker5/200/200',
  'https://picsum.photos/seed/broker6/200/200',
  'https://picsum.photos/seed/broker7/200/200',
  'https://picsum.photos/seed/broker8/200/200',
  'https://picsum.photos/seed/broker9/200/200',
  'https://picsum.photos/seed/broker10/200/200',
];

// ── Main seeding function ─────────────────────────────────────────────────────

async function seed() {
  console.log(`\n🌱  Seeding CPApp Firestore for project: ${serviceAccount.project_id}\n`);

  // ── 1. Create 20 broker user profiles ──────────────────────────────────────
  console.log('👤  Creating broker profiles...');
  const brokerIds = [];

  for (let i = 0; i < brokers.length; i++) {
    const b = brokers[i];
    const id = uid();
    brokerIds.push(id);
    const createdAt = daysAgo(randInt(30, 180));

    await db.collection('users').doc(id).set({
      uid: id,
      name: b.name,
      email: `${b.name.toLowerCase().replace(/\s+/g, '.')}@example.com`,
      photoUrl: avatarPhotos[i % avatarPhotos.length],
      mobile: b.mobile,
      city: b.city,
      reraNumber: b.rera,
      isProfileComplete: true,
      isVerified: i < 5,           // first 5 are verified
      listingsCount: randInt(1, 8),
      connectionsCount: randInt(5, 60),
      createdAt,
      updatedAt: FieldValue.serverTimestamp(),
    });
    process.stdout.write(`  ✓ ${b.name}\n`);
  }

  // ── 2. Create 25 listings ──────────────────────────────────────────────────
  console.log('\n🏠  Creating listings...');
  const listingIds = [];

  for (let i = 0; i < listingTemplates.length; i++) {
    const t = listingTemplates[i];
    const brokerId = brokerIds[i % brokerIds.length];
    const broker = brokers[i % brokers.length];
    const id = uid();
    listingIds.push(id);
    const createdAt = daysAgo(randInt(1, 60));

    await db.collection('listings').doc(id).set({
      brokerUid: brokerId,
      brokerName: broker.name,
      brokerPhotoUrl: avatarPhotos[i % avatarPhotos.length],
      brokerPhone: broker.mobile,
      category: t.category,
      city: t.city,
      location: t.location,
      area: t.area,
      price: t.price,
      description: t.description,
      heroImageUrl: heroImages[i % heroImages.length],
      additionalImageUrls: [
        heroImages[(i + 1) % heroImages.length],
        heroImages[(i + 2) % heroImages.length],
      ],
      posterUrl: null,
      status: 'active',
      likesCount: randInt(0, 45),
      commentsCount: randInt(0, 12),
      viewsCount: randInt(10, 300),
      createdAt,
      updatedAt: FieldValue.serverTimestamp(),
    });
    process.stdout.write(`  ✓ [${t.category}] ${t.location}, ${t.city}\n`);
  }

  // ── 3. Create 5 leads for the owner ───────────────────────────────────────
  console.log('\n📋  Creating CRM leads...');
  const stages = ['prospect', 'contacted', 'site_visit', 'negotiation', 'closed_won'];
  const priorities = ['high', 'medium', 'low'];
  const clients = [
    { name: 'Amit Verma',   phone: '9812345678' },
    { name: 'Preeti Bose',  phone: '9734567890' },
    { name: 'Raj Malhotra', phone: '9645678901' },
    { name: 'Nisha Pillai', phone: '9556789012' },
    { name: 'Tarun Saxena', phone: '9467890123' },
  ];

  for (let i = 0; i < clients.length; i++) {
    const c = clients[i];
    const id = uid();
    const now = new Date();
    const createdAt = daysAgo(randInt(3, 45));

    await db.collection('leads').doc(id).set({
      ownerUid: ownerUid,
      clientName: c.name,
      clientPhone: c.phone,
      stage: stages[i],
      priority: priorities[i % priorities.length],
      estimatedValue: pick([5000000, 8000000, 12000000, 20000000, 35000000]),
      linkedListingId: listingIds[i],
      linkedListingCity: listingTemplates[i].city,
      linkedListingPrice: `₹${(listingTemplates[i].price / 100000).toFixed(0)}L`,
      notes: [
        {
          id: uid(),
          text: `Initial call done. ${c.name} is interested in 3BHK. Budget confirmed.`,
          createdAt: Timestamp.fromDate(new Date(createdAt.toDate().getTime() + 3600000)),
        },
      ],
      createdAt,
      updatedAt: FieldValue.serverTimestamp(),
    });
    process.stdout.write(`  ✓ ${c.name} (${stages[i]})\n`);
  }

  // ── 4. Create notifications for the owner ─────────────────────────────────
  console.log('\n🔔  Creating notifications...');
  const notifTemplates = [
    {
      type: 'connection_request',
      title: 'New Connection Request',
      body: `${brokers[0].name} wants to connect with you`,
      actorUid: brokerIds[0],
      isRead: false,
    },
    {
      type: 'connection_accepted',
      title: 'Connection Accepted',
      body: `${brokers[1].name} accepted your connection request`,
      actorUid: brokerIds[1],
      isRead: false,
    },
    {
      type: 'listing_inquiry',
      title: 'New Inquiry on Your Listing',
      body: `${brokers[2].name} inquired about your ${listingTemplates[0].location} listing`,
      actorUid: brokerIds[2],
      targetId: listingIds[0],
      isRead: true,
    },
    {
      type: 'connection_request',
      title: 'New Connection Request',
      body: `${brokers[3].name} wants to connect with you`,
      actorUid: brokerIds[3],
      isRead: true,
    },
    {
      type: 'general',
      title: 'Welcome to CPApp!',
      body: 'Start posting deals and growing your broker network today.',
      actorUid: null,
      isRead: true,
    },
  ];

  for (let i = 0; i < notifTemplates.length; i++) {
    const n = notifTemplates[i];
    const id = uid();
    await db
      .collection('notifications')
      .doc(ownerUid)
      .collection('items')
      .doc(id)
      .set({
        type: n.type,
        title: n.title,
        body: n.body,
        actorUid: n.actorUid ?? null,
        targetId: n.targetId ?? null,
        isRead: n.isRead,
        createdAt: daysAgo(i),
      });
    process.stdout.write(`  ✓ ${n.title}\n`);
  }

  // ── 5. Create a couple of connections between the owner and seeded brokers ─
  console.log('\n🤝  Creating sample connections...');
  for (let i = 0; i < 2; i++) {
    const otherId = brokerIds[i];
    const sorted = [ownerUid, otherId].sort();
    const connectionId = `${sorted[0]}_${sorted[1]}`;
    await db.collection('connections').doc(connectionId).set({
      senderId: ownerUid,
      participants: [ownerUid, otherId],
      status: 'connected',
      createdAt: daysAgo(randInt(5, 20)),
    });
    process.stdout.write(`  ✓ Connected with ${brokers[i].name}\n`);
  }
  // One pending request
  const pendingId = brokerIds[2];
  const sortedP = [ownerUid, pendingId].sort();
  await db.collection('connections').doc(`${sortedP[0]}_${sortedP[1]}`).set({
    senderId: pendingId,
    participants: [ownerUid, pendingId],
    status: 'pending',
    createdAt: daysAgo(1),
  });
  console.log(`  ✓ Pending request from ${brokers[2].name}`);

  console.log('\n✅  Seed complete!\n');
  console.log('Summary:');
  console.log(`  • ${brokers.length} broker profiles`);
  console.log(`  • ${listingTemplates.length} listings (all categories)`);
  console.log(`  • 5 CRM leads for uid: ${ownerUid}`);
  console.log(`  • 5 notifications for uid: ${ownerUid}`);
  console.log(`  • 3 connections (2 accepted, 1 pending)\n`);

  process.exit(0);
}

seed().catch(err => {
  console.error('\n❌ Seed failed:', err.message);
  process.exit(1);
});
