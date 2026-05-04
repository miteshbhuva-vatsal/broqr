'use client'

import { useEffect, useState } from 'react'
import Header from '@/components/layout/Header'
import Modal from '@/components/ui/Modal'
import Spinner from '@/components/ui/Spinner'
import { Category, CategoryField } from '@/types'
import { Plus, Pencil, Trash2, GripVertical, ToggleLeft, ToggleRight } from 'lucide-react'

const FIELD_TYPES = ['text', 'number', 'select', 'boolean'] as const

const EMPTY_CATEGORY: Omit<Category, 'id'> = {
  name: '', emoji: '', label: '', isActive: true, sortOrder: 0, fields: [],
}

const EMPTY_FIELD: Omit<CategoryField, 'id'> = {
  label: '', type: 'text', options: [], required: false,
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading]       = useState(true)
  const [modal, setModal]           = useState<'create' | 'edit' | null>(null)
  const [form, setForm]             = useState<Omit<Category, 'id'>>(EMPTY_CATEGORY)
  const [editId, setEditId]         = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [newField, setNewField]     = useState<Omit<CategoryField, 'id'>>(EMPTY_FIELD)

  async function load() {
    setLoading(true)
    const res = await fetch('/api/categories')
    const data = await res.json()
    setCategories(data.categories ?? [])
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  async function save() {
    setSubmitting(true)
    const method = modal === 'create' ? 'POST' : 'PATCH'
    const url    = modal === 'create' ? '/api/categories' : `/api/categories/${editId}`
    await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    })
    await load()
    setModal(null)
    setSubmitting(false)
  }

  async function toggleActive(cat: Category) {
    await fetch(`/api/categories/${cat.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isActive: !cat.isActive }),
    })
    await load()
  }

  async function deleteCategory(id: string) {
    if (!confirm('Delete this category?')) return
    await fetch(`/api/categories/${id}`, { method: 'DELETE' })
    await load()
  }

  function addField() {
    if (!newField.label) return
    const field: CategoryField = { id: crypto.randomUUID(), ...newField }
    setForm((f) => ({ ...f, fields: [...f.fields, field] }))
    setNewField(EMPTY_FIELD)
  }

  function removeField(id: string) {
    setForm((f) => ({ ...f, fields: f.fields.filter((ff) => ff.id !== id) }))
  }

  function openCreate() {
    setForm(EMPTY_CATEGORY)
    setEditId(null)
    setModal('create')
  }

  function openEdit(cat: Category) {
    setForm({ name: cat.name, emoji: cat.emoji, label: cat.label, isActive: cat.isActive, sortOrder: cat.sortOrder, fields: cat.fields })
    setEditId(cat.id)
    setModal('edit')
  }

  return (
    <div>
      <Header
        title="Categories & Fields"
        subtitle="Manage listing categories and their custom fields"
        actions={
          <button
            onClick={openCreate}
            className="flex items-center gap-2 rounded-lg bg-navy-700 px-4 py-2 text-sm font-semibold text-white hover:bg-navy-600"
          >
            <Plus size={16} /> Add Category
          </button>
        }
      />

      {loading ? (
        <div className="flex h-40 items-center justify-center"><Spinner /></div>
      ) : (
        <div className="space-y-3">
          {categories.map((cat) => (
            <div key={cat.id} className="flex items-center gap-4 rounded-xl border border-gray-100 bg-white px-5 py-4 shadow-sm">
              <GripVertical size={16} className="cursor-grab text-gray-300" />
              <span className="text-2xl">{cat.emoji}</span>
              <div className="flex-1">
                <p className="font-semibold text-gray-900">{cat.label || cat.name}</p>
                <p className="text-xs text-gray-400">{cat.fields.length} custom fields</p>
              </div>
              <button onClick={() => toggleActive(cat)} className="text-gray-400 hover:text-navy-700">
                {cat.isActive ? <ToggleRight size={24} className="text-green-500" /> : <ToggleLeft size={24} />}
              </button>
              <button onClick={() => openEdit(cat)} className="rounded p-1.5 text-gray-400 hover:bg-gray-100 hover:text-navy-700">
                <Pencil size={15} />
              </button>
              <button onClick={() => deleteCategory(cat.id)} className="rounded p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600">
                <Trash2 size={15} />
              </button>
            </div>
          ))}
          {categories.length === 0 && (
            <div className="rounded-xl border border-dashed border-gray-200 py-16 text-center text-sm text-gray-400">
              No categories yet. Add your first one.
            </div>
          )}
        </div>
      )}

      <Modal open={!!modal} onClose={() => setModal(null)} title={modal === 'create' ? 'New Category' : 'Edit Category'} size="lg">
        <div className="space-y-4">
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="label">Emoji</label>
              <input className="input" placeholder="🏢" value={form.emoji} onChange={(e) => setForm({ ...form, emoji: e.target.value })} />
            </div>
            <div>
              <label className="label">Name (key)</label>
              <input className="input" placeholder="commercial" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            </div>
            <div>
              <label className="label">Display Label</label>
              <input className="input" placeholder="Commercial" value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} />
            </div>
          </div>

          {/* Custom Fields */}
          <div>
            <p className="mb-2 text-sm font-semibold text-gray-700">Custom Fields</p>
            <div className="space-y-2 mb-3">
              {form.fields.map((f) => (
                <div key={f.id} className="flex items-center gap-2 rounded-lg bg-gray-50 px-3 py-2">
                  <span className="flex-1 text-sm">{f.label} <span className="text-gray-400">({f.type})</span></span>
                  {f.required && <span className="text-xs text-amber-600">required</span>}
                  <button onClick={() => removeField(f.id)} className="text-red-400 hover:text-red-600"><Trash2 size={13} /></button>
                </div>
              ))}
            </div>
            <div className="flex items-center gap-2">
              <input
                className="input flex-1"
                placeholder="Field label"
                value={newField.label}
                onChange={(e) => setNewField({ ...newField, label: e.target.value })}
              />
              <select
                className="input w-28"
                value={newField.type}
                onChange={(e) => setNewField({ ...newField, type: e.target.value as CategoryField['type'] })}
              >
                {FIELD_TYPES.map((t) => <option key={t}>{t}</option>)}
              </select>
              <label className="flex items-center gap-1 text-xs text-gray-500 cursor-pointer">
                <input type="checkbox" checked={newField.required} onChange={(e) => setNewField({ ...newField, required: e.target.checked })} />
                Req.
              </label>
              <button onClick={addField} className="flex items-center gap-1 rounded-lg bg-gray-200 px-3 py-2 text-xs font-medium hover:bg-gray-300">
                <Plus size={13} /> Add
              </button>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-2 border-t border-gray-100">
            <button onClick={() => setModal(null)} className="rounded-lg border border-gray-200 px-4 py-2 text-sm hover:bg-gray-50">Cancel</button>
            <button onClick={save} disabled={submitting || !form.name} className="rounded-lg bg-navy-700 px-4 py-2 text-sm font-semibold text-white hover:bg-navy-600 disabled:opacity-60">
              {submitting ? 'Saving…' : 'Save'}
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
