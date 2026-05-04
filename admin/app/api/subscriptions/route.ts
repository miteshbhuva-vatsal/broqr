import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function GET(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const type = req.nextUrl.searchParams.get('type')
  const db   = adminDb()

  if (type === 'subscribers') {
    const snap = await db.collection('userSubscriptions').orderBy('startDate', 'desc').limit(300).get()
    return Response.json({ subscriptions: snap.docs.map((d) => ({ id: d.id, ...d.data() })) })
  }

  const snap = await db.collection('subscriptionPlans').orderBy('sortOrder').get()
  return Response.json({ plans: snap.docs.map((d) => ({ id: d.id, ...d.data() })) })
}

export async function POST(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const body = await req.json()
  const ref  = adminDb().collection('subscriptionPlans').doc()
  await ref.set({ ...body, id: ref.id })
  return Response.json({ id: ref.id })
}
