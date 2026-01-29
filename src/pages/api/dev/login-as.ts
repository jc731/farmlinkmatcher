/**
 * Dev-only: sign in as a seed test user (farmer, landowner, admin).
 * Only enabled when import.meta.env.DEV is true.
 * POST body: role = farmer | landowner | admin
 */
import type { APIRoute } from 'astro';
import { createSupabaseServerInstance } from '../../../lib/supabase-server';

const TEST_USERS: Record<string, string> = {
  admin: 'admin@farmlink-dev.local',
  farmer: 'farmer@farmlink-dev.local',
  landowner: 'landowner@farmlink-dev.local',
};

const VALID_ROLES = ['admin', 'farmer', 'landowner'] as const;

export const POST: APIRoute = async ({ request, cookies, redirect }) => {
  if (!import.meta.env.DEV) {
    return new Response('Not available', { status: 404 });
  }

  const password = import.meta.env.DEV_TEST_PASSWORD ?? 'DevPassword123!';
  const formData = await request.formData().catch(() => null);
  const roleParam = formData?.get('role')?.toString() ?? '';
  const role = roleParam.trim().toLowerCase();

  if (!VALID_ROLES.includes(role as typeof VALID_ROLES[number])) {
    return new Response('Invalid role', { status: 400 });
  }

  const email = TEST_USERS[role];
  if (!email) {
    return new Response('Unknown role', { status: 400 });
  }

  const supabase = createSupabaseServerInstance({ headers: request.headers, cookies });
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    return new Response(error.message, { status: 401 });
  }

  return redirect('/app/dev/user');
};
