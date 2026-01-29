import { useEffect, useState } from 'react';
import { createSupabaseClient } from '../lib/supabase';

/**
 * Handles auth redirect (e.g. password reset) when tokens are in the URL hash.
 * Sets session from hash and redirects to /app.
 */
export default function AuthCallback() {
  const [status, setStatus] = useState<'loading' | 'done' | 'error'>('loading');

  useEffect(() => {
    const hash = typeof window !== 'undefined' ? window.location.hash : '';
    if (!hash) {
      setStatus('error');
      return;
    }
    const params = new URLSearchParams(hash.slice(1));
    const access_token = params.get('access_token');
    const refresh_token = params.get('refresh_token');
    if (!access_token || !refresh_token) {
      setStatus('error');
      return;
    }
    const supabase = createSupabaseClient();
    supabase.auth
      .setSession({ access_token, refresh_token })
      .then(() => {
        setStatus('done');
        window.location.replace('/app');
      })
      .catch(() => setStatus('error'));
  }, []);

  if (status === 'loading') return <p className="text-gray-600">Signing you in…</p>;
  if (status === 'error') {
    return (
      <p className="text-amber-600">
        Invalid or expired link. <a href="/auth/sign-in" className="text-green-600 hover:underline">Sign in</a> or request a new reset link.
      </p>
    );
  }
  return <p className="text-green-600">Redirecting…</p>;
}
