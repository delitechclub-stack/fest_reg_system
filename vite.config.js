import { defineConfig } from "vite";

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: "index.html",
        registration: "registration.html",
        event0: "event-0.html",
        event1: "event-1.html",
        event2: "event-2.html",
        event3: "event-3.html",
        event4: "event-4.html",
        event5: "event-5.html",
        event6: "event-6.html",
        event7: "event-7.html",
        event8: "event-8.html",
        event9: "event-9.html",
        event10: "event-10.html",
        event11: "event-11.html",
      },
    },
  },
});
