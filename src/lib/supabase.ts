/**
 * Supabase client for browser. Uses cookies so session is available server-side (middleware).
 * Uses PUBLIC_ env vars.
 */
import { createBrowserClient } from '@supabase/ssr';

const url = import.meta.env.PUBLIC_SUPABASE_URL ?? '';
const anonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY ?? '';

export function createSupabaseClient() {
  return createBrowserClient(url, anonKey);
}
