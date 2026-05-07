import { adminAuth, adminDb } from '@/lib/firebase-admin'
import { cookies } from 'next/headers'

const SESSION_COOKIE = 'admin_session'
const SESSION_DURATION_MS = 60 * 60 * 24 * 5 * 1000 // 5 days

export async function createSessionCookie(idToken: string): Promise<string> {
  return adminAuth().createSessionCookie(idToken, {
    expiresIn: SESSION_DURATION_MS,
  })
}

export async function verifySession(): Promise<{ uid: string; email: string } | null> {
  try {
    const cookieStore = await cookies()
    const session = cookieStore.get(SESSION_COOKIE)?.value
    if (!session) return null

    const decoded = await adminAuth().verifySessionCookie(session, true)

    // Fast path: custom claims set at login — no Firestore round-trip needed
    if (decoded.admin === true) {
      return { uid: decoded.uid, email: decoded.email ?? '' }
    }

    // Fallback: check Firestore (for users created before custom claims were used)
    const userDoc = await adminDb().collection('users').doc(decoded.uid).get()
    if (!userDoc.exists) return null
    const role = userDoc.data()?.role as string | undefined
    if (role !== 'admin') return null

    // Backfill the custom claim so next request is fast
    await adminAuth().setCustomUserClaims(decoded.uid, { admin: true })

    return { uid: decoded.uid, email: decoded.email ?? '' }
  } catch {
    return null
  }
}

export async function setSessionCookie(cookie: string): Promise<void> {
  const cookieStore = await cookies()
  cookieStore.set(SESSION_COOKIE, cookie, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: SESSION_DURATION_MS / 1000,
    path: '/',
  })
}

export async function clearSessionCookie(): Promise<void> {
  const cookieStore = await cookies()
  cookieStore.set(SESSION_COOKIE, '', { maxAge: 0, path: '/' })
}
