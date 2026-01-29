/// <reference path="../.astro/types.d.ts" />
/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly PUBLIC_SUPABASE_URL: string;
  readonly PUBLIC_SUPABASE_ANON_KEY: string;
  /** Dev-only: password for seed test users (admin@, farmer@, landowner@farmlink-dev.local). Default in seed: DevPassword123! */
  readonly DEV_TEST_PASSWORD?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

declare namespace App {
  interface Locals {
    user: { id: string; email?: string } | null;
  }
}
