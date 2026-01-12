'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { Landmark, Category } from '@/lib/types'

interface LandmarkFormProps {
  landmark?: Landmark | null
  categories: Category[]
  onSave: () => void
  onCancel: () => void
}

export default function LandmarkForm({ landmark, categories, onSave, onCancel }: LandmarkFormProps) {
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    name_en: '',
    description: '',
    description_en: '',
    latitude: '',
    longitude: '',
    altitude: '0',
    year_built: '',
    architect: '',
    category_id: '',
    wikipedia_url: '',
    is_active: true,
  })

  useEffect(() => {
    if (landmark) {
      setFormData({
        name: landmark.name || '',
        name_en: landmark.name_en || '',
        description: landmark.description || '',
        description_en: landmark.description_en || '',
        latitude: landmark.latitude?.toString() || '',
        longitude: landmark.longitude?.toString() || '',
        altitude: landmark.altitude?.toString() || '0',
        year_built: landmark.year_built?.toString() || '',
        architect: landmark.architect || '',
        category_id: landmark.category_id || '',
        wikipedia_url: landmark.wikipedia_url || '',
        is_active: landmark.is_active ?? true,
      })
    }
  }, [landmark])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const data = {
        name: formData.name,
        name_en: formData.name_en || null,
        description: formData.description || null,
        description_en: formData.description_en || null,
        latitude: parseFloat(formData.latitude),
        longitude: parseFloat(formData.longitude),
        altitude: parseFloat(formData.altitude) || 0,
        year_built: formData.year_built ? parseInt(formData.year_built) : null,
        architect: formData.architect || null,
        category_id: formData.category_id || null,
        wikipedia_url: formData.wikipedia_url || null,
        is_active: formData.is_active,
      }

      if (landmark) {
        // Update
        const { error } = await supabase
          .from('landmarks')
          .update(data)
          .eq('id', landmark.id)

        if (error) throw error
      } else {
        // Insert
        const { error } = await supabase
          .from('landmarks')
          .insert([data])

        if (error) throw error
      }

      onSave()
    } catch (err) {
      console.error('Error saving landmark:', err)
      alert('Fehler beim Speichern')
    } finally {
      setLoading(false)
    }
  }

  const inputClass = "w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-[15px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
  const labelClass = "block text-[13px] font-medium text-gray-700 mb-1.5"

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {/* Name */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className={labelClass}>Name (DE) *</label>
          <input
            type="text"
            required
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className={inputClass}
            placeholder="Grossmünster"
          />
        </div>
        <div>
          <label className={labelClass}>Name (EN)</label>
          <input
            type="text"
            value={formData.name_en}
            onChange={(e) => setFormData({ ...formData, name_en: e.target.value })}
            className={inputClass}
            placeholder="Grossmünster"
          />
        </div>
      </div>

      {/* Description */}
      <div>
        <label className={labelClass}>Beschreibung (DE)</label>
        <textarea
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          className={`${inputClass} resize-none`}
          rows={3}
          placeholder="Beschreibung der Sehenswürdigkeit..."
        />
      </div>

      {/* Coordinates */}
      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className={labelClass}>Breitengrad *</label>
          <input
            type="number"
            step="any"
            required
            value={formData.latitude}
            onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
            className={inputClass}
            placeholder="47.3702"
          />
        </div>
        <div>
          <label className={labelClass}>Längengrad *</label>
          <input
            type="number"
            step="any"
            required
            value={formData.longitude}
            onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
            className={inputClass}
            placeholder="8.5442"
          />
        </div>
        <div>
          <label className={labelClass}>Höhe (m)</label>
          <input
            type="number"
            value={formData.altitude}
            onChange={(e) => setFormData({ ...formData, altitude: e.target.value })}
            className={inputClass}
            placeholder="410"
          />
        </div>
      </div>

      {/* Category & Year */}
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className={labelClass}>Kategorie</label>
          <select
            value={formData.category_id}
            onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
            className={inputClass}
          >
            <option value="">Keine Kategorie</option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.icon} {cat.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className={labelClass}>Baujahr</label>
          <input
            type="number"
            value={formData.year_built}
            onChange={(e) => setFormData({ ...formData, year_built: e.target.value })}
            className={inputClass}
            placeholder="1220"
          />
        </div>
      </div>

      {/* Architect */}
      <div>
        <label className={labelClass}>Architekt</label>
        <input
          type="text"
          value={formData.architect}
          onChange={(e) => setFormData({ ...formData, architect: e.target.value })}
          className={inputClass}
          placeholder="Name des Architekten"
        />
      </div>

      {/* Wikipedia URL */}
      <div>
        <label className={labelClass}>Wikipedia URL</label>
        <input
          type="url"
          value={formData.wikipedia_url}
          onChange={(e) => setFormData({ ...formData, wikipedia_url: e.target.value })}
          className={inputClass}
          placeholder="https://de.wikipedia.org/wiki/..."
        />
      </div>

      {/* Active Toggle */}
      <div className="flex items-center justify-between py-2">
        <div>
          <div className="text-[15px] font-medium text-gray-900">Aktiv</div>
          <div className="text-[13px] text-gray-500">Eintrag in der App anzeigen</div>
        </div>
        <button
          type="button"
          onClick={() => setFormData({ ...formData, is_active: !formData.is_active })}
          className={`relative w-12 h-7 rounded-full transition-colors ${formData.is_active ? 'bg-green-500' : 'bg-gray-300'
            }`}
        >
          <div className={`absolute top-0.5 w-6 h-6 bg-white rounded-full shadow transition-transform ${formData.is_active ? 'translate-x-5' : 'translate-x-0.5'
            }`} />
        </button>
      </div>

      {/* Actions */}
      <div className="flex gap-3 pt-4 border-t border-gray-100">
        <button
          type="button"
          onClick={onCancel}
          className="flex-1 px-4 py-2.5 bg-gray-100 text-gray-700 text-[15px] font-medium rounded-xl hover:bg-gray-200 transition-colors"
        >
          Abbrechen
        </button>
        <button
          type="submit"
          disabled={loading}
          className="flex-1 px-4 py-2.5 bg-blue-500 text-white text-[15px] font-medium rounded-xl hover:bg-blue-600 transition-colors disabled:opacity-50"
        >
          {loading ? 'Speichern...' : (landmark ? 'Aktualisieren' : 'Erstellen')}
        </button>
      </div>
    </form>
  )
}