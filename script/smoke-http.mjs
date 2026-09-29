// Read-only readiness check. Does not create or modify employees or salaries.
const base = process.env.APP_URL || "http://127.0.0.1:3300";
const home = await fetch(base);
if (!home.ok) throw new Error(`Home returned ${home.status}`);
const html = await home.text();
const asset = html.match(/src="([^"]+\.js)"/)?.[1];
if (!asset || !(await fetch(base + asset)).ok)
  throw new Error("React bundle unavailable");
const session = await fetch(base + "/api/session");
const { csrf_token } = await session.json();
let cookie = session.headers
  .getSetCookie()
  .map((value) => value.split(";")[0])
  .join("; ");
const login = await fetch(base + "/api/session", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": csrf_token,
    Cookie: cookie,
  },
  body: JSON.stringify({
    email: process.env.ADMIN_EMAIL || "hr@acme.example",
    password: process.env.ADMIN_PASSWORD || "AcmeDemo2026!",
  }),
});
if (!login.ok) throw new Error(`Login returned ${login.status}`);
cookie = login.headers
  .getSetCookie()
  .map((value) => value.split(";")[0])
  .join("; ");
const response = await fetch(base + "/api/employees", {
  headers: { Cookie: cookie },
});
const data = await response.json();
if (!response.ok || data.total !== 10000)
  throw new Error("Expected a fresh 10,000-employee directory");
console.log(
  "PASS: page, React bundle, CSRF-protected login, and 10,000-employee directory",
);
