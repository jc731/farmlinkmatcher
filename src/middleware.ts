/**
 * Protects /app/* routes: redirects unauthenticated users to sign-in.
 * Sets context.locals.user from Supabase session (cookies).
 */
import { defineMiddleware } from 'astro:middleware';
import { createSupabaseServerInstance } from './lib/supabase-server';

const PROTECTED_PREFIX = '/app';

export const onRequest = defineMiddleware(async (context, next) => {
  context.locals.user = null;

  const supabase = createSupabaseServerInstance({
    headers: context.request.headers,
    cookies: context.cookies,
  });

  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    context.locals.user = { id: user.id, email: user.email ?? undefined };
  }

  if (context.url.pathname.startsWith(PROTECTED_PREFIX) && !user) {
    return context.redirect('/auth/sign-in');
  }

  return next();
});
