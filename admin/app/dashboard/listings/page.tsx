'use client'

import { useEffect, useState } from 'react'
import Header from '@/components/layout/Header'
import DataTable, { Column } from '@/components/ui/DataTable'
import Badge from '@/components/ui/Badge'
import { Listing, ListingStatus } from '@/types'
import { formatDate, formatPrice } from '@/lib/utils'
import Link from 'next/link'
import { Eye, Filter } from 'lucide-react'

const STATUS_FILTERS: { label: string; value: string }[] = [
  { label: 'All',            value: '' },
  { label: 'Pending Review', value: 'pending_review' },
  { label: 'Active',         value: 'active' },
  { label: 'Inactive',       value: 'inactive' },
  { label: 'Sold',           value: 'sold' },
  { label: 'Rejected',       value: 'rejected' },
]

export default function ListingsPage() {
  const [listings, setListings] = useState<Listing[]>([])
  const [loading, setLoading]   = useState(true)
  const [status, setStatus]     = useState('')

  async function load() {
    setLoading(true)
    const qs = status ? `?status=${status}` : ''
    const res = await fetch(`/api/listings${qs}`)
    const data = await res.json()
    setListings(data.listings ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [status]) // eslint-disable-line

  const columns: Column<Listing>[] = [
    {
      key: 'listing',
      header: 'Listing',
      render: (l) => (
        <div>
          <p className="font-medium text-gray-900 line-clamp-1">{l.category} · {l.location}</p>
          <p className="text-xs text-gray-400">{l.city}</p>
        </div>
      ),
    },
    {
      key: 'broker',
      header: 'Broker',
      render: (l) => (
        <div>
          <p className="text-sm">{l.brokerName}</p>
          <p className="text-xs text-gray-400">{l.brokerPhone}</p>
        </div>
      ),
    },
    {
      key: 'price',
      header: 'Price',
      render: (l) => <span className="font-medium">{formatPrice(l.price)}</span>,
      width: '110px',
    },
    {
      key: 'status',
      header: 'Status',
      render: (l) => <Badge variant={l.status as ListingStatus}>{l.status.replace('_', ' ')}</Badge>,
      width: '120px',
    },
    {
      key: 'date',
      header: 'Added',
      render: (l) => <span className="text-gray-500">{l.createdAt ? formatDate(l.createdAt as { _seconds: number }) : '—'}</span>,
      width: '110px',
    },
    {
      key: 'actions',
      header: '',
      render: (l) => (
        <Link
          href={`/dashboard/listings/${l.id}`}
          className="flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium text-navy-700 hover:bg-navy-50"
        >
          <Eye size={13} /> Review
        </Link>
      ),
      width: '80px',
    },
  ]

  return (
    <div>
      <Header title="Listings" subtitle="Review and manage all property listings" />

      {/* Filter bar */}
      <div className="mb-4 flex items-center gap-2">
        <Filter size={15} className="text-gray-400" />
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setStatus(f.value)}
            className={`rounded-full px-3 py-1 text-xs font-medium transition ${
              status === f.value
                ? 'bg-navy-700 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={listings}
        loading={loading}
        keyExtractor={(l) => l.id}
        searchable
        searchKeys={['brokerName', 'city', 'location', 'category']}
        emptyMessage="No listings found."
      />
    </div>
  )
}
