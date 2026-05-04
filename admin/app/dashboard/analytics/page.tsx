'use client'

import { useEffect, useState } from 'react'
import Header from '@/components/layout/Header'
import StatCard from '@/components/ui/StatCard'
import Spinner from '@/components/ui/Spinner'
import {
  LineChart, Line, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
} from 'recharts'
import { Users, Building2, Eye, Smartphone } from 'lucide-react'

interface AnalyticsData {
  dau: number
  mau: number
  totalUsers: number
  totalListings: number
  newUsersToday: number
  newListingsToday: number
  dailySeries: { date: string; newUsers: number; newListings: number; appOpens: number; dau: number }[]
}

const RANGES = ['7d', '30d', '90d'] as const
type Range = typeof RANGES[number]

export default function AnalyticsPage() {
  const [data, setData]     = useState<AnalyticsData | null>(null)
  const [loading, setLoading] = useState(true)
  const [range, setRange]   = useState<Range>('30d')

  async function load() {
    setLoading(true)
    const res = await fetch(`/api/analytics?range=${range}`)
    const json = await res.json()
    setData(json)
    setLoading(false)
  }

  useEffect(() => { load() }, [range]) // eslint-disable-line

  return (
    <div>
      <Header
        title="Analytics"
        subtitle="Platform performance and user engagement metrics"
        actions={
          <div className="flex items-center gap-1 rounded-lg bg-gray-100 p-1">
            {RANGES.map((r) => (
              <button
                key={r}
                onClick={() => setRange(r)}
                className={`rounded-md px-3 py-1 text-xs font-semibold transition ${range === r ? 'bg-white shadow text-navy-800' : 'text-gray-500 hover:text-gray-800'}`}
              >
                {r}
              </button>
            ))}
          </div>
        }
      />

      {loading || !data ? (
        <div className="flex h-64 items-center justify-center"><Spinner /></div>
      ) : (
        <div className="space-y-6">
          {/* Stats */}
          <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
            <StatCard label="DAU"              value={data.dau}             icon={Smartphone} color="blue"
              change={`+${data.newUsersToday} new today`} changeType="up" />
            <StatCard label="MAU"              value={data.mau}             icon={Users}      color="green" />
            <StatCard label="Total Users"      value={data.totalUsers}      icon={Users}      color="purple" />
            <StatCard label="Total Listings"   value={data.totalListings}   icon={Building2}  color="amber" />
          </div>

          {/* User growth chart */}
          <div className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <h2 className="mb-4 font-semibold text-gray-900">User Growth</h2>
            <ResponsiveContainer width="100%" height={240}>
              <LineChart data={data.dailySeries}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => v.slice(5)} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="newUsers"  name="New Users"  stroke="#6366f1" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="dau"       name="DAU"        stroke="#10b981" strokeWidth={2} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* App opens + listings chart */}
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            <div className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
              <h2 className="mb-4 font-semibold text-gray-900">App Opens per Day</h2>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={data.dailySeries}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => v.slice(5)} />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip />
                  <Bar dataKey="appOpens" name="App Opens" fill="#f59e0b" radius={[3,3,0,0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            <div className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
              <h2 className="mb-4 font-semibold text-gray-900">New Listings per Day</h2>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={data.dailySeries}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                  <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => v.slice(5)} />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip />
                  <Bar dataKey="newListings" name="New Listings" fill="#1a237e" radius={[3,3,0,0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Summary table */}
          <div className="rounded-xl border border-gray-100 bg-white shadow-sm overflow-hidden">
            <div className="px-5 py-4 border-b border-gray-100">
              <h2 className="font-semibold text-gray-900">Daily Summary</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 text-xs font-semibold uppercase text-gray-500">
                  <tr>
                    <th className="px-4 py-3 text-left">Date</th>
                    <th className="px-4 py-3 text-right">DAU</th>
                    <th className="px-4 py-3 text-right">New Users</th>
                    <th className="px-4 py-3 text-right">App Opens</th>
                    <th className="px-4 py-3 text-right">New Listings</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {[...data.dailySeries].reverse().slice(0, 14).map((row) => (
                    <tr key={row.date} className="hover:bg-gray-50">
                      <td className="px-4 py-2.5 text-gray-600">{row.date}</td>
                      <td className="px-4 py-2.5 text-right font-medium">{row.dau}</td>
                      <td className="px-4 py-2.5 text-right text-green-600">+{row.newUsers}</td>
                      <td className="px-4 py-2.5 text-right text-amber-600">{row.appOpens}</td>
                      <td className="px-4 py-2.5 text-right">{row.newListings}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
