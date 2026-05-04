import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'CPApp Admin',
  description: 'CPApp administration panel',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
