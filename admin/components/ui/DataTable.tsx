'use client'

import { useState } from 'react'
import { Search, ChevronLeft, ChevronRight } from 'lucide-react'
import Spinner from './Spinner'

export interface Column<T> {
  key: string
  header: string
  render: (row: T) => React.ReactNode
  width?: string
}

interface DataTableProps<T> {
  columns: Column<T>[]
  data: T[]
  loading?: boolean
  keyExtractor: (row: T) => string
  searchable?: boolean
  searchKeys?: (keyof T)[]
  pageSize?: number
  emptyMessage?: string
}

export default function DataTable<T>({
  columns,
  data,
  loading,
  keyExtractor,
  searchable,
  searchKeys = [],
  pageSize = 20,
  emptyMessage = 'No records found.',
}: DataTableProps<T>) {
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)

  const filtered = searchable && query
    ? data.filter((row) =>
        searchKeys.some((k) =>
          String(row[k] ?? '').toLowerCase().includes(query.toLowerCase()),
        ),
      )
    : data

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize))
  const slice = filtered.slice((page - 1) * pageSize, page * pageSize)

  return (
    <div className="rounded-xl border border-gray-100 bg-white shadow-sm">
      {searchable && (
        <div className="border-b border-gray-100 px-4 py-3">
          <div className="relative max-w-xs">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              className="w-full rounded-lg border border-gray-200 py-2 pl-9 pr-3 text-sm outline-none focus:border-navy-500 focus:ring-1 focus:ring-navy-500"
              placeholder="Search…"
              value={query}
              onChange={(e) => { setQuery(e.target.value); setPage(1) }}
            />
          </div>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-xs font-semibold uppercase tracking-wide text-gray-500">
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key}
                  className="whitespace-nowrap px-4 py-3 text-left"
                  style={col.width ? { width: col.width } : undefined}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {loading ? (
              <tr>
                <td colSpan={columns.length} className="py-16 text-center">
                  <div className="flex justify-center">
                    <Spinner />
                  </div>
                </td>
              </tr>
            ) : slice.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="py-16 text-center text-gray-400">
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              slice.map((row) => (
                <tr key={keyExtractor(row)} className="hover:bg-gray-50/70">
                  {columns.map((col) => (
                    <td key={col.key} className="px-4 py-3 text-gray-700">
                      {col.render(row)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between border-t border-gray-100 px-4 py-3 text-sm text-gray-500">
          <span>
            {(page - 1) * pageSize + 1}–{Math.min(page * pageSize, filtered.length)} of{' '}
            {filtered.length}
          </span>
          <div className="flex gap-1">
            <button
              disabled={page === 1}
              onClick={() => setPage((p) => p - 1)}
              className="rounded p-1 hover:bg-gray-100 disabled:opacity-40"
            >
              <ChevronLeft size={16} />
            </button>
            <button
              disabled={page === totalPages}
              onClick={() => setPage((p) => p + 1)}
              className="rounded p-1 hover:bg-gray-100 disabled:opacity-40"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
