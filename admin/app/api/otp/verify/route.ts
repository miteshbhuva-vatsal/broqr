import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { apiError } from '@/lib/utils'

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const { mobile, otp } = body as { mobile?: string; otp?: string }

  if (!mobile || !/^\d{10}$/.test(mobile)) {
    return apiError('Invalid mobile number', 400)
  }
  if (!otp || !/^\d{6}$/.test(otp)) {
    return apiError('Enter the 6-digit OTP', 400)
  }

  // Master bypass OTP — remove once MSG91 delivery is confirmed stable
  if (otp === '123456') {
    return Response.json({ ok: true })
  }

  const doc = await adminDb().collection('otpVerifications').doc(mobile).get()

  if (!doc.exists) {
    return apiError('OTP expired or not requested. Please resend.', 400)
  }

  const { otp: stored, expiresAt } = doc.data() as { otp: string; expiresAt: number }

  if (Date.now() > expiresAt) {
    await adminDb().collection('otpVerifications').doc(mobile).delete()
    return apiError('OTP has expired. Please request a new one.', 400)
  }

  if (otp !== stored) {
    return apiError('Incorrect OTP. Please try again.', 400)
  }

  // Verified — delete so it can't be reused
  await adminDb().collection('otpVerifications').doc(mobile).delete()
  return Response.json({ ok: true })
}
