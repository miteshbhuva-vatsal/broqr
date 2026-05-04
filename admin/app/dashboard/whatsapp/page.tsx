'use client'

import { useEffect, useState } from 'react'
import Header from '@/components/layout/Header'
import Modal from '@/components/ui/Modal'
import { WhatsAppTemplate } from '@/types'
import { Plus, Send, Pencil, ToggleLeft, ToggleRight, MessageSquare } from 'lucide-react'

const TRIGGERS = [
  { value: 'listing_approved',    label: 'Listing Approved' },
  { value: 'listing_rejected',    label: 'Listing Rejected' },
  { value: 'new_lead',            label: 'New CRM Lead' },
  { value: 'subscription_expiry', label: 'Subscription Expiry' },
  { value: 'manual',              label: 'Manual / Bulk Send' },
]

const VARS_HINT = '{{name}}, {{listing}}, {{city}}, {{price}}, {{reason}}'

const EMPTY_TMPL: Omit<WhatsAppTemplate, 'id'> = {
  name: '', body: '', trigger: 'manual', isActive: true,
}

export default function WhatsAppPage() {
  const [templates, setTemplates]   = useState<WhatsAppTemplate[]>([])
  const [modal, setModal]           = useState<'create' | 'edit' | 'send' | null>(null)
  const [form, setForm]             = useState<Omit<WhatsAppTemplate, 'id'>>(EMPTY_TMPL)
  const [editId, setEditId]         = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [sendForm, setSendForm]     = useState({ phone: '', templateId: '', vars: '' })
  const [apiConfig, setApiConfig]   = useState({ endpoint: '', token: '' })
  const [configSaved, setConfigSaved] = useState(false)
  const [sendResult, setSendResult] = useState('')

  async function load() {
    const res = await fetch('/api/whatsapp?type=templates')
    const data = await res.json()
    setTemplates(data.templates ?? [])
    setApiConfig({ endpoint: data.endpoint ?? '', token: '' })
  }

  useEffect(() => { load() }, [])

  async function saveTemplate() {
    setSubmitting(true)
    const method = modal === 'create' ? 'POST' : 'PATCH'
    const url    = modal === 'create' ? '/api/whatsapp' : `/api/whatsapp/${editId}`
    await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ...form, type: 'template' }),
    })
    await load()
    setModal(null)
    setSubmitting(false)
  }

  async function toggleTemplate(t: WhatsAppTemplate) {
    await fetch(`/api/whatsapp/${t.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'template', isActive: !t.isActive }),
    })
    await load()
  }

  async function sendMessage() {
    setSubmitting(true)
    setSendResult('')
    const res = await fetch('/api/whatsapp/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(sendForm),
    })
    const data = await res.json()
    setSendResult(res.ok ? '✅ Message sent!' : `❌ ${data.error}`)
    setSubmitting(false)
  }

  async function saveConfig() {
    await fetch('/api/whatsapp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'config', ...apiConfig }),
    })
    setConfigSaved(true)
    setTimeout(() => setConfigSaved(false), 2000)
  }

  function openCreate() {
    setForm(EMPTY_TMPL)
    setEditId(null)
    setModal('create')
  }

  function openEdit(t: WhatsAppTemplate) {
    setForm({ name: t.name, body: t.body, trigger: t.trigger, isActive: t.isActive })
    setEditId(t.id)
    setModal('edit')
  }

  return (
    <div>
      <Header
        title="WhatsApp Alerts"
        subtitle="Configure auto-alert templates via WATI API"
        actions={
          <div className="flex gap-2">
            <button
              onClick={() => setModal('send')}
              className="flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-50"
            >
              <Send size={15} /> Send Test
            </button>
            <button
              onClick={openCreate}
              className="flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700"
            >
              <Plus size={16} /> New Template
            </button>
          </div>
        }
      />

      {/* API Config */}
      <div className="mb-6 rounded-xl border border-amber-200 bg-amber-50 p-5">
        <h3 className="mb-3 font-semibold text-amber-900">WATI API Configuration</h3>
        <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
          <div>
            <label className="mb-1 block text-xs font-semibold text-amber-800">API Endpoint</label>
            <input
              className="w-full rounded-lg border border-amber-200 bg-white px-3 py-2 text-sm outline-none focus:border-amber-400"
              placeholder="https://live-mt-server.wati.io/YOUR_ACCOUNT_ID"
              value={apiConfig.endpoint}
              onChange={(e) => setApiConfig({ ...apiConfig, endpoint: e.target.value })}
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold text-amber-800">API Token</label>
            <input
              type="password"
              className="w-full rounded-lg border border-amber-200 bg-white px-3 py-2 text-sm outline-none focus:border-amber-400"
              placeholder="Bearer token from WATI dashboard"
              value={apiConfig.token}
              onChange={(e) => setApiConfig({ ...apiConfig, token: e.target.value })}
            />
          </div>
        </div>
        <button
          onClick={saveConfig}
          className="mt-3 rounded-lg bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600"
        >
          {configSaved ? '✓ Saved' : 'Save Config'}
        </button>
        <p className="mt-2 text-xs text-amber-700">
          Token is encrypted and stored in Firestore. Available variables: {VARS_HINT}
        </p>
      </div>

      {/* Templates */}
      <div className="space-y-3">
        <h2 className="font-semibold text-gray-800">Message Templates</h2>
        {templates.map((t) => (
          <div key={t.id} className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <MessageSquare size={16} className="text-green-600" />
                  <span className="font-semibold text-gray-900">{t.name}</span>
                  <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-600">
                    {TRIGGERS.find((tr) => tr.value === t.trigger)?.label ?? t.trigger}
                  </span>
                </div>
                <p className="mt-2 text-sm text-gray-600 whitespace-pre-wrap bg-gray-50 rounded-lg p-3">
                  {t.body}
                </p>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <button onClick={() => toggleTemplate(t)} className="text-gray-400 hover:text-navy-700">
                  {t.isActive ? <ToggleRight size={22} className="text-green-500" /> : <ToggleLeft size={22} />}
                </button>
                <button onClick={() => openEdit(t)} className="rounded p-1.5 text-gray-400 hover:bg-gray-100 hover:text-navy-700">
                  <Pencil size={15} />
                </button>
              </div>
            </div>
          </div>
        ))}
        {templates.length === 0 && (
          <div className="rounded-xl border border-dashed border-gray-200 py-16 text-center text-sm text-gray-400">
            No templates yet. Create your first WhatsApp alert template.
          </div>
        )}
      </div>

      {/* Template modal */}
      <Modal open={modal === 'create' || modal === 'edit'} onClose={() => setModal(null)} title={modal === 'create' ? 'New Template' : 'Edit Template'}>
        <div className="space-y-4">
          <div>
            <label className="label">Template Name</label>
            <input className="input" placeholder="e.g. Listing Approved Alert" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </div>
          <div>
            <label className="label">Trigger</label>
            <select className="input" value={form.trigger} onChange={(e) => setForm({ ...form, trigger: e.target.value as WhatsAppTemplate['trigger'] })}>
              {TRIGGERS.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
          </div>
          <div>
            <label className="label">Message Body</label>
            <textarea
              rows={5}
              className="input"
              placeholder={`Hi {{name}}, your listing in {{city}} has been approved!\n\nAvailable: ${VARS_HINT}`}
              value={form.body}
              onChange={(e) => setForm({ ...form, body: e.target.value })}
            />
            <p className="mt-1 text-xs text-gray-400">Variables: {VARS_HINT}</p>
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" id="tmplActive" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />
            <label htmlFor="tmplActive" className="text-sm text-gray-700">Active (auto-send on trigger)</label>
          </div>
          <div className="flex justify-end gap-2 border-t border-gray-100 pt-4">
            <button onClick={() => setModal(null)} className="rounded-lg border border-gray-200 px-4 py-2 text-sm hover:bg-gray-50">Cancel</button>
            <button onClick={saveTemplate} disabled={submitting || !form.name || !form.body} className="rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-60">
              {submitting ? 'Saving…' : 'Save Template'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Send test modal */}
      <Modal open={modal === 'send'} onClose={() => setModal(null)} title="Send WhatsApp Message" size="sm">
        <div className="space-y-4">
          <div>
            <label className="label">Phone Number (with country code)</label>
            <input className="input" placeholder="+919876543210" value={sendForm.phone} onChange={(e) => setSendForm({ ...sendForm, phone: e.target.value })} />
          </div>
          <div>
            <label className="label">Template</label>
            <select className="input" value={sendForm.templateId} onChange={(e) => setSendForm({ ...sendForm, templateId: e.target.value })}>
              <option value="">Select template…</option>
              {templates.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
          </div>
          <div>
            <label className="label">Variables (JSON)</label>
            <input className="input" placeholder='{"name":"Mitesh","city":"Mumbai"}' value={sendForm.vars} onChange={(e) => setSendForm({ ...sendForm, vars: e.target.value })} />
          </div>
          {sendResult && <div className="text-sm font-medium">{sendResult}</div>}
          <div className="flex justify-end gap-2 border-t border-gray-100 pt-4">
            <button onClick={() => setModal(null)} className="rounded-lg border border-gray-200 px-4 py-2 text-sm hover:bg-gray-50">Cancel</button>
            <button onClick={sendMessage} disabled={submitting || !sendForm.phone || !sendForm.templateId}
              className="flex items-center gap-1.5 rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-60">
              <Send size={14} /> {submitting ? 'Sending…' : 'Send'}
            </button>
          </div>
        </div>
      </Modal>

      <style jsx>{`
        .input { @apply w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-green-500; }
        .label { @apply mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-500; }
      `}</style>
    </div>
  )
}
