import { adminDb } from '@/lib/firebase-admin'
import { notFound } from 'next/navigation'
import Image from 'next/image'
import { MessageCircle, Heart, User } from 'lucide-react'
import { OpenInAppButton } from '@/components/OpenInAppButton'
import type { Metadata } from 'next'

export const dynamic = 'force-dynamic'

async function getPost(id: string) {
  const doc = await adminDb().collection('posts').doc(id).get()
  if (!doc.exists) return null
  return { id: doc.id, ...doc.data() } as Record<string, unknown>
}

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params
  const post = await getPost(id)
  if (!post) return { title: 'Post not found' }
  const preview = (post.text as string)?.slice(0, 120)
  return {
    title: `${post.authorName ?? 'Broker'} on DigiProp Community`,
    description: preview,
    openGraph: {
      images: post.imageUrl ? [post.imageUrl as string] : [],
    },
  }
}

export default async function PostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const post = await getPost(id)
  if (!post) notFound()

  const deepLink = `cpapp://post/${id}`
  const webLink = `https://www.digiprop.co.in/post/${id}`

  return (
    <div className="min-h-screen bg-gray-50">
      {/* App bar */}
      <div className="bg-[#0A1628] px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="h-7 w-7 rounded-md bg-amber-500 flex items-center justify-center text-xs font-black text-[#0A1628]">DP</div>
          <span className="text-white text-sm font-semibold">DigiProp</span>
        </div>
        <span className="text-xs text-white/50">Community</span>
      </div>

      {/* Post card */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          {/* Author */}
          <div className="flex items-center gap-3 px-4 pt-4 pb-3">
            {!!post.authorPhotoUrl ? (
              <Image src={post.authorPhotoUrl as string} alt={post.authorName as string}
                width={40} height={40} className="rounded-full object-cover border border-amber-200" />
            ) : (
              <div className="h-10 w-10 rounded-full bg-[#0A1628] flex items-center justify-center">
                <User size={18} className="text-amber-400" />
              </div>
            )}
            <div>
              <p className="font-semibold text-gray-900 text-sm">{post.authorName as string}</p>
              <p className="text-xs text-gray-400">DigiProp Community</p>
            </div>
          </div>

          {/* Post image */}
          {!!post.imageUrl && (
            <div className="relative w-full bg-gray-100" style={{ aspectRatio: '4/5' }}>
              <Image src={post.imageUrl as string} alt="Post" fill className="object-cover" sizes="(max-width:640px) 100vw, 640px" />
            </div>
          )}

          {/* Post text */}
          {!!post.text && (
            <div className="px-4 py-4">
              <p className="text-gray-800 text-sm leading-relaxed whitespace-pre-wrap">{post.text as string}</p>
            </div>
          )}

          {/* Counts */}
          <div className="flex items-center gap-4 px-4 pb-4 border-t border-gray-100 pt-3">
            <span className="flex items-center gap-1 text-xs text-gray-500">
              <Heart size={13} className="text-red-400" /> {(post.likesCount as number) ?? 0}
            </span>
            <span className="flex items-center gap-1 text-xs text-gray-500">
              <MessageCircle size={13} className="text-gray-400" /> {(post.commentsCount as number) ?? 0}
            </span>
          </div>
        </div>

        {/* CTA */}
        <div className="mt-5 space-y-3">
          <OpenInAppButton deepLink={deepLink} webLink={webLink} label="Open in DigiProp App" />
          <p className="text-center text-xs text-gray-400">
            Don't have the app?{' '}
            <a href="https://play.google.com/store/apps/details?id=com.digiprop.cpapp" className="text-amber-600 font-medium underline">Download DigiProp</a>
          </p>
        </div>
      </div>

      <div className="text-center py-4 text-xs text-gray-400 border-t border-gray-100 bg-white">
        Powered by <span className="font-semibold text-[#0A1628]">DigiProp</span>
      </div>
    </div>
  )
}
