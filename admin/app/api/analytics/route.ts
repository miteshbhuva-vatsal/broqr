import { NextRequest } from 'next/server'
import { adminDb } from '@/lib/firebase-admin'
import { verifySession } from '@/lib/auth'
import { apiError, lastNDays } from '@/lib/utils'
import { format, subDays, startOfDay } from 'date-fns'

export async function GET(req: NextRequest) {
  if (!await verifySession()) return apiError('Unauthorized', 401)

  const rangeParam = req.nextUrl.searchParams.get('range') ?? '30d'
  const days = rangeParam === '7d' ? 7 : rangeParam === '90d' ? 90 : 30

  const db  = adminDb()
  const now = new Date()
  const rangeStart = startOfDay(subDays(now, days - 1))
  const todayStart = startOfDay(now)
  const monthStart = startOfDay(subDays(now, 29))

  // Parallel: total counts, DAU (lastSeen today), MAU (lastSeen 30d)
  const [
    totalUsersSnap,
    totalListingsSnap,
    dauSnap,
    mauSnap,
    newUsersTodaySnap,
    newListingsTodaySnap,
    usersInRangeSnap,
    listingsInRangeSnap,
    appOpensSnap,
  ] = await Promise.all([
    db.collection('users').count().get(),
    db.collection('listings').count().get(),
    db.collection('users').where('lastSeen', '>=', todayStart).count().get(),
    db.collection('users').where('lastSeen', '>=', monthStart).count().get(),
    db.collection('users').where('createdAt', '>=', todayStart).count().get(),
    db.collection('listings').where('createdAt', '>=', todayStart).count().get(),
    db.collection('users').where('createdAt', '>=', rangeStart).get(),
    db.collection('listings').where('createdAt', '>=', rangeStart).get(),
    // Single-field query only — no composite index required; filter event in JS below
    db.collection('appEvents').where('timestamp', '>=', rangeStart).get(),
  ])

  // Build per-day buckets
  const dateLabels = lastNDays(days)
  const newUsersByDay: Record<string, number>   = Object.fromEntries(dateLabels.map((d) => [d, 0]))
  const newListingsByDay: Record<string, number> = Object.fromEntries(dateLabels.map((d) => [d, 0]))
  const appOpensByDay: Record<string, number>    = Object.fromEntries(dateLabels.map((d) => [d, 0]))
  const dauByDay: Record<string, Set<string>>    = Object.fromEntries(dateLabels.map((d) => [d, new Set<string>()]))

  for (const doc of usersInRangeSnap.docs) {
    const ts = doc.data().createdAt
    if (ts?._seconds) {
      const key = format(new Date(ts._seconds * 1000), 'yyyy-MM-dd')
      if (key in newUsersByDay) newUsersByDay[key]++
    }
  }

  for (const doc of listingsInRangeSnap.docs) {
    const ts = doc.data().createdAt
    if (ts?._seconds) {
      const key = format(new Date(ts._seconds * 1000), 'yyyy-MM-dd')
      if (key in newListingsByDay) newListingsByDay[key]++
    }
  }

  for (const doc of appOpensSnap.docs) {
    const data = doc.data()
    if (data.event !== 'app_open') continue
    const ts = data.timestamp
    if (ts?._seconds) {
      const key = format(new Date(ts._seconds * 1000), 'yyyy-MM-dd')
      if (key in appOpensByDay) {
        appOpensByDay[key]++
        if (data.uid) dauByDay[key].add(data.uid as string)
      }
    }
  }

  const dailySeries = dateLabels.map((date) => ({
    date,
    newUsers:    newUsersByDay[date]  ?? 0,
    newListings: newListingsByDay[date] ?? 0,
    appOpens:    appOpensByDay[date]  ?? 0,
    dau:         dauByDay[date].size,
  }))

  return Response.json({
    totalUsers:       totalUsersSnap.data().count,
    totalListings:    totalListingsSnap.data().count,
    dau:              dauSnap.data().count,
    mau:              mauSnap.data().count,
    newUsersToday:    newUsersTodaySnap.data().count,
    newListingsToday: newListingsTodaySnap.data().count,
    dailySeries,
  })
}
