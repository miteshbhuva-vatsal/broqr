import { adminDb } from '@/lib/firebase-admin'
import { formatPrice } from '@/lib/utils'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { CheckCircle, MapPin, Phone, Building2 } from 'lucide-react'

export const dynamic = 'force-dynamic'

async function getData(uid: string) {
  const db = adminDb()
  const [userDoc, listingsSnap] = await Promise.all([
    db.collection('users').doc(uid).get(),
    db.collection('listings')
      .where('brokerUid', '==', uid)
      .where('status', '==', 'active')
      .orderBy('createdAt', 'desc')
      .get(),
  ])
  if (!userDoc.exists) return null
  return {
    user:     { uid, ...userDoc.data() } as Record<string, unknown>,
    listings: listingsSnap.docs.map((d) => ({ id: d.id, ...d.data() })) as Record<string, unknown>[],
  }
}

export default async function PortfolioPage({ params }: { params: Promise<{ uid: string }> }) {
  const { uid } = await params
  const data = await getData(uid)
  if (!data) notFound()

  const { user, listings } = data

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header bar */}
      <div className="bg-[#0A1628] px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-7 w-7 rounded-md bg-amber-500 flex items-center justify-center text-xs font-black text-[#0A1628]">CP</div>
          <span className="text-white text-sm font-semibold">CPApp</span>
        </div>
        <span className="text-xs text-white/50">Broker Portfolio</span>
      </div>

      {/* Broker card */}
      <div className="bg-white border-b border-gray-100 px-4 py-6">
        <div className="max-w-2xl mx-auto flex items-center gap-4">
          {user.photoUrl ? (
            <Image
              src={user.photoUrl as string}
              alt={user.name as string}
              width={72} height={72}
              className="rounded-full object-cover shrink-0 border-2 border-amber-400"
            />
          ) : (
            <div className="h-[72px] w-[72px] shrink-0 rounded-full bg-[#0A1628] flex items-center justify-center text-2xl font-black text-amber-400">
              {(user.name as string)?.[0]?.toUpperCase() ?? 'B'}
            </div>
          )}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-xl font-bold text-gray-900 truncate">{user.name as string}</h1>
              {user.isVerified && (
                <CheckCircle size={18} className="text-blue-500 shrink-0" />
              )}
            </div>
            {user.reraNumber && (
              <p className="text-xs text-gray-500 mt-0.5">RERA: {user.reraNumber as string}</p>
            )}
            <div className="flex items-center gap-3 mt-1 flex-wrap">
              {user.city && (
                <span className="flex items-center gap-1 text-xs text-gray-500">
                  <MapPin size={11} /> {user.city as string}
                </span>
              )}
              {user.mobile && (
                <a href={`tel:${user.mobile}`} className="flex items-center gap-1 text-xs text-amber-600 font-medium">
                  <Phone size={11} /> {user.mobile as string}
                </a>
              )}
            </div>
          </div>
          <div className="shrink-0 text-right">
            <p className="text-2xl font-black text-[#0A1628]">{listings.length}</p>
            <p className="text-xs text-gray-400">Active listings</p>
          </div>
        </div>
      </div>

      {/* Listings grid */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        {listings.length === 0 ? (
          <div className="text-center py-16 text-gray-400">
            <Building2 size={40} className="mx-auto mb-3 opacity-30" />
            <p className="text-sm">No active listings yet.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {listings.map((l) => (
              <ListingCard key={l.id as string} listing={l} />
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="text-center py-6 text-xs text-gray-400 border-t border-gray-100 bg-white">
        Powered by <span className="font-semibold text-[#0A1628]">CPApp</span> · Download the app to connect
      </div>
    </div>
  )
}

function ListingCard({ listing: l }: { listing: Record<string, unknown> }) {
  const price = typeof l.price === 'number' ? formatPrice(l.price) : '—'
  const origPrice = typeof l.originalPrice === 'number' && l.originalPrice > 0
    ? formatPrice(l.originalPrice) : null
  const area = l.area ? `${l.area} ${l.areaUnit ?? 'sqFt'}` : null

  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
      {l.heroImageUrl && (
        <div className="relative h-40 w-full bg-gray-100">
          <Image
            src={l.heroImageUrl as string}
            alt={l.category as string}
            fill
            className="object-cover"
            sizes="(max-width: 640px) 100vw, 50vw"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
          <span className="absolute bottom-2 left-2 rounded-full bg-amber-400 px-2 py-0.5 text-[10px] font-bold text-[#0A1628]">
            {l.category as string}
          </span>
        </div>
      )}
      <div className="p-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <p className="font-bold text-gray-900 text-sm">{price}</p>
            {origPrice && (
              <p className="text-xs text-gray-400 line-through">{origPrice}</p>
            )}
          </div>
          {area && <p className="text-xs text-gray-500 shrink-0">{area}</p>}
        </div>
        <p className="mt-1 text-xs text-gray-500 flex items-center gap-1">
          <MapPin size={10} />
          {l.location as string}, {l.city as string}
        </p>
        {l.description && (
          <p className="mt-1.5 text-xs text-gray-600 line-clamp-2">{l.description as string}</p>
        )}
      </div>
    </div>
  )
}
