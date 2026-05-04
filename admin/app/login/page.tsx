'use client'

import dynamic from 'next/dynamic'

// Firebase client SDK must not run on the server — load the form client-only.
const LoginForm = dynamic(() => import('./LoginForm'), { ssr: false })

export default function LoginPage() {
  return <LoginForm />
}
