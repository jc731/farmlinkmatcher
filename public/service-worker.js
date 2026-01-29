// Placeholder; no-op so browser doesn't 404. Replace with real SW if needed.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', () => self.clients.claim());
