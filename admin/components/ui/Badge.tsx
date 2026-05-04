import { cn } from '@/lib/utils'

type BadgeVariant =
  | 'active' | 'inactive' | 'sold' | 'pending' | 'pending_review' | 'rejected'
  | 'admin' | 'broker' | 'viewer'
  | 'verified' | 'banned'
  | 'default'

const variantMap: Record<BadgeVariant, string> = {
  active:         'bg-green-100 text-green-800',
  inactive:       'bg-gray-100 text-gray-700',
  sold:           'bg-blue-100 text-blue-800',
  pending:        'bg-amber-100 text-amber-800',
  pending_review: 'bg-amber-100 text-amber-800',
  rejected:       'bg-red-100 text-red-800',
  admin:    'bg-purple-100 text-purple-800',
  broker:   'bg-navy-100 text-navy-800',
  viewer:   'bg-gray-100 text-gray-700',
  verified: 'bg-green-100 text-green-800',
  banned:   'bg-red-100 text-red-800',
  default:  'bg-gray-100 text-gray-700',
}

interface BadgeProps {
  variant?: BadgeVariant
  children: React.ReactNode
  className?: string
}

export default function Badge({ variant = 'default', children, className }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
        variantMap[variant],
        className,
      )}
    >
      {children}
    </span>
  )
}
