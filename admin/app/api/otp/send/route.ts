import { NextRequest } from 'next/server'
import { apiError } from '@/lib/utils'

const AUTH_KEY = process.env.MSG91_AUTH_KEY!
const TEMPLATE_ID = process.env.MSG91_TEMPLATE_ID!
const SENDER_ID = process.env.MSG91_SENDER_ID!

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const { mobile } = body as { mobile?: string }

  if (!mobile || !/^\d{10}$/.test(mobile)) {
    return apiError('Enter a valid 10-digit mobile number', 400)
  }

  if (!AUTH_KEY || !TEMPLATE_ID) {
    return apiError('MSG91 not configured', 500)
  }

  const res = await fetch('https://control.msg91.com/api/v5/otp', {
    method: 'POST',
    headers: {
      authkey: AUTH_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      mobile: `91${mobile}`,
      template_id: TEMPLATE_ID,
      sender: SENDER_ID,
      otp_length: 6,
      otp_expiry: 10,
    }),
  })

  const data = await res.json().catch(() => ({ type: 'error' }))

  if (data.type === 'success') {
    return Response.json({ ok: true })
  }

  return apiError(data.message ?? 'Failed to send OTP. Please try again.', 502)
}
