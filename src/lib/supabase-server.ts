/**
 * Supabase server client for Astro middleware and API routes.
 * Uses cookies for session so auth state is available server-side.
 */
import { createServerClient } from '@supabase/ssr';
import { parseCookieHeader } from '@supabase/ssr';
import type { AstroCookies } from 'astro';

const url = import.meta.env.PUBLIC_SUPABASE_URL ?? '';
const anonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY ?? '';

export type SupabaseServerContext = {
  headers: Headers;
  cookies: AstroCookies;
};

function mapCookieOptions(options: Record<string, unknown> & { path?: string; maxAge?: number; httpOnly?: boolean; secure?: boolean; sameSite?: 'lax' | 'strict' | 'none' }) {
  const out: { path?: string; maxAge?: number; httpOnly?: boolean; secure?: boolean; sameSite?: 'lax' | 'strict' | 'none' } = {};
  if (options.path != null) out.path = options.path as string;
  if (options.maxAge != null) out.maxAge = options.maxAge as number;
  if (options.httpOnly != null) out.httpOnly = options.httpOnly as boolean;
  if (options.secure != null) out.secure = options.secure as boolean;
  if (options.sameSite != null) out.sameSite = options.sameSite as 'lax' | 'strict' | 'none';
  return out;
}

export function createSupabaseServerInstance(context: SupabaseServerContext) {
  return createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        const header = context.headers.get('Cookie') ?? '';
        const parsed = parseCookieHeader(header);
        return parsed.filter((c): c is { name: string; value: string } => c.value != null) as { name: string; value: string }[];
      },
      setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
        cookiesToSet.forEach(({ name, value, options }) => {
          context.cookies.set(name, value, mapCookieOptions((options ?? {}) as Record<string, unknown> & { path?: string; maxAge?: number; httpOnly?: boolean; secure?: boolean; sameSite?: 'lax' | 'strict' | 'none' }));
        });
      },
    },
  });
}
