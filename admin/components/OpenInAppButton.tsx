'use client'

import { useState } from 'react'
import { Smartphone } from 'lucide-react'

interface Props {
  deepLink: string   // cpapp://listing/{id}
  webLink: string    // https://www.digiprop.co.in/listing/{id}  (fallback for og share)
  label?: string
}

export function OpenInAppButton({ deepLink, label = 'Open in App' }: Props) {
  const [tried, setTried] = useState(false)

  function handleClick() {
    setTried(true)
    // Try to open the app via custom scheme
    window.location.href = deepLink

    // After 2.5 s, if still on this page, redirect to Play Store
    setTimeout(() => {
      window.location.href =
        'https://play.google.com/store/apps/details?id=com.digiprop.cpapp'
    }, 2500)
  }

  return (
    <button
      onClick={handleClick}
      className="w-full flex items-center justify-center gap-2 rounded-2xl bg-[#0A1628] py-4 text-sm font-bold text-amber-400 shadow-md active:opacity-80 transition-opacity"
    >
      <Smartphone size={18} />
      {tried ? 'Opening…' : label}
    </button>
  )
}
