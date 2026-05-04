'use client'

import { useEffect, useState } from 'react'
import Header from '@/components/layout/Header'
import DataTable, { Column } from '@/components/ui/DataTable'
import Modal from '@/components/ui/Modal'
import Badge from '@/components/ui/Badge'
import { SubscriptionPlan, UserSubscription } from '@/types'
import { formatDate, formatPrice } from '@/lib/utils'
import { Plus, Pencil, Trash2 } from 'lucide-react'

const EMPTY_PLAN: Omit<SubscriptionPlan, 'id'> = {
  name: '', price: 0, durationDays: 30, maxListings: 10,
  features: [], isActive: true, sortOrder: 0,
}

export default function SubscriptionsPage() {
  const [plans, setPlans]               = useState<SubscriptionPlan[]>([])
  const [subs, setSubs]                 = useState<UserSubscription[]>([])
  const [loading, setLoading]           = useState(true)
  const [modal, setModal]               = useState<'create' | 'edit' | null>(null)
  const [form, setForm]                 = useState<Omit<SubscriptionPlan, 'id'>>(EMPTY_PLAN)
  const [editId, setEditId]             = useState<string | null>(null)
  const [featInput, setFeatInput]       = useState('')
  const [submitting, setSubmitting]     = useState(false)
  const [tab, setTab]                   = useState<'plans' | 'subscribers'>('plans')

  async function load() {
    setLoading(true)
    const [plansRes, subsRes] = await Promise.all([
      fetch('/api/subscriptions?type=plans'),
      fetch('/api/subscriptions?type=subscribers'),
    ])
    const plansData = await plansRes.json()
    const subsData  = await subsRes.json()
    setPlans(plansData.plans ?? [])
    setSubs(subsData.subscriptions ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  async function savePlan() {
    setSubmitting(true)
    const method = modal === 'create' ? 'POST' : 'PATCH'
    const url    = modal === 'create' ? '/api/subscriptions' : `/api/subscriptions/${editId}`
    await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...form, type: 'plan' }),
    })
    await load()
    setModal(null)
    setSubmitting(false)
  }

  async function deletePlan(id: string) {
    if (!confirm('Delete this plan?')) return
    await fetch(`/api/subscriptions/${id}`, { method: 'DELETE' })
    await load()
  }

  function openCreate() {
    setForm(EMPTY_PLAN)
    setEditId(null)
    setModal('create')
  }

  function openEdit(plan: SubscriptionPlan) {
    setForm({ name: plan.name, price: plan.price, durationDays: plan.durationDays, maxListings: plan.maxListings, features: plan.features, isActive: plan.isActive, sortOrder: plan.sortOrder })
    setEditId(plan.id)
    setModal('edit')
  }

  const subColumns: Column<UserSubscription>[] = [
    { key: 'user',   header: 'User',   render: (s) => <span className="font-medium">{s.userName}</span> },
    { key: 'plan',   header: 'Plan',   render: (s) => <span>{s.planName}</span>, width: '120px' },
    { key: 'amount', header: 'Paid',   render: (s) => <span>{formatPrice(s.amountPaid)}</span>, width: '100px' },
    { key: 'start',  header: 'Start',  render: (s) => <span className="text-gray-500">{formatDate(s.startDate as { _seconds: number })}</span>, width: '110px' },
    { key: 'end',    header: 'Expires',render: (s) => <span className="text-gray-500">{formatDate(s.endDate as { _seconds: number })}</span>, width: '110px' },
    { key: 'active', header: 'Status', render: (s) => <Badge variant={s.isActive ? 'active' : 'inactive'}>{s.isActive ? 'Active' : 'Expired'}</Badge>, width: '80px' },
  ]

  return (
    <div>
      <Header
        title="Subscriptions"
        subtitle="Manage subscription plans and user subscriptions"
        actions={
          tab === 'plans' ? (
            <button onClick={openCreate} className="flex items-center gap-2 rounded-lg bg-navy-700 px-4 py-2 text-sm font-semibold text-white hover:bg-navy-600">
              <Plus size={16} /> New Plan
            </button>
          ) : undefined
        }
      />

      {/* Tabs */}
      <div className="mb-5 flex gap-1 border-b border-gray-200">
        {(['plans', 'subscribers'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 text-sm font-medium border-b-2 transition ${tab === t ? 'border-navy-700 text-navy-700' : 'border-transparent text-gray-500 hover:text-gray-800'}`}
          >
            {t === 'plans' ? 'Subscription Plans' : 'Subscribers'}
          </button>
        ))}
      </div>

      {tab === 'plans' && (
        <div className="space-y-3">
          {plans.map((plan) => (
            <div key={plan.id} className="flex items-start gap-5 rounded-xl border border-gray-100 bg-white px-5 py-4 shadow-sm">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold text-gray-900">{plan.name}</h3>
                  <Badge variant={plan.isActive ? 'active' : 'inactive'}>{plan.isActive ? 'Active' : 'Inactive'}</Badge>
                </div>
                <p className="text-sm text-gray-500 mt-0.5">
                  {formatPrice(plan.price)} · {plan.durationDays} days · {plan.maxListings} listings
                </p>
                {plan.features.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1">
                    {plan.features.map((f, i) => (
                      <span key={i} className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-600">{f}</span>
                    ))}
                  </div>
                )}
              </div>
              <div className="flex gap-2">
                <button onClick={() => openEdit(plan)} className="rounded p-1.5 text-gray-400 hover:bg-gray-100 hover:text-navy-700"><Pencil size={15} /></button>
                <button onClick={() => deletePlan(plan.id)} className="rounded p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600"><Trash2 size={15} /></button>
              </div>
            </div>
          ))}
          {plans.length === 0 && !loading && (
            <div className="rounded-xl border border-dashed border-gray-200 py-16 text-center text-sm text-gray-400">
              No plans yet. Create your first subscription plan.
            </div>
          )}
        </div>
      )}

      {tab === 'subscribers' && (
        <DataTable
          columns={subColumns}
          data={subs}
          loading={loading}
          keyExtractor={(s) => s.id}
          searchable
          searchKeys={['userName', 'planName']}
          emptyMessage="No active subscriptions."
        />
      )}

      {/* Plan modal */}
      <Modal open={!!modal} onClose={() => setModal(null)} title={modal === 'create' ? 'New Plan' : 'Edit Plan'}>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div className="col-span-2">
              <label className="label">Plan Name</label>
              <input className="input" placeholder="e.g. Pro, Starter…" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            </div>
            <div>
              <label className="label">Price (₹)</label>
              <input type="number" className="input" value={form.price} onChange={(e) => setForm({ ...form, price: Number(e.target.value) })} />
            </div>
            <div>
              <label className="label">Duration (days)</label>
              <input type="number" className="input" value={form.durationDays} onChange={(e) => setForm({ ...form, durationDays: Number(e.target.value) })} />
            </div>
            <div>
              <label className="label">Max Listings</label>
              <input type="number" className="input" value={form.maxListings} onChange={(e) => setForm({ ...form, maxListings: Number(e.target.value) })} />
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" id="isActive" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />
              <label htmlFor="isActive" className="text-sm text-gray-700">Active</label>
            </div>
          </div>

          <div>
            <label className="label">Features</label>
            <div className="flex gap-2 mb-2">
              <input className="input flex-1" placeholder="Add feature…" value={featInput} onChange={(e) => setFeatInput(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') { setForm((f) => ({ ...f, features: [...f.features, featInput] })); setFeatInput('') } }} />
              <button onClick={() => { setForm((f) => ({ ...f, features: [...f.features, featInput] })); setFeatInput('') }}
                className="rounded-lg bg-gray-200 px-3 py-2 text-xs hover:bg-gray-300">Add</button>
            </div>
            <div className="flex flex-wrap gap-1">
              {form.features.map((f, i) => (
                <span key={i} className="flex items-center gap-1 rounded-full bg-gray-100 px-2 py-0.5 text-xs">
                  {f}
                  <button onClick={() => setForm((prev) => ({ ...prev, features: prev.features.filter((_, j) => j !== i) }))} className="text-gray-400 hover:text-red-500">×</button>
                </span>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-2 border-t border-gray-100 pt-4">
            <button onClick={() => setModal(null)} className="rounded-lg border border-gray-200 px-4 py-2 text-sm hover:bg-gray-50">Cancel</button>
            <button onClick={savePlan} disabled={submitting || !form.name} className="rounded-lg bg-navy-700 px-4 py-2 text-sm font-semibold text-white hover:bg-navy-600 disabled:opacity-60">
              {submitting ? 'Saving…' : 'Save Plan'}
            </button>
          </div>
        </div>
      </Modal>

      <style jsx>{`
        .input { @apply w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-navy-500; }
        .label { @apply mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500; }
      `}</style>
    </div>
  )
}
