'use client'

import { useState } from 'react'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { clientAuth } from '@/lib/firebase-client'

export default function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const cred = await signInWithEmailAndPassword(clientAuth, email, password)
      const idToken = await cred.user.getIdToken()

      const res = await fetch('/api/auth/session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      })

      if (!res.ok) {
        const data = await res.json()
        throw new Error(data.error ?? 'Access denied. Admin accounts only.')
      }

      window.location.href = '/dashboard'
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Sign-in failed.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-navy-900 px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-amber-500 text-xl font-bold text-navy-900">
            CP
          </div>
          <h1 className="text-2xl font-bold text-white">CPApp Admin</h1>
          <p className="mt-1 text-sm text-navy-100 opacity-60">Sign in to manage your platform</p>
        </div>

        <form onSubmit={handleSubmit} className="rounded-xl bg-white p-6 shadow-2xl space-y-4">
          {error && (
            <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
          )}
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500">
              Email
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2.5 text-sm outline-none focus:border-navy-500 focus:ring-1 focus:ring-navy-500"
              placeholder="admin@cpapp.in"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500">
              Password
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2.5 text-sm outline-none focus:border-navy-500 focus:ring-1 focus:ring-navy-500"
              placeholder="••••••••"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-navy-700 py-2.5 text-sm font-semibold text-white transition hover:bg-navy-600 disabled:opacity-60"
          >
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}
