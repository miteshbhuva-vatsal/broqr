export const dynamic = 'force-dynamic'

import Sidebar from '@/components/layout/Sidebar'
import { verifySession } from '@/lib/auth'
import { redirect } from 'next/navigation'

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await verifySession()
  if (!session) redirect('/login')

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="ml-60 flex-1 px-8 py-8">{children}</main>
    </div>
  )
}
