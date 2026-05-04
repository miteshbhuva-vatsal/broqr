'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard,
  Building2,
  Users,
  Tag,
  CreditCard,
  BarChart3,
  MessageSquare,
  LogOut,
} from 'lucide-react'
import { cn } from '@/lib/utils'

const navItems = [
  { href: '/dashboard',               label: 'Dashboard',     icon: LayoutDashboard },
  { href: '/dashboard/listings',      label: 'Listings',      icon: Building2 },
  { href: '/dashboard/users',         label: 'Users',         icon: Users },
  { href: '/dashboard/categories',    label: 'Categories',    icon: Tag },
  { href: '/dashboard/subscriptions', label: 'Subscriptions', icon: CreditCard },
  { href: '/dashboard/analytics',     label: 'Analytics',     icon: BarChart3 },
  { href: '/dashboard/whatsapp',      label: 'WhatsApp',      icon: MessageSquare },
]

async function logout() {
  await fetch('/api/auth/session', { method: 'DELETE' })
  window.location.href = '/login'
}

export default function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="fixed inset-y-0 left-0 z-40 flex w-60 flex-col bg-navy-900 text-white">
      {/* Logo */}
      <div className="flex h-16 items-center gap-2 border-b border-navy-700 px-5">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-500 font-bold text-navy-900 text-sm">
          CP
        </div>
        <div>
          <p className="text-sm font-semibold leading-tight">CPApp</p>
          <p className="text-[10px] text-navy-100 opacity-60">Admin Panel</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        {navItems.map(({ href, label, icon: Icon }) => {
          const active =
            href === '/dashboard'
              ? pathname === '/dashboard'
              : pathname.startsWith(href)
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                active
                  ? 'bg-amber-500 text-navy-900'
                  : 'text-navy-100 hover:bg-navy-700 hover:text-white',
              )}
            >
              <Icon size={18} />
              {label}
            </Link>
          )
        })}
      </nav>

      {/* Logout */}
      <div className="border-t border-navy-700 p-3">
        <button
          onClick={logout}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-navy-100 transition-colors hover:bg-navy-700 hover:text-white"
        >
          <LogOut size={18} />
          Sign out
        </button>
      </div>
    </aside>
  )
}
