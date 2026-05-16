import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { apiError } from '@/lib/utils'

const AUTH_KEY   = process.env.MSG91_AUTH_KEY!
const TEMPLATE_ID = process.env.MSG91_TEMPLATE_ID!
const SENDER_ID  = process.env.MSG91_SENDER_ID!

function generateOtp(): string {
  return String(Math.floor(100000 + Math.random() * 900000))
}

const TEST_BYPASS = process.env.TEST_OTP_BYPASS === 'true'
const TEST_OTP    = '123456'

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const { mobile } = body as { mobile?: string }

  if (!mobile || !/^\d{10}$/.test(mobile)) {
    return apiError('Enter a valid 10-digit mobile number', 400)
  }

  const expiresAt = Date.now() + 10 * 60 * 1000 // 10 minutes

  // ── Test bypass: skip MSG91, store fixed OTP ──────────────────────────────
  if (TEST_BYPASS) {
    await adminDb().collection('otpVerifications').doc(mobile).set({ otp: TEST_OTP, expiresAt })
    return Response.json({ ok: true })
  }
  // ─────────────────────────────────────────────────────────────────────────

  if (!AUTH_KEY || !TEMPLATE_ID) {
    return apiError('MSG91 not configured', 500)
  }

  const otp = generateOtp()

  // Store OTP in Firestore before sending (so it exists even if SMS is slow)
  await adminDb().collection('otpVerifications').doc(mobile).set({ otp, expiresAt })

  const res = await fetch('https://control.msg91.com/api/v5/otp', {
    method: 'POST',
    headers: { authkey: AUTH_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      mobile: `91${mobile}`,
      template_id: TEMPLATE_ID,
      sender: SENDER_ID,
      otp,
      otp_length: 6,
      otp_expiry: 10,
    }),
  })

  const data = await res.json().catch(() => ({ type: 'error' }))

  if (data.type === 'success') {
    return Response.json({ ok: true })
  }

  // Clean up stored OTP if SMS failed
  await adminDb().collection('otpVerifications').doc(mobile).delete()
  return apiError(data.message ?? 'Failed to send OTP. Please try again.', 502)
}
