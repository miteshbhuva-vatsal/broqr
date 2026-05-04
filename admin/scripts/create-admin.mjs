// Run once: node scripts/create-admin.mjs
// Creates (or promotes) a Firebase user to admin role.

import { initializeApp, cert } from 'firebase-admin/app'
import { getAuth } from 'firebase-admin/auth'
import { getFirestore } from 'firebase-admin/firestore'
import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

// Load .env.local manually
const __dir = dirname(fileURLToPath(import.meta.url))
const envPath = resolve(__dir, '../.env.local')
const envLines = readFileSync(envPath, 'utf8').split('\n')
for (const line of envLines) {
  const match = line.match(/^([^#=]+)=(.*)$/)
  if (match) process.env[match[1].trim()] = match[2].trim().replace(/^"|"$/g, '')
}

const ADMIN_EMAIL    = process.argv[2] || 'admin@cpapp.in'
const ADMIN_PASSWORD = process.argv[3] || 'Admin@1234'

const app = initializeApp({
  credential: cert({
    projectId:   process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey:  process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
})

const auth = getAuth(app)
const db   = getFirestore(app)

async function run() {
  let uid

  // Create or fetch the user
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL)
    uid = existing.uid
    console.log(`✓ Found existing user: ${ADMIN_EMAIL} (${uid})`)
  } catch {
    const created = await auth.createUser({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD, displayName: 'Admin' })
    uid = created.uid
    console.log(`✓ Created user: ${ADMIN_EMAIL} (${uid})`)
  }

  // Set Firestore document with role: admin
  await db.collection('users').doc(uid).set({
    uid,
    name:              'Admin',
    email:             ADMIN_EMAIL,
    role:              'admin',
    isVerified:        true,
    isProfileComplete: true,
    listingsCount:     0,
    connectionsCount:  0,
    createdAt:         new Date(),
  }, { merge: true })

  console.log(`✓ Firestore users/${uid} → role: admin`)
  console.log('')
  console.log('─────────────────────────────────────')
  console.log(`  URL:      http://localhost:3001`)
  console.log(`  Email:    ${ADMIN_EMAIL}`)
  console.log(`  Password: ${ADMIN_PASSWORD}`)
  console.log('─────────────────────────────────────')
  process.exit(0)
}

run().catch(err => { console.error('✗', err.message); process.exit(1) })
