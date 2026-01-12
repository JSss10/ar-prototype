export interface Category {
  id: string
  name: string
  name_en: string | null
  icon: string | null
  color: string
  sort_order: number
  created_at: string
}

export interface Landmark {
  id: string
  name: string
  name_en: string | null
  description: string | null
  description_en: string | null
  latitude: number
  longitude: number
  altitude: number
  year_built: number | null
  architect: string | null
  category_id: string | null
  image_url: string | null
  wikipedia_url: string | null
  zurich_tourism_id: string | null
  is_active: boolean
  created_at: string
  updated_at: string
  // Joined
  category?: Category
}

export interface LandmarkFact {
  id: string
  landmark_id: string
  title: string
  title_en: string | null
  content: string
  content_en: string | null
  sort_order: number
  created_at: string
}