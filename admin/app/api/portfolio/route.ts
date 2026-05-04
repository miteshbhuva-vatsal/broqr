import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const uid = req.nextUrl.searchParams.get('uid')
  if (!uid) return Response.json({ error: 'Missing uid' }, { status: 400 })

  const db = adminDb()
  const [userDoc, listingsSnap] = await Promise.all([
    db.collection('users').doc(uid).get(),
    db.collection('listings')
      .where('brokerUid', '==', uid)
      .where('status', '==', 'active')
      .orderBy('createdAt', 'desc')
      .get(),
  ])

  if (!userDoc.exists) return Response.json({ error: 'User not found' }, { status: 404 })

  const user = { uid, ...userDoc.data() }
  const listings = listingsSnap.docs.map((d) => ({ id: d.id, ...d.data() }))

  return Response.json({ user, listings })
}
