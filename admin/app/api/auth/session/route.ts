import { NextRequest } from 'next/server'
import { createSessionCookie, setSessionCookie, clearSessionCookie } from '@/lib/auth'
import { adminAuth, adminDb } from '@/lib/firebase-admin'
import { apiError } from '@/lib/utils'

export async function POST(req: NextRequest) {
  try {
    const { idToken } = await req.json()
    if (!idToken) return apiError('Missing idToken', 400)

    // Verify token and check admin role
    const decoded = await adminAuth().verifyIdToken(idToken)
    const userDoc = await adminDb().collection('users').doc(decoded.uid).get()
    if (!userDoc.exists || userDoc.data()?.role !== 'admin') {
      return apiError('Access denied. Admin accounts only.', 403)
    }

    // Stamp admin custom claim so verifySession() skips Firestore on every request
    if (!decoded.admin) {
      await adminAuth().setCustomUserClaims(decoded.uid, { admin: true })
    }

    const cookie = await createSessionCookie(idToken)
    await setSessionCookie(cookie)

    return Response.json({ ok: true })
  } catch (err) {
    console.error('[auth/session]', err)
    return apiError('Authentication failed.', 401)
  }
}

export async function DELETE() {
  await clearSessionCookie()
  return Response.json({ ok: true })
}
