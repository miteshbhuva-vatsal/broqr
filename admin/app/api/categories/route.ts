import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function GET() {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const snap = await adminDb().collection('categories').orderBy('sortOrder').get()
  const categories = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
  return Response.json({ categories })
}

export async function POST(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const body = await req.json()
  const ref  = adminDb().collection('categories').doc()
  await ref.set({ ...body, id: ref.id })
  return Response.json({ id: ref.id })
}
