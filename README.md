# ACME People — salary management

A Rails 8.1 / React application backed by PostgreSQL for an HR team managing 10,000 employees across countries.

## Clone, set up, and run

Choose the native setup below to develop and run tests, or use [Docker](#optional-local-containers) to review the application without installing Ruby, Node.js, or PostgreSQL locally. Commands use a macOS/Linux shell; on Windows, use WSL2 or Docker Desktop.

Prerequisites:

- Git and Ruby **3.4.7** (the version in `.ruby-version`), with Bundler installed.
- Node.js **24** with npm.
- Native build tools and PostgreSQL client headers if Bundler needs to compile gems (for example, Xcode Command Line Tools and `libpq` on macOS, or `build-essential`, `libpq-dev`, and `libyaml-dev` on Ubuntu).
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
git clone --branch main https://github.com/prashant-funzing/salary-management.git
cd salary-management
# Use local development settings, not an inherited deployment database URL.
unset DATABASE_URL RAILS_ENV TEST_DATABASE
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

Run these commands from the repository root after native setup. Tests require local Ruby/Node dependencies; the production Docker image does not include test tools.

```sh
unset DATABASE_URL RAILS_ENV TEST_DATABASE APP_URL
RAILS_ENV=test bin/rails db:prepare
COVERAGE=1 bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/rails zeitwerk:check
npm run build --prefix frontend
npm audit --prefix frontend
cd frontend
npx playwright install chromium
npm test
cd ..
```

On Linux, if Chromium reports missing system libraries, run `npx playwright install --with-deps chromium` from `frontend/` (installing system packages may require administrator access).

Browser tests start their own Rails server on port 3102 and recreate synthetic records in the dedicated `salary_management_tdd_browser_test` database. The launcher explicitly removes `DATABASE_URL` and only clears that named database in test mode; it does not touch the development or Docker review databases. PostgreSQL must be running and the local role must have permission to create this test database. Do not run two browser suites concurrently against the same database.

The browser suite covers desktop search/pagination/history, successful employee and salary changes, increment history, CSV import/export, validation errors, sign-out, mobile layout, and keyboard dialog dismissal. Set `APP_URL` to check an existing seeded app instead; data-writing tests are skipped in that mode. UI screenshots and videos go to ignored `frontend/test-results/` so routine tests do not change the committed demo artifacts.

Rails tests cover exact money rules, temporal history, simultaneous/stale writes, database constraints, authentication/CSRF/throttling, employee filters/editing, CSV rollback and limits, reporting, and full seed repeatability. `COVERAGE=1` writes line/branch coverage for loaded application files to `tmp/test-coverage.json`. See the [test coverage matrix](docs/test-coverage.md) for scenarios and limits. GitHub Actions runs both suites with PostgreSQL.

## Optional local containers

Install Docker with the Compose v2 plugin (Docker Desktop includes both), and start its daemon. The image builds React and runs Rails with PostgreSQL in a separate container. No local Ruby, Node.js, or PostgreSQL installation is needed for this path.

Clone the repository as shown above, then run the following from its root. Create `.env.docker` once; preserve it for subsequent starts. The generated database password is hexadecimal so it is safe in the configured database URL.

```sh
# Requires openssl, available on most macOS/Linux installations.
(umask 077; cat > .env.docker <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 24)
SECRET_KEY_BASE=$(openssl rand -hex 64)
ADMIN_EMAIL=hr@acme.example
ADMIN_PASSWORD=AcmeDemo2026!
WEB_PORT=3100
EOF
)
docker compose --env-file .env.docker up --build -d
docker compose --env-file .env.docker logs -f web
```

Wait for Rails to report that it is listening on port 3000 inside the container, then open **http://localhost:3100**. The entrypoint prepares the database and Rails seeds a newly initialized database automatically. Sign in with the credentials in `.env.docker`. Ctrl+C exits log viewing without stopping the containers.

To explicitly rerun the safe seed script, stop the application, or start it again:

```sh
docker compose --env-file .env.docker exec web bin/rails db:seed
docker compose --env-file .env.docker stop
docker compose --env-file .env.docker up -d
```

PostgreSQL data persists in a named volume. `docker compose down` retains it; adding `--volumes` deletes that data. Keep the same Compose project/directory and database password when restarting. If port 3100 is occupied, change `WEB_PORT` in `.env.docker`. The file is ignored by Git and is not included in a clone.

These containers bind only to the local machine and disable HTTPS for local review. The sample admin password is for synthetic local data. AWS EC2 deployment and its HTTPS/secrets configuration are planned separately.

## Artifacts and limits

- [One-page requirements](docs/requirements.md)
- [Recruiter clarification draft](docs/recruiter-questions.md)
- [Architecture and trade-offs](docs/architecture.md)
- [AI development record](docs/ai-development.md)
- [Recorded verification results](docs/verification.md)
- [Demo walkthrough](docs/demo.md)
- [UI screenshots](docs/screenshots/)

This is a single-organization HR application. Payroll, taxes, statutory deductions, payslips, employee self-service, approval chains, live FX, and performance-review scoring are excluded. Historical reporting uses today's active workforce and the salary effective on the selected date. Salary corrections require a new date; same-day replacement is deliberately disallowed. History is application-immutable, not a tamper-proof compliance ledger. Login throttling uses a single-process cache; shared throttling/SSO and production backup/restore drills are follow-up operational work. Delivery is a repository with written setup instructions, seeds, tests, and a local demo; no hosted instance is required.
