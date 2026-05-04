import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!await verifySession()) return apiError('Unauthorized', 401)
  const { id } = await params
  const body = await req.json()
  const { type: _type, ...rest } = body
  await adminDb().collection('whatsappTemplates').doc(id).update(rest)
  return Response.json({ ok: true })
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!await verifySession()) return apiError('Unauthorized', 401)
  const { id } = await params
  await adminDb().collection('whatsappTemplates').doc(id).delete()
  return Response.json({ ok: true })
}
