import { config } from 'dotenv';

config();

// Support .env with project_url / anon_public_key (map to Supabase client env)
const url =
  process.env.PUBLIC_SUPABASE_URL ||
  process.env.project_url ||
  '';
const anonKey =
  process.env.PUBLIC_SUPABASE_ANON_KEY ||
  process.env.anon_public_key ||
  '';

if (!url || !anonKey) {
  console.warn(
    'DB tests: PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY (or project_url and anon_public_key) should be set in .env'
  );
}

export const SUPABASE_URL = url;
export const SUPABASE_ANON_KEY = anonKey;
export const SUPABASE_SERVICE_ROLE_KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.secret_key_default || '';
