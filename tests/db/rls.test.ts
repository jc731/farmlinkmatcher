/**
 * RLS smoke tests: anon (unauthenticated) cannot see sensitive data.
 * Authenticated RLS (pending vs approved) is best tested with real auth; here we only check anon.
 * Requires .env with PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY (or project_url / anon_public_key).
 */
import { createClient } from '@supabase/supabase-js';
import { describe, it, expect, beforeAll } from 'vitest';
import { SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY } from '../setup.js';

const anon = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const serviceRole =
  SUPABASE_SERVICE_ROLE_KEY
    ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    : null;

describe('RLS (anon vs service role)', () => {
  beforeAll(() => {
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      throw new Error('Missing Supabase URL or anon key; set in .env');
    }
  });

  it('anon client cannot list profiles (RLS restricts to own row or approved)', async () => {
    const { data, error } = await anon.from('profiles').select('id, first_name, last_name');
    // Anon = no auth.uid(), so "Users can view own profile" and "Approved users can view approved profiles" don't match.
    // We expect either empty data or an error; no sensitive rows for unauthenticated.
    expect(error).toBeNull();
    expect(Array.isArray(data)).toBe(true);
    expect(data!.length).toBe(0);
  });

  it('anon client cannot list listings (no auth)', async () => {
    const { data, error } = await anon.from('listings').select('id, property_name, status');
    expect(error).toBeNull();
    expect(Array.isArray(data)).toBe(true);
    expect(data!.length).toBe(0);
  });

  it('service role can list tables when key is set', async () => {
    if (!serviceRole) {
      return;
    }
    const { data: profiles, error: e1 } = await serviceRole.from('profiles').select('id').limit(1);
    expect(e1).toBeNull();
    expect(Array.isArray(profiles)).toBe(true);

    const { data: listings, error: e2 } = await serviceRole.from('listings').select('id').limit(1);
    expect(e2).toBeNull();
    expect(Array.isArray(listings)).toBe(true);
  });
});
