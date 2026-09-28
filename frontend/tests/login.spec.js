import { test, expect } from '@playwright/test';

test('HR signs in with a CSRF-protected session and signs out', async ({ page }) => {
  await page.goto('/');
  await page.getByLabel('Work email').fill('hr@acme.example');
  await page.getByLabel('Password', { exact: true }).fill('WrongPassword');
  await page.getByRole('button', { name: 'Sign in to workspace' }).click();
  await expect(page.getByRole('alert')).toHaveText('Invalid email or password');
  await page.getByLabel('Password', { exact: true }).fill('AcmeDemo2026!');
  await page.getByRole('button', { name: 'Sign in to workspace' }).click();
  await expect(page.getByRole('button', { name: 'Sign out' })).toBeVisible();
  await page.reload();
  await expect(page.getByRole('button', { name: 'Sign out' })).toBeVisible();
  await page.getByRole('button', { name: 'Sign out' }).click();
  await expect(page.getByRole('button', { name: 'Sign in to workspace' })).toBeVisible();
});
