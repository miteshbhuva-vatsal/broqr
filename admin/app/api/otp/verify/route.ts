import { NextRequest } from 'next/server'
import { apiError } from '@/lib/utils'

const AUTH_KEY = process.env.MSG91_AUTH_KEY!

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => ({}))
  const { mobile, otp } = body as { mobile?: string; otp?: string }

  if (!mobile || !/^\d{10}$/.test(mobile)) {
    return apiError('Invalid mobile number', 400)
  }
  if (!otp || !/^\d{6}$/.test(otp)) {
    return apiError('Enter the 6-digit OTP', 400)
  }

  if (!AUTH_KEY) {
    return apiError('MSG91 not configured', 500)
  }

  const url = `https://control.msg91.com/api/v5/otp/verify?otp=${otp}&mobile=91${mobile}`
  const res = await fetch(url, {
    method: 'GET',
    headers: { authkey: AUTH_KEY },
  })

  const data = await res.json().catch(() => ({ type: 'error' }))

  if (data.type === 'success') {
    return Response.json({ ok: true })
  }

  return apiError(
    data.message?.toLowerCase().includes('not match')
      ? 'Incorrect OTP. Please try again.'
      : (data.message ?? 'OTP verification failed.'),
    400,
  )
}
