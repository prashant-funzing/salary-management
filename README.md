# ACME People — salary management

A Rails 8.1 / React application backed by PostgreSQL for an HR team managing 10,000 employees across countries. This `tdd-rebuild` branch is a test-first second iteration using the original prototype as a reference; see the [TDD execution record](docs/tdd.md).

## Clone, set up, and run

Publish the `tdd-rebuild` branch before sharing these clone instructions with reviewers. The local branch alone is not available on GitHub.

Prerequisites:

- Git and Ruby **3.4.7** (the version in `.ruby-version`), with Bundler installed.
- Node.js **24** with npm.
- PostgreSQL **16**, running and accepting connections on `127.0.0.1:5432`.
- A PostgreSQL role that can create the development and test databases. The default role is your OS username. If your installation uses another role, export its connection settings before setup:

```sh
export PGUSER=postgres
export PGPASSWORD='your-local-postgres-password'
export PGHOST=127.0.0.1
export PGPORT=5432
```

Use the role/password configured on your own PostgreSQL installation; these are not application login credentials. If PostgreSQL uses local trust authentication, `PGPASSWORD` can be omitted. The application reads these environment variables directly; it does not automatically load a `.env` file.

```sh
git clone --branch tdd-rebuild https://github.com/prashant-funzing/salary-management.git
cd salary-management
bin/setup
bin/rails server -p 3100
```

`bin/setup` installs Ruby and frontend dependencies, prepares PostgreSQL databases, seeds demo data, and builds React. It can be rerun without resetting existing data. Alternatively, run each step manually:

```sh
bundle install
npm ci --prefix frontend
bin/rails db:prepare
bin/rails db:seed
npm run build --prefix frontend
```

Open **http://localhost:3100** and sign in:

| Email | Password |
| --- | --- |
| `hr@acme.example` | `AcmeDemo2026!` |

On a fresh database, seeds create **10,000 employees** and **20,000 salary versions** across seven countries/currencies. These are synthetic local demo credentials and records. Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` before the first setup to use different credentials. Seed reruns preserve existing passwords, employee edits, and salary history; they do not reset the database or remove employees you add.

After setup, only `bin/rails server -p 3100` is needed to run the built application. Stop it with Ctrl+C. No hosting account or cloud service is required.

### Working on the React UI

For hot reload, use two terminals from the repository root:

```sh
# Terminal 1
bin/rails server -p 3000

# Terminal 2
npm run dev --prefix frontend
```

Open **http://127.0.0.1:5173/app/** (or the port printed by Vite). Vite proxies `/api` to Rails on port 3000. Use the Vite URL consistently when signing in. For the single-server workflow, rebuild with `npm run build --prefix frontend` after frontend changes.

### Troubleshooting

- **PostgreSQL connection refused:** start your local PostgreSQL service and check `PGHOST`/`PGPORT`.
- **Role does not exist / password authentication failed:** set `PGUSER`/`PGPASSWORD` to a valid local role.
- **Permission denied to create database:** use a role with `CREATEDB`, or ask your local database administrator to create `salary_management_tdd_development` and `salary_management_tdd_test` owned by your application role.
- **Ruby version mismatch:** install/select Ruby 3.4.7 with your Ruby version manager before `bundle install`.
- **Missing React page or old UI:** run `npm ci --prefix frontend` and `npm run build --prefix frontend`.
- **Port already in use:** choose another Rails port, for example `bin/rails server -p 3200`. In hot-reload mode, update the API target in `frontend/vite.config.js` if changing Rails from port 3000.

## What works

- HR sign-in, sign-out, session cookies, CSRF protection, and authenticated salary endpoints.
- Searchable, filtered, paginated employee directory; create/edit employees and mark inactive.
- Annual CTC and monthly equivalents, configurable annual components, and currency-aware rounding. INR 12 LPA = INR 1 lakh per month. Monthly values represent CTC, not take-home pay.
- Effective-dated salary versions, scheduled changes, increment percentages, actor/reason history, and conflict detection for stale edits.
- Headcount, annual spend, median, and department/country/level breakdowns. Original currencies remain separate. An explicitly illustrative INR planning total uses visible fixed demo rates, not real market FX.
- Atomic CSV import for **new** employees plus initial compensation; errors identify rows and roll back all changes. Filtered export and [template](public/import-template.csv). Components are JSON in one CSV column. Formula-like text is escaped on export. Existing employees must be edited in the UI; exports are not an upsert/restore format.
- Deterministic seed: 10,000 synthetic employees, seven currencies, 20,000 salary versions. No real personnel data.

## Verify

```sh
COVERAGE=1 bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/rails zeitwerk:check
npm run build --prefix frontend
npm audit --prefix frontend
cd frontend
npx playwright install chromium
npm test
```

Browser tests start their own Rails server on port 3102 and recreate synthetic records in the dedicated `salary_management_tdd_browser_test` database. The launcher explicitly removes `DATABASE_URL` and only clears that named database in test mode; it does not touch the development or Docker review databases. PostgreSQL must be running and the local role must have permission to create this test database. Do not run two browser suites concurrently against the same database.

The browser suite covers desktop search/pagination/history, successful employee and salary changes, increment history, CSV import/export, validation errors, sign-out, mobile layout, and keyboard dialog dismissal. Set `APP_URL` to check an existing seeded app instead; data-writing tests are skipped in that mode. UI screenshots and videos go to ignored `frontend/test-results/` so routine tests do not change the committed demo artifacts.

Rails tests cover exact money rules, temporal history, simultaneous/stale writes, database constraints, authentication/CSRF/throttling, employee filters/editing, CSV rollback and limits, reporting, and full seed repeatability. `COVERAGE=1` writes line/branch coverage for loaded application files to `tmp/test-coverage.json`. See the [test coverage matrix](docs/test-coverage.md) for scenarios and limits. GitHub Actions runs both suites with PostgreSQL.

## Optional local containers

The native setup above is the documented, verified path. [compose.yml](compose.yml) and [Dockerfile](Dockerfile) are optional local container tooling. They require a running Docker daemon and the environment variables `POSTGRES_PASSWORD`, `SECRET_KEY_BASE`, and `ADMIN_PASSWORD`. Generate a secret with `bin/rails secret`, then run `docker compose up --build` and open port 3100. Set `WEB_PORT` to use another port. PostgreSQL data is persisted in a named volume.

A local, ignored `.env.docker` file can supply these settings. To review this branch alongside another running stack, select a separate Compose project and port:

```sh
WEB_PORT=3300 docker compose -p salary_management_tdd --env-file .env.docker up --build -d
docker compose -p salary_management_tdd --env-file .env.docker logs -f web
docker compose -p salary_management_tdd --env-file .env.docker stop
```

The ignored file is not included in a clone; new users should provide the environment variables described above. Hosting and public deployment are outside the agreed delivery scope.

## Artifacts and limits

- [One-page requirements](docs/requirements.md)
- [TDD execution record](docs/tdd.md)
- [Recruiter clarification draft](docs/recruiter-questions.md)
- [Architecture and trade-offs](docs/architecture.md)
- [AI development record](docs/ai-development.md)
- [Verification and performance](docs/verification.md)
- [Demo walkthrough](docs/demo.md)
- [UI screenshots](docs/screenshots/)

This is a single-organization HR application. Payroll, taxes, statutory deductions, payslips, employee self-service, approval chains, live FX, and performance-review scoring are excluded. Historical reporting uses today's active workforce and the salary effective on the selected date. Salary corrections require a new date; same-day replacement is deliberately disallowed. History is application-immutable, not a tamper-proof compliance ledger. Login throttling uses a single-process cache; shared throttling/SSO and production backup/restore drills are follow-up operational work. Delivery is a repository with written setup instructions, seeds, tests, and a local demo; no hosted instance is required.
