import { test, expect } from "@playwright/test";

test("HR can search, inspect annual/monthly salary history, and view reports", async ({
  page,
}) => {
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/");
  await page
    .getByLabel("Work email")
    .fill(process.env.ADMIN_EMAIL || "hr@acme.example");
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.ADMIN_PASSWORD || "AcmeDemo2026!");
  await page.getByRole("button", { name: "Sign in to workspace" }).click();
  await expect(
    page.getByRole("heading", { name: "Your people, in one place." }),
  ).toBeVisible();
  await expect(
    page.getByText("10,000 employees", { exact: true }),
  ).toBeVisible();
  await page.screenshot({
    path: "test-results/screenshots/directory.png",
    fullPage: true,
  });
  await page.getByRole("button", { name: "Next page" }).click();
  await expect(page.getByText("Page 2", { exact: true })).toBeVisible();
  await page
    .getByRole("textbox", { name: "Search employees" })
    .fill("ACME-00001");
  await expect(page.getByText("1 employees", { exact: true })).toBeVisible();
  await page
    .getByRole("button", { name: "View Aarav Sharma", exact: true })
    .click();
  await expect(
    page.getByRole("heading", { name: "Compensation history" }),
  ).toBeVisible();
  await expect(
    page.getByText("Annual evaluation", { exact: false }),
  ).toBeVisible();
  await page.screenshot({
    path: "test-results/screenshots/history.png",
    fullPage: true,
  });
  await page.getByRole("button", { name: "Record salary change" }).click();
  await expect(page.getByLabel("Annual CTC", { exact: true })).toHaveValue(
    "972000.0",
  );
  await page.getByLabel("Annual CTC", { exact: true }).fill("1");
  await page.getByLabel("Reason", { exact: true }).fill("Validation check");
  await page.getByRole("button", { name: "Save compensation version" }).click();
  await expect(
    page
      .getByRole("dialog", { name: "Record salary change" })
      .getByRole("alert"),
  ).toContainText("must sum exactly");
  await page
    .getByRole("dialog", { name: "Record salary change" })
    .getByRole("button", { name: "Close dialog" })
    .click();
  await page.getByRole("button", { name: "Close dialog" }).click();
  await page.getByRole("textbox", { name: "Search employees" }).fill("");
  await page.getByRole("button", { name: "Compensation insights" }).click();
  await expect(
    page.getByRole("heading", { name: "Understand how you pay." }),
  ).toBeVisible();
  await expect(page.getByText("USD", { exact: true }).first()).toBeVisible();
  await page.screenshot({
    path: "test-results/screenshots/reports.png",
    fullPage: true,
  });
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(
    page.getByRole("button", { name: "Sign in to workspace" }),
  ).toBeVisible();
  expect(errors).toEqual([]);
});

test("mobile sign-in and directory remain usable", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await page
    .getByLabel("Work email")
    .fill(process.env.ADMIN_EMAIL || "hr@acme.example");
  await page
    .getByLabel("Password", { exact: true })
    .fill(process.env.ADMIN_PASSWORD || "AcmeDemo2026!");
  await page.getByRole("button", { name: "Sign in to workspace" }).click();
  await expect(
    page.getByRole("heading", { name: "Employee directory" }),
  ).toBeVisible();
  await expect(
    page.getByRole("textbox", { name: "Search employees" }),
  ).toBeVisible();
  await page.screenshot({
    path: "test-results/screenshots/mobile.png",
    fullPage: true,
  });
});
