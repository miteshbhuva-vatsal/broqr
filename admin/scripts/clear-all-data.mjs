/**
 * Wipes ALL Firestore data + Firebase Storage + Firebase Auth users.
 * Run: node admin/scripts/clear-all-data.mjs
 */
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const env = {};
readFileSync(join(__dirname, '..', '.env.local'), 'utf8').split('\n').forEach(line => {
  const [k, ...v] = line.split('=');
  if (k && v.length) env[k.trim()] = v.join('=').trim().replace(/^"|"$/g, '').replace(/\\n/g, '\n');
});

initializeApp({
  credential: cert({
    projectId: env.FIREBASE_PROJECT_ID,
    clientEmail: env.FIREBASE_CLIENT_EMAIL,
    privateKey: env.FIREBASE_PRIVATE_KEY,
  }),
  storageBucket: `${env.FIREBASE_PROJECT_ID}.firebasestorage.app`,
});

const db = getFirestore();
const storage = getStorage().bucket();
const auth = getAuth();

// ── Helpers ───────────────────────────────────────────────────────────────────

async function deleteCollection(path, batchSize = 400) {
  const ref = db.collection(path);
  let total = 0;
  let snap;
  do {
    snap = await ref.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
  } while (snap.size >= batchSize);
  console.log(`  ✓ Firestore /${path}: ${total} docs deleted`);
}

async function deleteAllSubcollections(parentPath, subName, batchSize = 400) {
  const snap = await db.collection(parentPath).get();
  let total = 0;
  for (const doc of snap.docs) {
    let sub;
    do {
      sub = await doc.ref.collection(subName).limit(batchSize).get();
      if (sub.empty) break;
      const batch = db.batch();
      sub.docs.forEach(d => batch.delete(d.ref));
      await batch.commit();
      total += sub.size;
    } while (sub.size >= batchSize);
  }
  if (total) console.log(`  ✓ Firestore /${parentPath}/*/${subName}: ${total} docs deleted`);
}

async function deleteStorageFolder(prefix) {
  try {
    const [files] = await storage.getFiles({ prefix });
    if (!files.length) { console.log(`  ✓ Storage /${prefix}: empty`); return; }
    await Promise.all(files.map(f => f.delete().catch(() => {})));
    console.log(`  ✓ Storage /${prefix}: ${files.length} files deleted`);
  } catch (e) {
    console.log(`  ⚠ Storage /${prefix}: ${e.message}`);
  }
}

async function deleteAllAuthUsers() {
  let total = 0;
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    const uids = result.users.map(u => u.uid);
    if (uids.length) {
      await auth.deleteUsers(uids);
      total += uids.length;
    }
    pageToken = result.pageToken;
  } while (pageToken);
  console.log(`  ✓ Firebase Auth: ${total} users deleted`);
}

// ── Run ───────────────────────────────────────────────────────────────────────

console.log(`\n🗑  Full wipe — project: ${env.FIREBASE_PROJECT_ID}`);
console.log('─'.repeat(55));

console.log('\n1️⃣  Firestore — all collections');
await deleteCollection('listings');
await deleteCollection('posts');
await deleteCollection('leads');
await deleteCollection('connections');
await deleteCollection('connection_requests');
await deleteCollection('appEvents');
await deleteAllSubcollections('chats', 'messages');
await deleteCollection('chats');
await deleteAllSubcollections('users', 'notifications');
await deleteAllSubcollections('users', 'likes');
await deleteAllSubcollections('users', 'views');
await deleteCollection('users');
await deleteCollection('organisations');
await deleteCollection('org_members');
await deleteCollection('org_teams');
await deleteCollection('org_invites');
await deleteCollection('notifications');

console.log('\n2️⃣  Firebase Storage — all media');
await deleteStorageFolder('profile_images/');
await deleteStorageFolder('listing_images/');
await deleteStorageFolder('posters/');

console.log('\n3️⃣  Firebase Auth — all accounts');
await deleteAllAuthUsers();

console.log('\n' + '─'.repeat(55));
console.log('✅  Complete wipe done. App is fully clean.\n');
