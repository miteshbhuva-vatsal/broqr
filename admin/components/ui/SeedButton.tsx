'use client'

import { useState } from 'react'
import { Database } from 'lucide-react'

export default function SeedButton() {
  const [status, setStatus] = useState<'idle' | 'loading' | 'done' | 'error'>('idle')
  const [summary, setSummary] = useState('')

  async function handleSeed(force = false) {
    setStatus('loading')
    setSummary('')
    try {
      const res  = await fetch(`/api/seed${force ? '?force=1' : ''}`, { method: 'POST' })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error ?? 'Seed failed')
      const s = data.seeded
      const parts = []
      if (s.categoriesSeeded)  parts.push(`${s.categoriesSeeded} categories`)
      if (s.plansSeeded)       parts.push(`${s.plansSeeded} plans`)
      if (s.templatesSeeded)   parts.push(`${s.templatesSeeded} templates`)
      if (s.eventsSeeded)      parts.push(`${s.eventsSeeded} analytics events`)
      setSummary(parts.length ? `Seeded: ${parts.join(', ')}` : 'Already seeded — use Force Reseed to overwrite.')
      setStatus('done')
    } catch (err) {
      setSummary(err instanceof Error ? err.message : 'Unknown error')
      setStatus('error')
    }
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center gap-2">
        <button
          onClick={() => handleSeed(false)}
          disabled={status === 'loading'}
          className="flex items-center gap-1.5 rounded-lg border border-navy-200 bg-white px-3 py-2 text-xs font-medium text-navy-700 shadow-sm transition hover:bg-navy-50 disabled:opacity-50"
        >
          <Database size={14} />
          {status === 'loading' ? 'Seeding…' : 'Seed Demo Data'}
        </button>
        <button
          onClick={() => handleSeed(true)}
          disabled={status === 'loading'}
          className="rounded-lg border border-gray-200 bg-white px-3 py-2 text-xs font-medium text-gray-500 shadow-sm transition hover:bg-gray-50 disabled:opacity-50"
        >
          Force Reseed
        </button>
      </div>
      {summary && (
        <p className={`text-xs ${status === 'error' ? 'text-red-600' : 'text-green-700'}`}>
          {summary}
        </p>
      )}
    </div>
  )
}
