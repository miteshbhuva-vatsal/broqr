import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function POST(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const { phone, templateId, vars } = await req.json()
  if (!phone || !templateId) return apiError('Missing phone or templateId', 400)

  const db = adminDb()
  const [templateDoc, configDoc] = await Promise.all([
    db.collection('whatsappTemplates').doc(templateId).get(),
    db.collection('config').doc('whatsapp').get(),
  ])

  if (!templateDoc.exists) return apiError('Template not found', 404)
  if (!configDoc.exists)   return apiError('WhatsApp not configured', 500)

  const { endpoint, token } = configDoc.data()!
  if (!endpoint || !token)  return apiError('WATI endpoint or token missing', 500)

  const template = templateDoc.data()!
  let variables: Record<string, string> = {}
  try { variables = vars ? JSON.parse(vars) : {} } catch { /* ignore */ }

  const messageText = (template.body as string).replace(
    /\{\{(\w+)\}\}/g,
    (_: string, k: string) => variables[k] ?? `{{${k}}}`,
  )

  const res = await fetch(`${endpoint}/api/v1/sendSessionMessage/${phone}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ messageText }),
  })

  if (!res.ok) {
    const err = await res.text()
    return apiError(`WATI error: ${err}`, 502)
  }

  return Response.json({ ok: true })
}
