'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { Landmark, Category } from '@/lib/types'
import Modal from '@/components/Modal'
import LandmarkForm from '@/components/LandmarkForm'

export default function Home() {
  const [landmarks, setLandmarks] = useState<Landmark[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingLandmark, setEditingLandmark] = useState<Landmark | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<Landmark | null>(null)

  const fetchData = async () => {
    try {
      const { data: landmarksData, error: landmarksError } = await supabase
        .from('landmarks')
        .select(`
          *,
          category:categories(*)
        `)
        .order('name')

      if (landmarksError) throw landmarksError

      const { data: categoriesData, error: categoriesError } = await supabase
        .from('categories')
        .select('*')
        .order('sort_order')

      if (categoriesError) throw categoriesError

      setLandmarks(landmarksData || [])
      setCategories(categoriesData || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Ein Fehler ist aufgetreten')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  const handleCreate = () => {
    setEditingLandmark(null)
    setIsModalOpen(true)
  }

  const handleEdit = (landmark: Landmark) => {
    setEditingLandmark(landmark)
    setIsModalOpen(true)
  }

  const handleSave = () => {
    setIsModalOpen(false)
    setEditingLandmark(null)
    fetchData()
  }

  const handleDelete = async (landmark: Landmark) => {
    try {
      const { error } = await supabase
        .from('landmarks')
        .delete()
        .eq('id', landmark.id)

      if (error) throw error

      setDeleteConfirm(null)
      fetchData()
    } catch (err) {
      console.error('Error deleting landmark:', err)
      alert('Fehler beim Löschen')
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f5f5f7]">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-gray-300 border-t-blue-500 rounded-full animate-spin" />
          <span className="text-[15px] text-gray-500 font-medium">Laden...</span>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f5f5f7]">
        <div className="bg-white rounded-2xl p-8 shadow-sm max-w-md text-center">
          <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </div>
          <h2 className="text-[17px] font-semibold text-gray-900 mb-2">Verbindungsfehler</h2>
          <p className="text-[15px] text-gray-500">{error}</p>
        </div>
      </div>
    )
  }

  return (
    <main className="min-h-screen bg-[#f5f5f7]">
      {/* Navigation */}
      <nav className="bg-white/80 backdrop-blur-xl border-b border-gray-200/50 sticky top-0 z-40">
        <div className="max-w-6xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 bg-linear-to-br from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-sm">
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <span className="text-[17px] font-semibold text-gray-900">AR Landmarks</span>
            </div>
            <button
              onClick={handleCreate}
              className="bg-blue-500 hover:bg-blue-600 text-white text-[15px] font-medium px-4 py-2 rounded-full transition-colors"
            >
              + Neu
            </button>
          </div>
        </div>
      </nav>

      <div className="max-w-6xl mx-auto px-6 py-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <div className="bg-white rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-[28px] font-bold text-gray-900">{landmarks.length}</div>
                <div className="text-[15px] text-gray-500 mt-1">Sehenswürdigkeiten</div>
              </div>
              <div className="w-12 h-12 bg-blue-50 rounded-2xl flex items-center justify-center">
                <svg className="w-6 h-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-[28px] font-bold text-gray-900">{categories.length}</div>
                <div className="text-[15px] text-gray-500 mt-1">Kategorien</div>
              </div>
              <div className="w-12 h-12 bg-purple-50 rounded-2xl flex items-center justify-center">
                <svg className="w-6 h-6 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                </svg>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-[28px] font-bold text-gray-900">{landmarks.filter(l => l.is_active).length}</div>
                <div className="text-[15px] text-gray-500 mt-1">Aktive Einträge</div>
              </div>
              <div className="w-12 h-12 bg-green-50 rounded-2xl flex items-center justify-center">
                <svg className="w-6 h-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        {/* Landmarks List */}
        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div className="px-6 py-5 border-b border-gray-100">
            <h2 className="text-[17px] font-semibold text-gray-900">Alle Sehenswürdigkeiten</h2>
          </div>

          <div className="divide-y divide-gray-100">
            {landmarks.map((landmark) => (
              <div
                key={landmark.id}
                className="px-6 py-4 hover:bg-gray-50/50 transition-colors group"
              >
                <div className="flex items-center justify-between">
                  <div
                    className="flex items-center gap-4 flex-1 cursor-pointer"
                    onClick={() => handleEdit(landmark)}
                  >
                    <div
                      className="w-11 h-11 rounded-xl flex items-center justify-center text-lg"
                      style={{
                        backgroundColor: landmark.category ? `${landmark.category.color}15` : '#f3f4f6',
                      }}
                    >
                      {landmark.category?.icon || '📍'}
                    </div>

                    <div>
                      <div className="text-[15px] font-medium text-gray-900">{landmark.name}</div>
                      <div className="flex items-center gap-2 mt-0.5">
                        {landmark.category && (
                          <span className="text-[13px]" style={{ color: landmark.category.color }}>
                            {landmark.category.name}
                          </span>
                        )}
                        <span className="text-gray-300">•</span>
                        <span className="text-[13px] text-gray-400">{landmark.year_built || 'Unbekannt'}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="hidden md:block text-right">
                      <div className="text-[13px] text-gray-400 font-mono">{landmark.latitude.toFixed(4)}° N</div>
                      <div className="text-[13px] text-gray-400 font-mono">{landmark.longitude.toFixed(4)}° E</div>
                    </div>

                    <div className={`px-2.5 py-1 rounded-full text-[12px] font-medium ${landmark.is_active ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-500'
                      }`}>
                      {landmark.is_active ? 'Aktiv' : 'Inaktiv'}
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button
                        onClick={() => handleEdit(landmark)}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                        title="Bearbeiten"
                      >
                        <svg className="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                        </svg>
                      </button>
                      <button
                        onClick={() => setDeleteConfirm(landmark)}
                        className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                        title="Löschen"
                      >
                        <svg className="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Footer */}
        <div className="mt-8 text-center text-[13px] text-gray-400">
          ASP Projekt · AR Landmarks Dashboard · {new Date().getFullYear()}
        </div>
      </div>

      {/* Create/Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingLandmark ? 'Sehenswürdigkeit bearbeiten' : 'Neue Sehenswürdigkeit'}
      >
        <LandmarkForm
          landmark={editingLandmark}
          categories={categories}
          onSave={handleSave}
          onCancel={() => setIsModalOpen(false)}
        />
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deleteConfirm}
        onClose={() => setDeleteConfirm(null)}
        title="Löschen bestätigen"
      >
        <div className="text-center py-4">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </div>
          <h3 className="text-[17px] font-semibold text-gray-900 mb-2">
            {deleteConfirm?.name} löschen?
          </h3>
          <p className="text-[15px] text-gray-500 mb-6">
            Diese Aktion kann nicht rückgängig gemacht werden.
          </p>
          <div className="flex gap-3">
            <button
              onClick={() => setDeleteConfirm(null)}
              className="flex-1 px-4 py-2.5 bg-gray-100 text-gray-700 text-[15px] font-medium rounded-xl hover:bg-gray-200 transition-colors"
            >
              Abbrechen
            </button>
            <button
              onClick={() => deleteConfirm && handleDelete(deleteConfirm)}
              className="flex-1 px-4 py-2.5 bg-red-500 text-white text-[15px] font-medium rounded-xl hover:bg-red-600 transition-colors"
            >
              Löschen
            </button>
          </div>
        </div>
      </Modal>
    </main>
  )
}