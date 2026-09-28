import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./tests",
  workers: 1,
  webServer: process.env.APP_URL
    ? undefined
    : {
        command: "../bin/browser-test-server",
        url: "http://127.0.0.1:3102/up",
        reuseExistingServer: false,
        timeout: 120000,
        env: {
          ADMIN_EMAIL: "hr@acme.example",
          ADMIN_PASSWORD: "AcmeDemo2026!",
        },
      },
  use: {
    baseURL: process.env.APP_URL || "http://127.0.0.1:3102",
    viewport: { width: 1440, height: 1000 },
    video: "on",
    screenshot: "only-on-failure",
  },
  reporter: "list",
});
