import { NextResponse } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { FieldValue, Timestamp } from 'firebase-admin/firestore'

export const dynamic = 'force-dynamic'

// ─── Seed data ────────────────────────────────────────────────────────────────

const CATEGORIES = [
  {
    name: 'barter',
    emoji: '🔄',
    label: 'Barter Deal',
    isActive: true,
    sortOrder: 1,
    fields: [
      { id: 'f1', label: 'Exchange Type', type: 'text', required: true },
      { id: 'f2', label: 'Exchange Value (₹)', type: 'number', required: false },
    ],
  },
  {
    name: 'project',
    emoji: '🏗️',
    label: 'New Project',
    isActive: true,
    sortOrder: 2,
    fields: [
      { id: 'f1', label: 'Project Name', type: 'text', required: true },
      { id: 'f2', label: 'Total Units', type: 'number', required: false },
      { id: 'f3', label: 'Possession Date', type: 'text', required: false },
      {
        id: 'f4',
        label: 'Configuration',
        type: 'select',
        options: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Villa', 'Plot'],
        required: true,
      },
    ],
  },
  {
    name: 'investor',
    emoji: '💰',
    label: 'Investor Deal',
    isActive: true,
    sortOrder: 3,
    fields: [
      { id: 'f1', label: 'Expected ROI (%)', type: 'number', required: true },
      { id: 'f2', label: 'Investment Horizon', type: 'text', required: false },
    ],
  },
  {
    name: 'discount',
    emoji: '🏷️',
    label: 'Distress / Discount',
    isActive: true,
    sortOrder: 4,
    fields: [
      { id: 'f1', label: 'Original Price (₹)', type: 'number', required: true },
      { id: 'f2', label: 'Discount Reason', type: 'text', required: false },
    ],
  },
  {
    name: 'rental',
    emoji: '🏠',
    label: 'Rental',
    isActive: true,
    sortOrder: 5,
    fields: [
      { id: 'f1', label: 'Rent/Month (₹)', type: 'number', required: true },
      {
        id: 'f2',
        label: 'Furnishing',
        type: 'select',
        options: ['Unfurnished', 'Semi-Furnished', 'Fully Furnished'],
        required: true,
      },
      { id: 'f3', label: 'Deposit (₹)', type: 'number', required: false },
      { id: 'f4', label: 'Pet Friendly', type: 'boolean', required: false },
    ],
  },
  {
    name: 'commercial',
    emoji: '🏢',
    label: 'Commercial',
    isActive: true,
    sortOrder: 6,
    fields: [
      {
        id: 'f1',
        label: 'Property Type',
        type: 'select',
        options: ['Office', 'Shop', 'Warehouse', 'Co-working', 'Showroom'],
        required: true,
      },
      { id: 'f2', label: 'Cabin Rooms', type: 'number', required: false },
    ],
  },
  {
    name: 'urgentSale',
    emoji: '⚡',
    label: 'Urgent Sale',
    isActive: true,
    sortOrder: 7,
    fields: [
      { id: 'f1', label: 'Reason for Urgency', type: 'text', required: false },
      { id: 'f2', label: 'Available Till', type: 'text', required: false },
    ],
  },
]

const SUBSCRIPTION_PLANS = [
  {
    name: 'Starter',
    price: 0,
    durationDays: 30,
    maxListings: 3,
    features: ['3 active listings', 'Basic profile', 'WhatsApp inquiries'],
    isActive: true,
    sortOrder: 1,
  },
  {
    name: 'Pro',
    price: 99900,
    durationDays: 30,
    maxListings: 15,
    features: [
      '15 active listings',
      'Verified badge',
      'Priority placement',
      'Analytics dashboard',
      'WhatsApp auto-alerts',
    ],
    isActive: true,
    sortOrder: 2,
  },
  {
    name: 'Premium',
    price: 249900,
    durationDays: 90,
    maxListings: 50,
    features: [
      '50 active listings',
      'Verified badge',
      'Top placement',
      'Advanced analytics',
      'WhatsApp auto-alerts',
      'Dedicated support',
      'CRM exports',
    ],
    isActive: true,
    sortOrder: 3,
  },
]

const WHATSAPP_TEMPLATES = [
  {
    name: 'Listing Approved',
    trigger: 'listing_approved',
    isActive: true,
    body:
      'Hi {{name}}, your listing *{{listing}}* in {{city}} has been approved! 🎉\n' +
      'It is now live on CPApp. Share it with your network to get more inquiries.\n\n' +
      'Team CPApp',
  },
  {
    name: 'Listing Rejected',
    trigger: 'listing_rejected',
    isActive: true,
    body:
      'Hi {{name}}, your listing *{{listing}}* could not be approved.\n\n' +
      'Reason: {{reason}}\n\n' +
      'Please update the listing and resubmit. If you need help, reply to this message.\n\n' +
      'Team CPApp',
  },
  {
    name: 'New CRM Lead',
    trigger: 'new_lead',
    isActive: true,
    body:
      'Hi {{name}}, you have a new lead on CPApp! 🔥\n\n' +
      'A broker is interested in your listing *{{listing}}* ({{city}}).\n' +
      'Open the app to view their contact and follow up.\n\n' +
      'Team CPApp',
  },
  {
    name: 'Subscription Expiry Reminder',
    trigger: 'subscription_expiry',
    isActive: false,
    body:
      'Hi {{name}}, your CPApp subscription expires in 3 days.\n\n' +
      'Renew now to keep your listings active and maintain your verified badge.\n\n' +
      'Team CPApp',
  },
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function daysAgo(n: number): Date {
  const d = new Date()
  d.setDate(d.getDate() - n)
  d.setHours(Math.floor(Math.random() * 14) + 8, 0, 0, 0)
  return d
}

// ─── Route ────────────────────────────────────────────────────────────────────

export async function POST(req: Request) {
  const session = await verifySession()
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const url   = new URL(req.url)
  const force = url.searchParams.get('force') === '1'

  const db = adminDb()

  // ── Categories ──────────────────────────────────────────────────────────────
  const catSnap = await db.collection('categories').count().get()
  let categoriesSeeded = 0
  if (force || catSnap.data().count === 0) {
    const existing = await db.collection('categories').get()
    const batch = db.batch()
    existing.docs.forEach((d) => batch.delete(d.ref))
    await batch.commit()
    const batch2 = db.batch()
    CATEGORIES.forEach((cat) => {
      const ref = db.collection('categories').doc(cat.name)
      batch2.set(ref, { ...cat, createdAt: FieldValue.serverTimestamp() })
    })
    await batch2.commit()
    categoriesSeeded = CATEGORIES.length
  }

  // ── Subscription plans ───────────────────────────────────────────────────────
  const planSnap = await db.collection('subscriptionPlans').count().get()
  let plansSeeded = 0
  if (force || planSnap.data().count === 0) {
    const existing = await db.collection('subscriptionPlans').get()
    const batch = db.batch()
    existing.docs.forEach((d) => batch.delete(d.ref))
    await batch.commit()
    const batch2 = db.batch()
    SUBSCRIPTION_PLANS.forEach((plan) => {
      const ref = db.collection('subscriptionPlans').doc()
      batch2.set(ref, { ...plan, createdAt: FieldValue.serverTimestamp() })
    })
    await batch2.commit()
    plansSeeded = SUBSCRIPTION_PLANS.length
  }

  // ── WhatsApp templates ───────────────────────────────────────────────────────
  const tmplSnap = await db.collection('whatsappTemplates').count().get()
  let templatesSeeded = 0
  if (force || tmplSnap.data().count === 0) {
    const existing = await db.collection('whatsappTemplates').get()
    const batch = db.batch()
    existing.docs.forEach((d) => batch.delete(d.ref))
    await batch.commit()
    const batch2 = db.batch()
    WHATSAPP_TEMPLATES.forEach((tmpl) => {
      const ref = db.collection('whatsappTemplates').doc()
      batch2.set(ref, { ...tmpl, createdAt: FieldValue.serverTimestamp() })
    })
    await batch2.commit()
    templatesSeeded = WHATSAPP_TEMPLATES.length
  }

  // ── Historical analytics events (past 30 days) ───────────────────────────────
  const eventSnap = await db.collection('appEvents').count().get()
  let eventsSeeded = 0
  if (force || eventSnap.data().count < 50) {
    // Seed realistic daily open counts: ramp up over 30 days
    const writes: Promise<unknown>[] = []
    for (let day = 29; day >= 0; day--) {
      const opensToday = Math.floor(10 + (30 - day) * 1.5 + Math.random() * 8)
      for (let i = 0; i < opensToday; i++) {
        const ts = daysAgo(day)
        ts.setMinutes(Math.floor(Math.random() * 60))
        writes.push(
          db.collection('appEvents').add({
            event: 'app_open',
            uid: `seed_user_${(i % 10) + 1}`,
            timestamp: Timestamp.fromDate(ts),
          }),
        )
      }
    }
    await Promise.all(writes)
    eventsSeeded = writes.length
  }

  return NextResponse.json({
    ok: true,
    seeded: { categoriesSeeded, plansSeeded, templatesSeeded, eventsSeeded },
  })
}
