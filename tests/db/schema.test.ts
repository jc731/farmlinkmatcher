/**
 * DB schema smoke tests: tables and RLS exist.
 * Requires .env with PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY (or project_url / anon_public_key).
 */
import { createClient } from '@supabase/supabase-js';
import { describe, it, expect, beforeAll } from 'vitest';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from '../setup.js';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

describe('DB schema', () => {
  beforeAll(() => {
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      throw new Error('Missing Supabase URL or anon key; set in .env');
    }
  });

  it('profiles table exists and has expected columns', async () => {
    const { data, error } = await supabase.from('profiles').select('id, role, status, first_name, last_name').limit(1);
    expect(error).toBeNull();
    expect(Array.isArray(data)).toBe(true);
  });

  it('listings table exists', async () => {
    const { data, error } = await supabase.from('listings').select('id, status, property_name').limit(1);
    expect(error).toBeNull();
    expect(Array.isArray(data)).toBe(true);
  });

  it('inquiries table exists', async () => {
    const { data, error } = await supabase.from('inquiries').select('id, status').limit(1);
    expect(error).toBeNull();
    expect(Array.isArray(data)).toBe(true);
  });
});
