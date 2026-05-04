import { LucideIcon } from 'lucide-react'
import { cn } from '@/lib/utils'

interface StatCardProps {
  label: string
  value: string | number
  icon: LucideIcon
  change?: string
  changeType?: 'up' | 'down' | 'neutral'
  color?: 'blue' | 'green' | 'amber' | 'red' | 'purple'
}

const colorMap = {
  blue:   { bg: 'bg-blue-50',   icon: 'bg-blue-500',   text: 'text-blue-600' },
  green:  { bg: 'bg-green-50',  icon: 'bg-green-500',  text: 'text-green-600' },
  amber:  { bg: 'bg-amber-50',  icon: 'bg-amber-500',  text: 'text-amber-600' },
  red:    { bg: 'bg-red-50',    icon: 'bg-red-500',    text: 'text-red-600' },
  purple: { bg: 'bg-purple-50', icon: 'bg-purple-500', text: 'text-purple-600' },
}

export default function StatCard({
  label,
  value,
  icon: Icon,
  change,
  changeType = 'neutral',
  color = 'blue',
}: StatCardProps) {
  const colors = colorMap[color]
  return (
    <div className={cn('rounded-xl border border-gray-100 p-5', colors.bg)}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{label}</p>
          <p className="mt-1 text-2xl font-bold text-gray-900">{value}</p>
          {change && (
            <p
              className={cn(
                'mt-1 text-xs font-medium',
                changeType === 'up'   && 'text-green-600',
                changeType === 'down' && 'text-red-600',
                changeType === 'neutral' && 'text-gray-500',
              )}
            >
              {change}
            </p>
          )}
        </div>
        <div className={cn('rounded-lg p-2.5', colors.icon)}>
          <Icon size={20} className="text-white" />
        </div>
      </div>
    </div>
  )
}
