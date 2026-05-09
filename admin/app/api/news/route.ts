import { NextRequest } from 'next/server'

// Add SERPAPI_KEY to .env.local:  SERPAPI_KEY=your_key_here
const SERPAPI_KEY = process.env.SERPAPI_KEY ?? ''

interface SerpApiSource {
  name?: string
  icon?: string
}

interface SerpApiArticle {
  title?: string
  link?: string
  source?: SerpApiSource
  thumbnail?: string
  thumbnail_small?: string
  iso_date?: string
  date?: string
  story_token?: string
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url)
  const q    = searchParams.get('q')?.trim() ?? ''
  const hl   = searchParams.get('hl') ?? 'en'
  const lang = hl === 'gu' ? 'gu' : hl === 'hi' ? 'hi' : 'en'

  if (!SERPAPI_KEY) {
    return Response.json(
      { error: 'SERPAPI_KEY not configured on server' },
      { status: 500 },
    )
  }

  if (!q) {
    return Response.json({ articles: [] })
  }

  const url = new URL('https://serpapi.com/search')
  url.searchParams.set('engine', 'google_news')
  url.searchParams.set('q', q)
  url.searchParams.set('gl', 'IN')
  url.searchParams.set('hl', lang)
  url.searchParams.set('num', '20')
  url.searchParams.set('api_key', SERPAPI_KEY)

  let serpData: { news_results?: SerpApiArticle[] }
  try {
    const res = await fetch(url.toString(), {
      // Next.js ISR: cache each unique query for 3 hours server-side
      next: { revalidate: 10800 },
    })
    if (!res.ok) {
      console.error('[news] SerpAPI error', res.status, await res.text())
      return Response.json({ articles: [] }, { status: 200 })
    }
    serpData = await res.json()
  } catch (err) {
    console.error('[news] fetch failed', err)
    return Response.json({ articles: [] }, { status: 200 })
  }

  const raw: SerpApiArticle[] = serpData.news_results ?? []

  const articles = raw
    .map((item) => ({
      id:          item.link ?? item.title ?? '',
      title:       item.title ?? '',
      link:        item.link ?? '',
      source:      item.source?.name ?? 'Google News',
      imageUrl:    item.thumbnail ?? item.thumbnail_small ?? null,
      publishedAt: item.iso_date ?? null,
    }))
    .filter((a) => a.title && a.link)

  return Response.json(
    { articles },
    {
      headers: {
        // Client-side cache: 1 hour fresh, 30 min stale-while-revalidate
        'Cache-Control': 'public, max-age=3600, stale-while-revalidate=1800',
        'Access-Control-Allow-Origin': '*',
      },
    },
  )
}
