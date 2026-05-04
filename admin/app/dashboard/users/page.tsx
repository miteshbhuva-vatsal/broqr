'use client'

import { useEffect, useState } from 'react'
import Header from '@/components/layout/Header'
import DataTable, { Column } from '@/components/ui/DataTable'
import Badge from '@/components/ui/Badge'
import Modal from '@/components/ui/Modal'
import { AppUser } from '@/types'
import { formatDate } from '@/lib/utils'
import { CheckCircle, XCircle, ShieldCheck, Ban, QrCode } from 'lucide-react'
import Image from 'next/image'
import dynamic from 'next/dynamic'

const PortfolioQR = dynamic(() => import('@/components/ui/PortfolioQR'), { ssr: false })

export default function UsersPage() {
  const [users, setUsers]         = useState<AppUser[]>([])
  const [loading, setLoading]     = useState(true)
  const [selected, setSelected]   = useState<AppUser | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [msg, setMsg]             = useState('')
  const [modalTab, setModalTab]   = useState<'info' | 'qr'>('info')

  async function load() {
    setLoading(true)
    const res = await fetch('/api/users')
    const data = await res.json()
    setUsers(data.users ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  async function updateUser(uid: string, payload: Partial<AppUser>) {
    setSubmitting(true)
    const res = await fetch(`/api/users/${uid}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (res.ok) {
      setMsg('Updated successfully.')
      await load()
      setSelected(null)
    } else {
      setMsg('Update failed.')
    }
    setSubmitting(false)
  }

  const columns: Column<AppUser>[] = [
    {
      key: 'user',
      header: 'User',
      render: (u) => (
        <div className="flex items-center gap-3">
          {u.photoUrl ? (
            <Image src={u.photoUrl} alt={u.name} width={32} height={32} className="rounded-full object-cover" />
          ) : (
            <div className="h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center text-xs font-semibold text-gray-500">
              {u.name?.[0]?.toUpperCase() ?? '?'}
            </div>
          )}
          <div>
            <p className="font-medium text-gray-900">{u.name || 'No name'}</p>
            <p className="text-xs text-gray-400">{u.mobile || u.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'city',
      header: 'City',
      render: (u) => <span className="text-gray-600">{u.city || '—'}</span>,
      width: '100px',
    },
    {
      key: 'role',
      header: 'Role',
      render: (u) => <Badge variant={u.role as 'admin' | 'broker' | 'viewer'}>{u.role}</Badge>,
      width: '80px',
    },
    {
      key: 'verified',
      header: 'Verified',
      render: (u) => u.isVerified
        ? <CheckCircle size={16} className="text-green-500" />
        : <XCircle size={16} className="text-gray-300" />,
      width: '70px',
    },
    {
      key: 'status',
      header: 'Status',
      render: (u) => u.isBanned
        ? <Badge variant="banned">Banned</Badge>
        : <Badge variant="active">Active</Badge>,
      width: '80px',
    },
    {
      key: 'listings',
      header: 'Listings',
      render: (u) => <span className="text-gray-600">{u.listingsCount}</span>,
      width: '70px',
    },
    {
      key: 'joined',
      header: 'Joined',
      render: (u) => <span className="text-gray-500">{u.createdAt ? formatDate(u.createdAt as { _seconds: number }) : '—'}</span>,
      width: '110px',
    },
    {
      key: 'actions',
      header: '',
      render: (u) => (
        <button
          onClick={() => { setSelected(u); setMsg(''); setModalTab('info') }}
          className="rounded px-2 py-1 text-xs font-medium text-navy-700 hover:bg-navy-50"
        >
          Manage
        </button>
      ),
      width: '70px',
    },
  ]

  return (
    <div>
      <Header title="Users" subtitle="Manage broker accounts and permissions" />

      {msg && <div className="mb-4 text-sm text-green-600">{msg}</div>}

      <DataTable
        columns={columns}
        data={users}
        loading={loading}
        keyExtractor={(u) => u.uid}
        searchable
        searchKeys={['name', 'mobile', 'city', 'email']}
        emptyMessage="No users found."
      />

      {/* User manage modal */}
      {selected && (
        <Modal open={!!selected} onClose={() => setSelected(null)} title={`Manage: ${selected.name}`}>
          {/* Tabs */}
          <div className="flex gap-1 mb-4 border-b border-gray-100 pb-0">
            <button
              onClick={() => setModalTab('info')}
              className={`flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-t-lg transition border-b-2 ${
                modalTab === 'info'
                  ? 'border-navy-700 text-navy-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Profile Info
            </button>
            <button
              onClick={() => setModalTab('qr')}
              className={`flex items-center gap-1.5 px-3 py-2 text-xs font-semibold rounded-t-lg transition border-b-2 ${
                modalTab === 'qr'
                  ? 'border-navy-700 text-navy-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              <QrCode size={13} /> Portfolio QR
            </button>
          </div>

          {modalTab === 'info' ? (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-3 text-sm">
                <Info label="Mobile"   value={selected.mobile ?? '—'} />
                <Info label="Email"    value={selected.email ?? '—'} />
                <Info label="City"     value={selected.city ?? '—'} />
                <Info label="Role"     value={selected.role} />
                <Info label="RERA"     value={selected.reraNumber ?? '—'} />
                <Info label="Referral" value={selected.referralCode ?? '—'} />
                <Info label="Listings" value={String(selected.listingsCount)} />
                <Info label="Joined"   value={selected.createdAt ? formatDate(selected.createdAt as { _seconds: number }) : '—'} />
              </div>

              {msg && <p className="text-xs text-green-600">{msg}</p>}

              <div className="border-t border-gray-100 pt-4 flex flex-wrap gap-2">
                {!selected.isVerified ? (
                  <button
                    onClick={() => updateUser(selected.uid, { isVerified: true })}
                    disabled={submitting}
                    className="flex items-center gap-1.5 rounded-lg bg-green-600 px-3 py-2 text-xs font-semibold text-white hover:bg-green-700 disabled:opacity-60"
                  >
                    <ShieldCheck size={14} /> Verify User
                  </button>
                ) : (
                  <button
                    onClick={() => updateUser(selected.uid, { isVerified: false })}
                    disabled={submitting}
                    className="flex items-center gap-1.5 rounded-lg border border-gray-200 px-3 py-2 text-xs font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-60"
                  >
                    Unverify
                  </button>
                )}

                {!selected.isBanned ? (
                  <button
                    onClick={() => updateUser(selected.uid, { isBanned: true })}
                    disabled={submitting}
                    className="flex items-center gap-1.5 rounded-lg bg-red-600 px-3 py-2 text-xs font-semibold text-white hover:bg-red-700 disabled:opacity-60"
                  >
                    <Ban size={14} /> Ban User
                  </button>
                ) : (
                  <button
                    onClick={() => updateUser(selected.uid, { isBanned: false })}
                    disabled={submitting}
                    className="flex items-center gap-1.5 rounded-lg bg-green-600 px-3 py-2 text-xs font-semibold text-white hover:bg-green-700 disabled:opacity-60"
                  >
                    Unban User
                  </button>
                )}

                {selected.role !== 'admin' && (
                  <button
                    onClick={() => updateUser(selected.uid, { role: 'admin' })}
                    disabled={submitting}
                    className="flex items-center gap-1.5 rounded-lg bg-purple-600 px-3 py-2 text-xs font-semibold text-white hover:bg-purple-700 disabled:opacity-60"
                  >
                    Make Admin
                  </button>
                )}
              </div>
            </div>
          ) : (
            <PortfolioQR uid={selected.uid} userName={selected.name} />
          )}
        </Modal>
      )}
    </div>
  )
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-400">{label}</p>
      <p className="font-medium text-gray-900 truncate">{value}</p>
    </div>
  )
}
