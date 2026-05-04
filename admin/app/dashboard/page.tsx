export const dynamic = 'force-dynamic'

import { adminDb } from '@/lib/firebase-admin'
import Header from '@/components/layout/Header'
import StatCard from '@/components/ui/StatCard'
import { Building2, Users, Clock, TrendingUp, CheckCircle, XCircle } from 'lucide-react'
import { formatDate } from '@/lib/utils'
import Link from 'next/link'
import SeedButton from '@/components/ui/SeedButton'

async function getDashboardData() {
  const db = adminDb()
  const now = new Date()
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)

  const [listingsSnap, usersSnap, pendingSnap, recentListings, recentUsers] = await Promise.all([
    db.collection('listings').count().get(),
    db.collection('users').count().get(),
    db.collection('listings').where('status', '==', 'pending_review').count().get(),
    db.collection('listings').orderBy('createdAt', 'desc').limit(5).get(),
    db.collection('users').orderBy('createdAt', 'desc').limit(5).get(),
  ])

  const [newTodaySnap, newMonthSnap, dauSnap] = await Promise.all([
    db.collection('users').where('createdAt', '>=', todayStart).count().get(),
    db.collection('users').where('createdAt', '>=', monthStart).count().get(),
    db.collection('users').where('lastSeen', '>=', todayStart).count().get(),
  ])

  return {
    totalListings:  listingsSnap.data().count,
    totalUsers:     usersSnap.data().count,
    pendingApproval: pendingSnap.data().count,
    newUsersToday:  newTodaySnap.data().count,
    newUsersMonth:  newMonthSnap.data().count,
    dau:            dauSnap.data().count,
    recentListings: recentListings.docs.map((d) => ({ id: d.id, ...d.data() })),
    recentUsers:    recentUsers.docs.map((d) => ({ id: d.id, ...d.data() })),
  }
}

export default async function DashboardPage() {
  const data = await getDashboardData()

  return (
    <div>
      <Header
        title="Dashboard"
        subtitle={`Welcome back — ${new Date().toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' })}`}
        actions={<SeedButton />}
      />

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4 mb-8">
        <StatCard label="Total Listings"     value={data.totalListings}   icon={Building2}  color="blue"   />
        <StatCard label="Total Users"        value={data.totalUsers}      icon={Users}      color="green"  />
        <StatCard label="Pending Approval"   value={data.pendingApproval} icon={Clock}      color="amber"
          change={data.pendingApproval > 0 ? 'Needs attention' : 'All clear'} changeType={data.pendingApproval > 0 ? 'down' : 'up'} />
        <StatCard label="DAU (Today)"        value={data.dau}             icon={TrendingUp} color="purple"
          change={`${data.newUsersToday} new today`} changeType="up" />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent listings */}
        <div className="rounded-xl border border-gray-100 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-gray-100 px-5 py-4">
            <h2 className="font-semibold text-gray-900">Recent Listings</h2>
            <Link href="/dashboard/listings" className="text-xs text-navy-600 hover:underline">View all</Link>
          </div>
          <div className="divide-y divide-gray-50">
            {data.recentListings.map((l: Record<string, unknown>) => (
              <Link
                key={l.id as string}
                href={`/dashboard/listings/${l.id}`}
                className="flex items-center justify-between px-5 py-3 hover:bg-gray-50 transition"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900 line-clamp-1">
                    {l.category as string} · {l.location as string}, {l.city as string}
                  </p>
                  <p className="text-xs text-gray-400">{l.brokerName as string}</p>
                </div>
                <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                  l.status === 'active' ? 'bg-green-100 text-green-700' :
                  l.status === 'pending_review' ? 'bg-amber-100 text-amber-700' :
                  'bg-gray-100 text-gray-600'
                }`}>
                  {l.status as string}
                </span>
              </Link>
            ))}
          </div>
        </div>

        {/* Recent users */}
        <div className="rounded-xl border border-gray-100 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-gray-100 px-5 py-4">
            <h2 className="font-semibold text-gray-900">Recent Users</h2>
            <Link href="/dashboard/users" className="text-xs text-navy-600 hover:underline">View all</Link>
          </div>
          <div className="divide-y divide-gray-50">
            {data.recentUsers.map((u: Record<string, unknown>) => (
              <div key={u.id as string} className="flex items-center justify-between px-5 py-3">
                <div>
                  <p className="text-sm font-medium text-gray-900">{u.name as string || 'No name'}</p>
                  <p className="text-xs text-gray-400">{u.mobile as string || u.email as string}</p>
                </div>
                <div className="flex items-center gap-2 text-xs text-gray-400">
                  {u.isVerified ? (
                    <CheckCircle size={14} className="text-green-500" />
                  ) : (
                    <XCircle size={14} className="text-gray-300" />
                  )}
                  {u.createdAt ? formatDate(u.createdAt as { _seconds: number }) : ''}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
