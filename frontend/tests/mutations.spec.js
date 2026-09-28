import { test, expect } from "@playwright/test";

test.describe("isolated browser writes", () => {
  test.skip(
    Boolean(process.env.APP_URL),
    "Write tests only run on the disposable browser-test database",
  );

  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await page.getByLabel("Work email").fill("hr@acme.example");
    await page.getByLabel("Password", { exact: true }).fill("AcmeDemo2026!");
    await page.getByRole("button", { name: "Sign in to workspace" }).click();
    await expect(
      page.getByRole("heading", { name: "Employee directory" }),
    ).toBeVisible();
  });

  test("create employee record salary increment and edit employee", async ({
    page,
  }) => {
    await page
      .getByRole("button", { name: "Add employee", exact: true })
      .click();
    const form = page.getByRole("dialog", {
      name: "Add employee",
      exact: true,
    });
    for (const [label, value] of Object.entries({
      "Full name": "Browser Test Person",
      "Employee ID": "BROWSER-001",
      Email: "browser@example.com",
      Country: "India",
      Department: "Engineering",
      Level: "L3",
    })) {
      await form.getByLabel(label, { exact: true }).fill(value);
    }
    await form.getByRole("button", { name: "Save employee" }).click();
    await expect(page.getByText("No salary recorded yet.")).toBeVisible();
    await page.getByRole("button", { name: "Record salary change" }).click();
    const salary = page.getByRole("dialog", { name: "Record salary change" });
    await salary.getByLabel("Effective date").fill("2026-01-01");
    await salary.getByLabel("Annual CTC", { exact: true }).fill("1200000");
    await salary.getByLabel("Reason", { exact: true }).fill("Initial offer");
    await salary.getByLabel("Component 1 amount").fill("480000");
    await salary.getByLabel("Component 2 amount").fill("240000");
    await salary.getByLabel("Component 3 amount").fill("480000");
    await salary
      .getByRole("button", { name: "Save compensation version" })
      .click();
    await expect(salary).not.toBeVisible();
    await expect(
      page.getByText("₹1,00,000.00 / month · Initial offer"),
    ).toBeVisible();
    await page.getByRole("button", { name: "Record salary change" }).click();
    await salary.getByLabel("Effective date").fill("2027-01-01");
    await salary.getByLabel("Annual CTC", { exact: true }).fill("1320000");
    await salary
      .getByLabel("Reason", { exact: true })
      .fill("Annual evaluation");
    await salary.getByLabel("Component 1 amount").fill("528000");
    await salary.getByLabel("Component 2 amount").fill("264000");
    await salary.getByLabel("Component 3 amount").fill("528000");
    await salary
      .getByRole("button", { name: "Save compensation version" })
      .click();
    await expect(salary).not.toBeVisible();
    await expect(page.getByText("+10.0%", { exact: true })).toBeVisible();
    await expect(
      page.getByText("₹1,00,000.00 / month · Initial offer"),
    ).toBeVisible();
    await page
      .getByRole("button", { name: "Edit employee", exact: true })
      .click();
    const edit = page.getByRole("dialog", {
      name: "Edit employee",
      exact: true,
    });
    await edit.getByLabel("Department").fill("Product");
    await edit.getByLabel("Status").selectOption("inactive");
    await edit.getByRole("button", { name: "Save employee" }).click();
    await expect(edit).not.toBeVisible();
    await expect(
      page.getByText("BROWSER-001 · Product · L3 · India"),
    ).toBeVisible();
  });

  test("CSV import rejects invalid file accepts new employees and exports filtered data", async ({
    page,
  }) => {
    await page.getByRole("button", { name: "Import CSV" }).click();
    const modal = page.getByRole("dialog", { name: "Import employees" });
    await modal
      .getByLabel("CSV file")
      .setInputFiles({
        name: "bad.csv",
        mimeType: "text/csv",
        buffer: Buffer.from("bad,headers\nvalue,value\n"),
      });
    await modal
      .getByRole("button", { name: "Import employees", exact: true })
      .click();
    await expect(modal.getByRole("alert")).toContainText("Headers must be");
    const csv =
      'employee_code,name,email,country,department,level,status,currency,annual_ctc,effective_on,reason,components\nBROWSER-CSV,CSV Person,csv@example.com,India,Finance,L2,active,INR,1200000,2026-01-01,Initial,"{""Basic"":""1200000""}"\n';
    await modal
      .getByLabel("CSV file")
      .setInputFiles({
        name: "valid.csv",
        mimeType: "text/csv",
        buffer: Buffer.from(csv),
      });
    await modal
      .getByRole("button", { name: "Import employees", exact: true })
      .click();
    await expect(modal).not.toBeVisible();
    await page
      .getByRole("textbox", { name: "Search employees" })
      .fill("BROWSER-CSV");
    await expect(page.getByText("1 employees", { exact: true })).toBeVisible();
    const downloadPromise = page.waitForEvent("download");
    await page.getByRole("link", { name: "Export CSV" }).click();
    const download = await downloadPromise;
    const stream = await download.createReadStream();
    let content = "";
    for await (const chunk of stream) content += chunk.toString();
    expect(content).toContain("BROWSER-CSV");
    expect(content).not.toContain("ACME-00001");
  });
});

test("failed sign-in displays error and keyboard can dismiss a dialog", async ({
  page,
}) => {
  await page.goto("/");
  await page.getByLabel("Work email").fill("hr@acme.example");
  await page.getByLabel("Password", { exact: true }).fill("WrongPassword");
  await page.getByRole("button", { name: "Sign in to workspace" }).click();
  await expect(page.getByRole("alert")).toHaveText("Invalid email or password");
  await page.getByLabel("Password", { exact: true }).fill("AcmeDemo2026!");
  await page.getByRole("button", { name: "Sign in to workspace" }).click();
  await page.getByRole("button", { name: "Add employee", exact: true }).click();
  await expect(page.getByRole("dialog")).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).not.toBeVisible();
  await expect(
    page.getByRole("button", { name: "Add employee", exact: true }),
  ).toBeFocused();
});
