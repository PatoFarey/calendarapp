import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export interface Calendar {
  id: string
  user_id: string
  name: string
  description: string
  color: string
  is_public?: boolean
  created_at: string
  updated_at: string
}

export interface Booking {
  id: string
  calendar_id: string
  user_id: string
  title: string
  description: string
  start_time: string
  end_time: string
  created_at: string
  updated_at: string
}

export interface CalendarShare {
  id: string
  calendar_id: string
  owner_id: string
  shared_with_email: string
  can_edit: boolean
  created_at: string
}
