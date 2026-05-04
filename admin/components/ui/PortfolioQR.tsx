'use client'

import { QRCodeSVG } from 'qrcode.react'
import { useCallback, useRef } from 'react'
import { Download, ExternalLink } from 'lucide-react'

interface Props {
  uid: string
  userName: string
}

export default function PortfolioQR({ uid, userName }: Props) {
  const svgRef = useRef<HTMLDivElement>(null)
  const portfolioUrl = `${window.location.origin}/portfolio/${uid}`

  const downloadQR = useCallback(() => {
    const svg = svgRef.current?.querySelector('svg')
    if (!svg) return

    const canvas = document.createElement('canvas')
    const size = 400
    canvas.width  = size
    canvas.height = size + 48

    const ctx = canvas.getContext('2d')!
    ctx.fillStyle = '#ffffff'
    ctx.fillRect(0, 0, canvas.width, canvas.height)

    // Draw QR into canvas via SVG blob
    const xml  = new XMLSerializer().serializeToString(svg)
    const blob = new Blob([xml], { type: 'image/svg+xml' })
    const url  = URL.createObjectURL(blob)
    const img  = new window.Image()
    img.onload = () => {
      ctx.drawImage(img, 0, 0, size, size)
      URL.revokeObjectURL(url)

      // Label below
      ctx.fillStyle = '#0A1628'
      ctx.font      = 'bold 14px sans-serif'
      ctx.textAlign = 'center'
      ctx.fillText(userName, size / 2, size + 20)
      ctx.fillStyle = '#6b7280'
      ctx.font      = '11px sans-serif'
      ctx.fillText('Scan to view portfolio · CPApp', size / 2, size + 38)

      const link    = document.createElement('a')
      link.download = `${userName.replace(/\s+/g, '_')}_portfolio_qr.png`
      link.href     = canvas.toDataURL('image/png')
      link.click()
    }
    img.src = url
  }, [uid, userName])

  return (
    <div className="flex flex-col items-center gap-3 py-2">
      <div ref={svgRef} className="rounded-xl border border-gray-200 bg-white p-3 shadow-sm">
        <QRCodeSVG
          value={portfolioUrl}
          size={180}
          level="M"
          includeMargin={false}
          imageSettings={{
            src: '/favicon.ico',
            height: 28,
            width: 28,
            excavate: true,
          }}
        />
      </div>

      <p className="text-xs text-gray-400 text-center max-w-[200px] break-all">{portfolioUrl}</p>

      <div className="flex gap-2">
        <button
          onClick={downloadQR}
          className="flex items-center gap-1.5 rounded-lg bg-[#0A1628] px-3 py-2 text-xs font-semibold text-white hover:bg-navy-700 transition"
        >
          <Download size={13} /> Download QR
        </button>
        <a
          href={portfolioUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-1.5 rounded-lg border border-gray-200 px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 transition"
        >
          <ExternalLink size={13} /> Preview
        </a>
      </div>
    </div>
  )
}
