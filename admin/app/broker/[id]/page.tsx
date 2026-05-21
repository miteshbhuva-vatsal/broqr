import { adminDb } from '@/lib/firebase-admin'
import { formatPrice } from '@/lib/utils'
import Image from 'next/image'
import { notFound } from 'next/navigation'
import { MapPin, Phone, CheckCircle, Building2, User } from 'lucide-react'
import { OpenInAppButton } from '@/components/OpenInAppButton'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

async function getData(id: string) {
  const db = adminDb()
  const [userDoc, listingsSnap] = await Promise.all([
    db.collection('users').doc(id).get(),
    db.collection('listings')
      .where('brokerUid', '==', id)
      .where('status', '==', 'active')
      .orderBy('createdAt', 'desc')
      .limit(6)
      .get(),
  ])
  if (!userDoc.exists) return null
  return {
    user: { uid: id, ...userDoc.data() } as Record<string, unknown>,
    listings: listingsSnap.docs.map((d) => ({ id: d.id, ...d.data() })) as Record<string, unknown>[],
  }
}

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params
  const data = await getData(id)
  if (!data) return { title: 'Broker not found' }
  const { user } = data
  return {
    title: `${user.name ?? 'Broker'} – Real Estate Agent | DigiProp`,
    description: `Connect with ${user.name} on DigiProp.${user.city ? ` Based in ${user.city}.` : ''}`,
    openGraph: {
      images: user.photoUrl ? [user.photoUrl as string] : [],
    },
  }
}

export default async function BrokerPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const data = await getData(id)
  if (!data) notFound()

  const { user, listings } = data
  const deepLink = `cpapp://broker/${id}`
  const webLink = `https://www.digiprop.co.in/broker/${id}`

  return (
    <div className="min-h-screen bg-gray-50">
      {/* App bar */}
      <div className="bg-[#0A1628] px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-7 w-7 rounded-md bg-amber-500 flex items-center justify-center text-xs font-black text-[#0A1628]">DP</div>
          <span className="text-white text-sm font-semibold">DigiProp</span>
        </div>
        <span className="text-xs text-white/50">Broker Profile</span>
      </div>

      {/* Broker card */}
      <div className="bg-white border-b border-gray-100 px-4 py-6">
        <div className="max-w-2xl mx-auto flex items-center gap-4">
          {user.photoUrl ? (
            <Image src={user.photoUrl as string} alt={user.name as string} width={72} height={72}
              className="rounded-full object-cover shrink-0 border-2 border-amber-400" />
          ) : (
            <div className="h-[72px] w-[72px] shrink-0 rounded-full bg-[#0A1628] flex items-center justify-center">
              <User size={32} className="text-amber-400" />
            </div>
          )}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-xl font-bold text-gray-900 truncate">{user.name as string}</h1>
              {!!user.isVerified && <CheckCircle size={18} className="text-blue-500 shrink-0" />}
            </div>
            {!!user.reraNumber && (
              <p className="text-xs text-gray-500 mt-0.5">RERA: {user.reraNumber as string}</p>
            )}
            <div className="flex items-center gap-3 mt-1 flex-wrap">
              {!!user.city && (
                <span className="flex items-center gap-1 text-xs text-gray-500">
                  <MapPin size={11} /> {user.city as string}
                </span>
              )}
              {!!user.mobile && (
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

      {/* CTA */}
      <div className="max-w-2xl mx-auto px-4 pt-5 pb-2 space-y-3">
        <OpenInAppButton deepLink={deepLink} webLink={webLink} label="Connect on DigiProp App" />
        <p className="text-center text-xs text-gray-400">
          Don't have the app?{' '}
          <a href="https://play.google.com/store/apps/details?id=com.digiprop.cpapp" className="text-amber-600 font-medium underline">Download DigiProp</a>
        </p>
      </div>

      {/* Listings */}
      <div className="max-w-2xl mx-auto px-4 py-4">
        {listings.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <Building2 size={36} className="mx-auto mb-2 opacity-30" />
            <p className="text-sm">No active listings yet.</p>
          </div>
        ) : (
          <>
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Active Listings</p>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {listings.map((l) => {
                const price = typeof l.price === 'number' ? formatPrice(l.price) : '—'
                return (
                  <div key={l.id as string} className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
                    {!!l.heroImageUrl && (
                      <div className="relative h-36 w-full bg-gray-100">
                        <Image src={l.heroImageUrl as string} alt={l.category as string} fill className="object-cover" sizes="(max-width:640px) 100vw, 50vw" />
                        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
                        <span className="absolute bottom-2 left-2 rounded-full bg-amber-400 px-2 py-0.5 text-[10px] font-bold text-[#0A1628]">
                          {l.category as string}
                        </span>
                      </div>
                    )}
                    <div className="p-3">
                      <p className="font-bold text-gray-900 text-sm">{price}</p>
                      <p className="text-xs text-gray-500 mt-0.5 truncate">{l.location as string}, {l.city as string}</p>
                    </div>
                  </div>
                )
              })}
            </div>
          </>
        )}
      </div>

      <div className="text-center py-6 text-xs text-gray-400 border-t border-gray-100 bg-white mt-4">
        Powered by <span className="font-semibold text-[#0A1628]">DigiProp</span>
      </div>
    </div>
  )
}
