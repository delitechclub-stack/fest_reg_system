import { defineConfig } from 'vite';
import { resolve } from 'node:path';

const eventPages = Array.from({ length: 12 }, (_, index) => `event-${index}.html`);

export default defineConfig({
  root: '.',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      input: [
        resolve(__dirname, 'index.html'),
        resolve(__dirname, 'event.html'),
        ...eventPages.map((page) => resolve(__dirname, page))
      ]
    }
  },
  server: {
    host: true,
    port: 5173,
    strictPort: false
  },
  preview: {
    host: true,
    port: 5173,
    strictPort: false
  }
});
