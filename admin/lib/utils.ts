import { type ClassValue, clsx } from 'clsx'
import { format, subDays, eachDayOfInterval } from 'date-fns'

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs)
}

export function formatPrice(price: number): string {
  if (price >= 10_000_000) return `₹${(price / 10_000_000).toFixed(2)} Cr`
  if (price >= 100_000)    return `₹${(price / 100_000).toFixed(2)} L`
  return `₹${price.toLocaleString('en-IN')}`
}

export function formatDate(date: Date | string | { _seconds: number }): string {
  if (typeof date === 'object' && '_seconds' in date) {
    return format(new Date(date._seconds * 1000), 'dd MMM yyyy')
  }
  return format(new Date(date as string | Date), 'dd MMM yyyy')
}

export function formatDateTime(date: Date | string | { _seconds: number }): string {
  if (typeof date === 'object' && '_seconds' in date) {
    return format(new Date(date._seconds * 1000), 'dd MMM yyyy, HH:mm')
  }
  return format(new Date(date as string | Date), 'dd MMM yyyy, HH:mm')
}

// Returns the last N days as 'YYYY-MM-DD' strings, oldest first.
export function lastNDays(n: number): string[] {
  const today = new Date()
  return eachDayOfInterval({ start: subDays(today, n - 1), end: today }).map(
    (d) => format(d, 'yyyy-MM-dd'),
  )
}

export function apiError(message: string, status = 500) {
  return Response.json({ error: message }, { status })
}
