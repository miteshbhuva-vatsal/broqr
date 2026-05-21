import { NextRequest, NextResponse } from 'next/server'

// CORS for /api/otp/* so the Flutter web build (served from a different
// origin in dev and any DigiProp web origin in prod) can call these routes.
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
}

function withCors(res: NextResponse) {
  for (const [k, v] of Object.entries(CORS_HEADERS)) res.headers.set(k, v)
  return res
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const session = request.cookies.get('admin_session')?.value

  // CORS preflight for OTP endpoints
  if (pathname.startsWith('/api/otp') && request.method === 'OPTIONS') {
    return new NextResponse(null, { status: 204, headers: CORS_HEADERS })
  }

  // Public routes
  if (pathname.startsWith('/login') || pathname.startsWith('/api/auth') || pathname.startsWith('/api/otp') || pathname.startsWith('/api/news') || pathname.startsWith('/portfolio') || pathname.startsWith('/api/portfolio') || pathname.startsWith('/listing') || pathname.startsWith('/broker') || pathname.startsWith('/post')) {
    if (session && pathname === '/login') {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
    const res = NextResponse.next()
    if (pathname.startsWith('/api/otp')) return withCors(res)
    return res
  }

  // Protect all other routes
  if (!session) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
