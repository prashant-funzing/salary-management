# Test coverage matrix

Tests are organized by behavior, with shared deterministic builders in `test/support/salary_test_data.rb`. PostgreSQL-backed Rails tests use transactions except the simultaneous-write test, which explicitly cleans up its own committed records. Seeds are exercised inside a rolled-back test transaction. Browser writes use a separately named disposable database.

| Area | Scenarios | Evidence |
| --- | --- | --- |
| Sessions and access | Anonymous token/session, every private endpoint, wrong/unknown credentials, normalized login, logout, throttling and expiry, successful-login reset, CSRF rejection | `test/integration/sessions_api_test.rb`, `hr_workflow_test.rb` |
| Employee directory | Pagination, empty/out-of-range page, stable ordering, name/email/code search, escaped wildcard/injection-shaped search, all filters, distinct options, missing records | `test/integration/employees_api_test.rb` |
| Employee editing | Required fields, normalized email uniqueness, invalid status/email, stale/missing/malformed/fractional versions, malformed request shapes | `test/models/employee_test.rb`, `test/integration/employees_api_test.rb` |
| Money and components | 12 LPA / 1 lakh monthly, exact reconciliation, invalid/non-finite totals, currency precision, shape/size/name validation, positive and negative rounding adjustment, seven supported currencies | `test/models/compensation_test.rb`, `compensation_validation_test.rb` |
| Salary history | Current/future/effective-date boundary, backdated insertion, currency changes, employee isolation, immutable versions, preserved actor/reason, duplicate dates | Model tests and `test/integration/compensations_api_test.rb` |
| Concurrent writes | Two simultaneous writers produce exactly one version and one conflict; failed writes leave version/count unchanged | `test/services/concurrent_compensation_test.rb`, compensation API tests |
| Database constraints | Duplicate employee/date, invalid status/currency/non-positive CTC, employee foreign key, deletion restriction | `test/models/database_constraints_test.rb`, `employee_test.rb` |
| Reporting | Empty/filtered results, unpaid/active/inactive headcount, current versus future salaries, all grouping dimensions and allowlist, invalid dates, odd/even exact median, separate currencies, labeled reference conversion | `test/integration/reports_api_test.rb`, `hr_workflow_test.rb` |
| CSV | Success, duplicate rerun, atomic rollback, invalid JSON/headers/quoting, BOM/CRLF, byte/row/error limits, current salary export, filtered download, unpaid employees, formula escaping | `test/services/employee_csv_validation_test.rb`, `test/services_employee_csv_test.rb`, `test/integration/transfers_api_test.rb` |
| Seed data | Exactly 10,000 employees / 20,000 versions initially, seven currencies, all component sums, repeatability preserving HR edits/password/history | `test/services/seeds_test.rb` |
| Browser flows | Desktop/mobile, search/pagination/history/reports, employee creation/edit, salary/increment saves, invalid breakdown, CSV import/export, login failure/logout, Escape/focus restoration | `frontend/tests/` |

## Reproduce

```sh
COVERAGE=1 bin/rails test
npm run build --prefix frontend
npm test --prefix frontend
```

The browser suite manages its test server on port 3102 and only resets `salary_management_tdd_browser_test`. An external `APP_URL` disables the write tests. Coverage JSON is written to ignored `tmp/test-coverage.json`; screenshots/videos are written under ignored `frontend/test-results`.

## Interpretation and limits

Line/branch coverage reports loaded application files, not every possible input combination. The matrix does not claim exhaustive testing, full JavaScript branch coverage, every browser engine, load capacity, disaster recovery, or external service availability. Browser coverage uses Chromium. The concurrency test exercises the salary-write conflict, not a sustained load test. Human acceptance testing remains useful.

Test coverage describes current verified behavior; it does not establish a test-first development history.
