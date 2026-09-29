import { chromium } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
const output = fileURLToPath(new URL("../../docs/demo/", import.meta.url));
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ slowMo: 350 });
const context = await browser.newContext({
  viewport: { width: 1440, height: 1000 },
  recordVideo: { dir: output, size: { width: 1440, height: 1000 } },
});
const page = await context.newPage();
try {
  await page.goto(process.env.APP_URL || "http://127.0.0.1:3100");
  await page
    .getByLabel("Work email")
    .fill(process.env.ADMIN_EMAIL || "hr@acme.example");
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.ADMIN_PASSWORD || "AcmeDemo2026!");
  await page.getByRole("button", { name: "Sign in to workspace" }).click();
  await page.getByText("10,000 employees", { exact: true }).waitFor();
  await page.waitForTimeout(3500);
  await page
    .getByRole("combobox", { name: "country", exact: true })
    .selectOption("India");
  await page.waitForTimeout(2500);
  await page
    .getByRole("textbox", { name: "Search employees" })
    .fill("ACME-00001");
  await page.getByRole("button", { name: "View Aarav Sharma" }).click();
  await page.waitForTimeout(5000);
  await page.getByRole("button", { name: "Record salary change" }).click();
  await page.waitForTimeout(4000);
  await page
    .getByRole("dialog", { name: "Record salary change" })
    .getByRole("button", { name: "Close dialog" })
    .click();
  await page.getByRole("button", { name: "Close dialog" }).click();
  await page.getByRole("textbox", { name: "Search employees" }).fill("");
  await page
    .getByRole("combobox", { name: "country", exact: true })
    .selectOption("");
  await page.getByRole("button", { name: "Compensation insights" }).click();
  await page.getByText("View conversion assumptions").click();
  await page.waitForTimeout(5000);
  await page.getByRole("button", { name: "Employees", exact: true }).click();
  await page.getByRole("button", { name: "Import CSV" }).click();
  await page.waitForTimeout(4000);
  await page.getByRole("button", { name: "Close dialog" }).click();
  await page.getByRole("button", { name: "Sign out" }).click();
  await page.waitForTimeout(1500);
} finally {
  await context.close();
  await page.video().saveAs(`${output}/walkthrough.webm`);
  await page.video().delete();
  await browser.close();
}
console.log("Recorded docs/demo/walkthrough.webm");
