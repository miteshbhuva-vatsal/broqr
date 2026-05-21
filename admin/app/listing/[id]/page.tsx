import { adminDb } from '@/lib/firebase-admin'
import { formatPrice } from '@/lib/utils'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { MapPin, Maximize2, Building2, User } from 'lucide-react'
import { OpenInAppButton } from '@/components/OpenInAppButton'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

async function getListing(id: string) {
  const doc = await adminDb().collection('listings').doc(id).get()
  if (!doc.exists) return null
  return { id: doc.id, ...doc.data() } as Record<string, unknown>
}

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params
  const l = await getListing(id)
  if (!l) return { title: 'Listing not found' }
  const price = typeof l.price === 'number' ? formatPrice(l.price) : ''
  return {
    title: `${l.category ?? 'Property'} in ${l.city ?? ''} – ${price} | DigiProp`,
    description: `${l.location}, ${l.city}. ${price}. Shared via DigiProp.`,
    openGraph: {
      images: l.heroImageUrl ? [l.heroImageUrl as string] : [],
    },
  }
}

export default async function ListingPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const l = await getListing(id)
  if (!l) notFound()

  const price = typeof l.price === 'number' ? formatPrice(l.price) : '—'
  const origPrice = typeof l.originalPrice === 'number' && (l.originalPrice as number) > 0
    ? formatPrice(l.originalPrice as number) : null
  const area = l.area ? `${l.area} ${l.areaUnit ?? 'sq ft'}` : null
  const images = (l.images as string[] | undefined) ?? (l.heroImageUrl ? [l.heroImageUrl as string] : [])
  const deepLink = `cpapp://listing/${id}`
  const webLink = `https://www.digiprop.co.in/listing/${id}`

  return (
    <div className="min-h-screen bg-gray-50">
      {/* App bar */}
      <div className="bg-[#0A1628] px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-7 w-7 rounded-md bg-amber-500 flex items-center justify-center text-xs font-black text-[#0A1628]">DP</div>
          <span className="text-white text-sm font-semibold">DigiProp</span>
        </div>
        <span className="text-xs text-white/50">Property Detail</span>
      </div>

      {/* Hero image */}
      {images.length > 0 && (
        <div className="relative h-56 w-full bg-gray-200">
          <Image src={images[0]} alt="Property" fill className="object-cover" sizes="100vw" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
          <span className="absolute bottom-3 left-3 rounded-full bg-amber-400 px-3 py-1 text-xs font-bold text-[#0A1628]">
            {l.category as string}
          </span>
          {images.length > 1 && (
            <span className="absolute bottom-3 right-3 rounded-full bg-black/50 px-2 py-1 text-[10px] text-white">
              +{images.length - 1} photos
            </span>
          )}
        </div>
      )}

      {/* Property info */}
      <div className="bg-white border-b border-gray-100 px-4 py-5 max-w-2xl mx-auto">
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-baseline gap-2 flex-wrap">
              <span className="text-2xl font-black text-[#0A1628]">{price}</span>
              {origPrice && (
                <span className="text-sm text-gray-400 line-through">{origPrice}</span>
              )}
            </div>
            <div className="flex items-center gap-1 mt-1 text-gray-500 text-sm">
              <MapPin size={13} className="shrink-0 text-amber-500" />
              <span className="truncate">{l.location as string}, {l.city as string}</span>
            </div>
            {area && (
              <div className="flex items-center gap-1 mt-1 text-gray-500 text-sm">
                <Maximize2 size={13} className="shrink-0" />
                <span>{area}</span>
              </div>
            )}
          </div>
          {!((l.images as string[] | undefined)?.length) && (
            <div className="shrink-0 h-16 w-16 rounded-xl bg-amber-50 flex items-center justify-center">
              <Building2 size={28} className="text-amber-400" />
            </div>
          )}
        </div>

        {/* Broker */}
        {!!l.brokerName && (
          <div className="flex items-center gap-2 mt-4 pt-4 border-t border-gray-100">
            {!!l.brokerPhotoUrl ? (
              <Image src={l.brokerPhotoUrl as string} alt={l.brokerName as string} width={32} height={32} className="rounded-full object-cover" />
            ) : (
              <div className="h-8 w-8 rounded-full bg-[#0A1628] flex items-center justify-center">
                <User size={14} className="text-amber-400" />
              </div>
            )}
            <div>
              <p className="text-xs text-gray-400">Listed by</p>
              <p className="text-sm font-semibold text-gray-800">{l.brokerName as string}</p>
            </div>
          </div>
        )}
      </div>

      {/* Description */}
      {!!l.description && (
        <div className="bg-white mt-2 px-4 py-4 max-w-2xl mx-auto">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">About</p>
          <p className="text-sm text-gray-700 leading-relaxed line-clamp-4">{l.description as string}</p>
        </div>
      )}

      {/* CTA */}
      <div className="max-w-2xl mx-auto px-4 py-6 space-y-3">
        <OpenInAppButton deepLink={deepLink} webLink={webLink} label="Open in DigiProp App" />
        <p className="text-center text-xs text-gray-400">
          Don't have the app?{' '}
          <a href="https://play.google.com/store/apps/details?id=com.digiprop.cpapp" className="text-amber-600 font-medium underline">Download DigiProp</a>
        </p>
      </div>

      <div className="text-center py-4 text-xs text-gray-400 border-t border-gray-100 bg-white">
        Powered by <span className="font-semibold text-[#0A1628]">DigiProp</span>
      </div>
    </div>
  )
}
