import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function GET(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const type = req.nextUrl.searchParams.get('type')
  const db   = adminDb()

  if (type === 'templates') {
    const [snap, configDoc] = await Promise.all([
      db.collection('whatsappTemplates').orderBy('trigger').get(),
      db.collection('config').doc('whatsapp').get(),
    ])
    return Response.json({
      templates: snap.docs.map((d) => ({ id: d.id, ...d.data() })),
      endpoint: configDoc.data()?.endpoint ?? '',
    })
  }

  return apiError('Missing type param', 400)
}

export async function POST(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const body = await req.json()
  const db   = adminDb()

  if (body.type === 'config') {
    const update: Record<string, string> = { endpoint: body.endpoint }
    if (body.token) update.token = body.token
    await db.collection('config').doc('whatsapp').set(update, { merge: true })
    return Response.json({ ok: true })
  }

  if (body.type === 'template') {
    const ref = db.collection('whatsappTemplates').doc()
    await ref.set({ id: ref.id, name: body.name, body: body.body, trigger: body.trigger, isActive: body.isActive })
    return Response.json({ id: ref.id })
  }

  return apiError('Unknown type', 400)
}
