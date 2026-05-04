import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { FieldValue } from 'firebase-admin/firestore'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!await verifySession()) return apiError('Unauthorized', 401)
  const { id } = await params
  const body = await req.json()
  const allowed: Record<string, unknown> = {}

  if (body.isVerified !== undefined) allowed.isVerified = body.isVerified
  if (body.isBanned   !== undefined) allowed.isBanned   = body.isBanned
  if (body.role       !== undefined) allowed.role       = body.role

  allowed.updatedAt = FieldValue.serverTimestamp()

  await adminDb().collection('users').doc(id).update(allowed)
  return Response.json({ ok: true })
}
