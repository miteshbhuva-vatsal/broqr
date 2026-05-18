// Wipes ALL Firebase Auth users and their Firestore documents.
// Run from /admin: node scripts/wipe_users.mjs
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

// Load .env.local manually
const __dir = dirname(fileURLToPath(import.meta.url));
const envPath = resolve(__dir, '../.env.local');
const envLines = readFileSync(envPath, 'utf8').split('\n');
for (const line of envLines) {
  const idx = line.indexOf('=');
  if (idx === -1) continue;
  const key = line.slice(0, idx).trim();
  const val = line.slice(idx + 1).trim().replace(/^"([\s\S]*)"$/, '$1');
  process.env[key] = val;
}

import admin from 'firebase-admin';

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  }),
});

const auth = admin.auth();
const db = admin.firestore();

async function deleteAllAuthUsers() {
  let deleted = 0;
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    const uids = result.users.map(u => u.uid);
    if (uids.length > 0) {
      await auth.deleteUsers(uids);
      deleted += uids.length;
      console.log(`Deleted ${uids.length} auth users (total: ${deleted})`);
    }
    pageToken = result.pageToken;
  } while (pageToken);
  console.log(`Auth users deleted: ${deleted}`);
}

async function deleteCollection(collectionPath) {
  const snap = await db.collection(collectionPath).get();
  if (snap.empty) {
    console.log(`  ${collectionPath}: empty, skipping`);
    return;
  }
  const batch = db.batch();
  snap.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  console.log(`  Deleted ${snap.size} docs from ${collectionPath}`);
}

async function main() {
  console.log('=== Wiping all users and data ===');

  console.log('\n[1] Deleting Firebase Auth users...');
  await deleteAllAuthUsers();

  console.log('\n[2] Deleting Firestore collections...');
  const collections = [
    'users',
    'org_members',
    'org_invites',
    'organisations',
    'leads',
    'ask_posts',
  ];
  for (const col of collections) {
    await deleteCollection(col);
  }

  console.log('\n=== Done ===');
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
