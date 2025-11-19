import type { SupabaseClient as SupabaseClientBase } from '@supabase/supabase-js'
import type { Database } from './database.types'

// Re-export typed SupabaseClient to use throughout the app
// This ensures consistent typing across all Supabase client usages
export type SupabaseClient = SupabaseClientBase<Database>

