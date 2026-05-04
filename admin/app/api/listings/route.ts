import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function GET(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const status = req.nextUrl.searchParams.get('status')
  const db = adminDb()

  let query = db.collection('listings').orderBy('createdAt', 'desc').limit(500)
  if (status) query = query.where('status', '==', status) as typeof query

  const snap = await query.get()
  const listings = snap.docs.map((d) => ({ id: d.id, ...d.data() }))

  return Response.json({ listings })
}
