import { cn } from '@/lib/utils'

export default function Spinner({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        'h-6 w-6 animate-spin rounded-full border-2 border-gray-200 border-t-navy-600',
        className,
      )}
    />
  )
}
