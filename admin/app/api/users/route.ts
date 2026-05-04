import { verifySession } from '@/lib/auth'
import { adminDb } from '@/lib/firebase-admin'
import { apiError } from '@/lib/utils'

export async function GET() {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const snap = await adminDb()
    .collection('users')
    .orderBy('createdAt', 'desc')
    .limit(500)
    .get()

  const users = snap.docs.map((d) => ({ uid: d.id, ...d.data() }))
  return Response.json({ users })
}
