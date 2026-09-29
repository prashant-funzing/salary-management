# Rebuild verification — 2026-09-29

This record applies to the `tdd-rebuild` second iteration, not the prototype's original development order. [The TDD log](tdd.md) maps actual failing test executions to passing implementation commits.

## Checks completed

- 69 backend tests, 358 assertions; zero failures/errors/skips after the shared lock-version refactor.
- Six Chromium browser tests passed: sessions, directory/history/reports, employee and salary writes, increment history, CSV import/export, validation, keyboard focus, and mobile layout.
- Loaded core backend coverage: 210/210 executable lines and 72/72 branches. This is not exhaustive behavior coverage or JavaScript coverage.
- `bin/setup` completed with locked dependencies, PostgreSQL preparation, 10,000 employees, 20,000 salary versions, and a production React build.
- Rails autoload verification passed. Ruby lint passed. npm dependency installation reported zero audit vulnerabilities.
- Docker image build and database startup passed. The HTTP readiness check verified the page, React bundle, CSRF-protected login, and 10,000-person directory on port 3300.
- A fresh silent walkthrough recording and browser screenshots are included under `docs/`.

## Reproduce

```sh
bin/setup
COVERAGE=1 bin/rails test
npm test --prefix frontend
bin/rubocop
bin/rails zeitwerk:check
```

`npm test` starts and stops its own Rails test server on port 3102. It resets only `salary_management_tdd_browser_test` and never the native development database or Docker review volume. PostgreSQL access and browser installation are required as documented in the README.

For the separate review container on port 3300:

```sh
APP_URL=http://127.0.0.1:3300 node script/smoke-http.mjs
```

This smoke test assumes a freshly seeded dataset and only reads employees/salaries. It signs in using `ADMIN_EMAIL`/`ADMIN_PASSWORD` or the documented local demo defaults.

## Limits

The tests are not a load test, cross-browser certification, backup/recovery exercise, or a substitute for human acceptance testing. A fresh Brakeman scan and hosted CI are not claimed in this rebuild record. The local Git branch must be published before reviewers can clone it. Local-only delivery still needs recruiter confirmation because the supplied brief requested hosting.
