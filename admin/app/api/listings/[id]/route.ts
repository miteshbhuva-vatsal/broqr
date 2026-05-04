import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { FieldValue } from 'firebase-admin/firestore'
import { verifySession } from '@/lib/auth'
import { apiError } from '@/lib/utils'

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!await verifySession()) return apiError('Unauthorized', 401)
  const { id } = await params
  const doc = await adminDb().collection('listings').doc(id).get()
  if (!doc.exists) return apiError('Not found', 404)
  return Response.json({ listing: { id: doc.id, ...doc.data() } })
}

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!await verifySession()) return apiError('Unauthorized', 401)
  const { id } = await params
  const body = await req.json()
  const { status, rejectionReason, ...rest } = body

  const update: Record<string, unknown> = {
    ...rest,
    updatedAt: FieldValue.serverTimestamp(),
  }
  if (status) update.status = status
  if (rejectionReason !== undefined) update.rejectionReason = rejectionReason

  await adminDb().collection('listings').doc(id).update(update)

  if (status === 'active' || status === 'rejected') {
    await triggerWhatsAppAlert(id, status, rejectionReason)
  }

  return Response.json({ ok: true })
}

async function triggerWhatsAppAlert(
  listingId: string,
  status: string,
  reason?: string,
) {
  try {
    const db = adminDb()
    const trigger = status === 'active' ? 'listing_approved' : 'listing_rejected'

    const [listingDoc, templatesSnap] = await Promise.all([
      db.collection('listings').doc(listingId).get(),
      db.collection('whatsappTemplates').where('trigger', '==', trigger).where('isActive', '==', true).limit(1).get(),
    ])

    if (templatesSnap.empty || !listingDoc.exists) return

    const listing = listingDoc.data()!
    const template = templatesSnap.docs[0].data()
    const brokerPhone = listing.brokerPhone as string | undefined
    if (!brokerPhone) return

    const configDoc = await db.collection('config').doc('whatsapp').get()
    if (!configDoc.exists) return
    const { endpoint, token } = configDoc.data()!

    const vars: Record<string, string> = {
      name:    listing.brokerName ?? '',
      listing: `${listing.category} in ${listing.location}, ${listing.city}`,
      city:    listing.city ?? '',
      price:   String(listing.price ?? ''),
      reason:  reason ?? '',
    }
    const body = (template.body as string).replace(/\{\{(\w+)\}\}/g, (_: string, k: string) => vars[k] ?? '')

    await fetch(`${endpoint}/api/v1/sendSessionMessage/${brokerPhone}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ messageText: body }),
    })
  } catch (e) {
    console.error('[WhatsApp trigger]', e)
  }
}
