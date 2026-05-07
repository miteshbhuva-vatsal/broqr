import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

const LISTING_LIST_FIELDS = [
  'brokerUid', 'brokerName', 'brokerPhone', 'brokerPhotoUrl',
  'category', 'propertyType', 'location', 'city',
  'price', 'originalPrice', 'area', 'areaUnit',
  'status', 'heroImageUrl', 'createdAt', 'viewsCount', 'likesCount',
]

export async function GET(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const { searchParams } = req.nextUrl
  const limitParam = Math.min(parseInt(searchParams.get('limit') ?? '100', 10), 500)
  const cursor     = searchParams.get('cursor')
  const status     = searchParams.get('status')
  const city       = searchParams.get('city')
  const category   = searchParams.get('category')

  try {
    const db = adminDb()
    let query = db.collection('listings')
      .select(...LISTING_LIST_FIELDS)
      .orderBy('createdAt', 'desc')
      .limit(limitParam + 1)

    if (status)   query = query.where('status', '==', status) as typeof query
    if (city)     query = query.where('city', '==', city) as typeof query
    if (category) query = query.where('category', '==', category) as typeof query

    if (cursor) {
      const cursorDoc = await db.collection('listings').doc(cursor).get()
      if (cursorDoc.exists) query = query.startAfter(cursorDoc) as typeof query
    }

    const snap = await query.get()
    const docs     = snap.docs.slice(0, limitParam)
    const listings = docs.map((d) => ({ id: d.id, ...d.data() }))
    const nextCursor = snap.docs.length > limitParam ? docs[docs.length - 1].id : null

    return Response.json({ listings, nextCursor, total: listings.length })
  } catch (err) {
    console.error('[listings GET]', err)
    return apiError('Failed to fetch listings', 500)
  }
}
