import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

// Fields needed for the admin users table — avoids fetching heavy blobs
const USER_LIST_FIELDS = [
  'name', 'email', 'mobile', 'city', 'role',
  'isVerified', 'isBanned', 'createdAt', 'lastSeen',
  'connectionsCount', 'listingsCount', 'photoUrl',
]

export async function GET(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const { searchParams } = req.nextUrl
  const limitParam = Math.min(parseInt(searchParams.get('limit') ?? '100', 10), 500)
  const cursor     = searchParams.get('cursor')
  const role       = searchParams.get('role')
  const verified   = searchParams.get('isVerified')
  const banned     = searchParams.get('isBanned')

  try {
    const db = adminDb()
    let query = db.collection('users')
      .select(...USER_LIST_FIELDS)
      .orderBy('createdAt', 'desc')
      .limit(limitParam + 1) // +1 to detect next page

    if (role)     query = query.where('role', '==', role) as typeof query
    if (verified) query = query.where('isVerified', '==', verified === 'true') as typeof query
    if (banned)   query = query.where('isBanned', '==', banned === 'true') as typeof query

    if (cursor) {
      const cursorDoc = await db.collection('users').doc(cursor).get()
      if (cursorDoc.exists) query = query.startAfter(cursorDoc) as typeof query
    }

    const snap = await query.get()
    const docs  = snap.docs.slice(0, limitParam)
    const users = docs.map((d) => ({ uid: d.id, ...d.data() }))
    const nextCursor = snap.docs.length > limitParam ? docs[docs.length - 1].id : null

    return Response.json({ users, nextCursor, total: users.length })
  } catch (err) {
    console.error('[users GET]', err)
    return apiError('Failed to fetch users', 500)
  }
}
