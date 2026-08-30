import { defineConfig } from "vite";

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        input: {
          main: "index.html",
          registration: "registration.html",
        },
      },
    },
  },
});
