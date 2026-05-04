'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Header from '@/components/layout/Header'
import Badge from '@/components/ui/Badge'
import Modal from '@/components/ui/Modal'
import Spinner from '@/components/ui/Spinner'
import { Listing, ListingStatus } from '@/types'
import { formatDate, formatPrice } from '@/lib/utils'
import { CheckCircle, XCircle, ArrowLeft, ExternalLink } from 'lucide-react'
import Image from 'next/image'

export default function ListingDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const [listing, setListing]         = useState<Listing | null>(null)
  const [loading, setLoading]         = useState(true)
  const [rejectModal, setRejectModal] = useState(false)
  const [reason, setReason]           = useState('')
  const [submitting, setSubmitting]   = useState(false)
  const [message, setMessage]         = useState('')

  async function loadListing() {
    const res = await fetch(`/api/listings/${id}`)
    const data = await res.json()
    setListing(data.listing)
    setLoading(false)
  }

  useEffect(() => { loadListing() }, [id]) // eslint-disable-line

  async function updateStatus(status: ListingStatus, rejectionReason?: string) {
    setSubmitting(true)
    const res = await fetch(`/api/listings/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, rejectionReason }),
    })
    if (res.ok) {
      setMessage(status === 'active' ? 'Listing approved!' : `Listing ${status}.`)
      await loadListing()
      setRejectModal(false)
    } else {
      setMessage('Failed. Please try again.')
    }
    setSubmitting(false)
  }

  if (loading) {
    return <div className="flex h-64 items-center justify-center"><Spinner /></div>
  }

  if (!listing) {
    return <div className="text-center text-gray-400 py-20">Listing not found.</div>
  }

  return (
    <div>
      <button
        onClick={() => router.back()}
        className="mb-4 flex items-center gap-1 text-sm text-gray-500 hover:text-gray-800"
      >
        <ArrowLeft size={15} /> Back to listings
      </button>

      <Header
        title={`${listing.category} · ${listing.location}, ${listing.city}`}
        subtitle={`ID: ${listing.id}`}
        actions={
          <div className="flex items-center gap-2">
            {message && <span className="text-sm text-green-600">{message}</span>}
            {listing.status === 'pending_review' && (
              <>
                <button
                  onClick={() => updateStatus('active')}
                  disabled={submitting}
                  className="flex items-center gap-1.5 rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-60"
                >
                  <CheckCircle size={16} /> Approve
                </button>
                <button
                  onClick={() => setRejectModal(true)}
                  className="flex items-center gap-1.5 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700"
                >
                  <XCircle size={16} /> Reject
                </button>
              </>
            )}
            {listing.status === 'active' && (
              <button
                onClick={() => updateStatus('inactive')}
                disabled={submitting}
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-60"
              >
                Deactivate
              </button>
            )}
            {listing.status === 'inactive' && (
              <button
                onClick={() => updateStatus('active')}
                disabled={submitting}
                className="rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-60"
              >
                Reactivate
              </button>
            )}
          </div>
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Images */}
        <div className="lg:col-span-2 space-y-4">
          {listing.heroImageUrl && (
            <div className="relative aspect-video w-full overflow-hidden rounded-xl bg-gray-100">
              <Image src={listing.heroImageUrl} alt="Hero" fill className="object-cover" />
            </div>
          )}
          {listing.additionalImageUrls && listing.additionalImageUrls.length > 0 && (
            <div className="grid grid-cols-3 gap-2">
              {listing.additionalImageUrls.map((url, i) => (
                <div key={i} className="relative aspect-video overflow-hidden rounded-lg bg-gray-100">
                  <Image src={url} alt={`Image ${i + 1}`} fill className="object-cover" />
                </div>
              ))}
            </div>
          )}
          {listing.description && (
            <div className="rounded-xl border border-gray-100 bg-white p-5">
              <h3 className="mb-2 font-semibold text-gray-900">Description</h3>
              <p className="text-sm text-gray-600 whitespace-pre-wrap">{listing.description}</p>
            </div>
          )}
        </div>

        {/* Details panel */}
        <div className="space-y-4">
          <div className="rounded-xl border border-gray-100 bg-white p-5 space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-500">Status</span>
              <Badge variant={listing.status as ListingStatus}>{listing.status.replace('_', ' ')}</Badge>
            </div>
            <Detail label="Price"        value={formatPrice(listing.price)} />
            <Detail label="Area"         value={`${listing.area} ${listing.areaUnit}`} />
            <Detail label="Category"     value={listing.category} />
            <Detail label="Property Type" value={listing.propertyType ?? '—'} />
            <Detail label="Visibility"   value={listing.visibility} />
            <Detail label="Added"        value={listing.createdAt ? formatDate(listing.createdAt as { _seconds: number }) : '—'} />
            <Detail label="Views"        value={String(listing.viewsCount)} />
            <Detail label="Likes"        value={String(listing.likesCount)} />
            {listing.rejectionReason && (
              <div className="rounded-lg bg-red-50 p-3 text-xs text-red-700">
                <strong>Rejection reason:</strong> {listing.rejectionReason}
              </div>
            )}
          </div>

          <div className="rounded-xl border border-gray-100 bg-white p-5 space-y-3">
            <h3 className="font-semibold text-gray-900">Broker</h3>
            <Detail label="Name"  value={listing.brokerName} />
            <Detail label="Phone" value={listing.brokerPhone ?? '—'} />
            <a
              href={`/dashboard/users?uid=${listing.brokerUid}`}
              className="flex items-center gap-1 text-xs text-navy-600 hover:underline"
            >
              <ExternalLink size={12} /> View broker profile
            </a>
          </div>
        </div>
      </div>

      {/* Reject modal */}
      <Modal open={rejectModal} onClose={() => setRejectModal(false)} title="Reject Listing" size="sm">
        <div className="space-y-4">
          <p className="text-sm text-gray-500">Provide a reason (will be stored for reference):</p>
          <textarea
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-navy-500"
            placeholder="e.g. Incomplete information, blurry images…"
          />
          <div className="flex gap-2 justify-end">
            <button onClick={() => setRejectModal(false)} className="rounded-lg border border-gray-200 px-4 py-2 text-sm hover:bg-gray-50">
              Cancel
            </button>
            <button
              onClick={() => updateStatus('rejected', reason)}
              disabled={submitting}
              className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60"
            >
              {submitting ? 'Rejecting…' : 'Confirm Reject'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-gray-900">{value}</span>
    </div>
  )
}
