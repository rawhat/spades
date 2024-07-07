import gleam from "vite-gleam";
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    host: "0.0.0.0",
    port: 5000,
    strictPort: true,
    proxy: {
      "/api": {
        target: "http://api:4000",
        secure: false,
      },
      "/socket": {
        target: "http://api:4000",
        changeOrigin: true,
        ws: true,
      },
      "/static": {
        target: "http://api:4000",
        changeOrigin: true,
        secure: false,
      },
    },
  },
  plugins: [gleam()],
});