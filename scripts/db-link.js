#!/usr/bin/env node
/**
 * Load .env and run: supabase link --project-ref <project_id>
 * Usage: node scripts/db-link.js   (from repo root)
 * Requires: .env with project_id=
 */
import { readFileSync } from 'fs';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
let projectId = '';

try {
  const envPath = join(root, '.env');
  const env = readFileSync(envPath, 'utf8');
  for (const line of env.split('\n')) {
    const m = line.match(/^\s*project_id\s*=\s*(.+?)\s*$/);
    if (m) {
      projectId = m[1].trim();
      break;
    }
  }
} catch (e) {
  console.error('Could not read .env (missing project_id?).', e.message);
  process.exit(1);
}

if (!projectId) {
  console.error('No project_id= in .env');
  process.exit(1);
}

const supabase = spawn('pnpm', ['exec', 'supabase', 'link', '--project-ref', projectId], {
  cwd: root,
  stdio: 'inherit',
  shell: true,
});
supabase.on('close', (code) => process.exit(code ?? 0));
