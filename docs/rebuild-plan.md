# TDD-led second iteration

This branch starts from the requirements/scaffold commit `f29db7f`. The working prototype is preserved on `main` at `5436366` and is used as a reference. This is a second implementation informed by that prototype, not a rewritten claim about its development history.

## Process

For each slice, add behavior tests, execute them against missing behavior, record the failure, implement only that slice, then run the applicable suite before committing the passing implementation. Refactor after green. Separate red/green commits are local review artifacts; confirm the recruiter's preferred commit format before submission.

## Slices

1. PostgreSQL compensation model: money, versions, validation, concurrency, relational constraints.
2. HR sessions and employee directory/edit APIs.
3. Compensation recording and reporting APIs.
4. CSV import/export.
5. Deterministic 10,000-employee seed and repeatability.
6. React sign-in, directory, salary workflow, reports, and CSV workflows through browser tests.
7. Documented local setup and container verification.

## Isolation

The rebuild uses `salary_management_tdd_development`, `salary_management_tdd_test`, and a separately guarded browser-test database. It must not alter the prototype's native or Docker data.

## Questions awaiting recruiter clarification

- Whether strict test-first development and separate failing-test commits are expected.
- Whether reproducible local/Docker setup and a video can replace the brief's public-deployment requirement.
- CTC/payroll scope, reference FX expectations, correction/future-date rules, and approval workflow.

Until clarified, retain the prototype's documented compensation assumptions. Local-only delivery is the stakeholder's preference; recruiter acceptance is not yet established.

## Execution log

Infrastructure: Ruby 3.4.7, Rails 8.1.4, PostgreSQL configuration and reusable test builders. No salary functionality copied at this stage.

Domain slice: tests committed at `fd9f32d` before models/schema/services. Red command `bin/rails test test/models/compensation_test.rb`: 10 missing-User errors. Implementation reuses reviewed prototype domain code; it does not claim independent discovery. The complete domain suite is run before the implementation commit.

Sessions/directory slice: test commit `6639ec0`; red pagination scenario failed at sign-in with HTTP 404 before routes/controllers existed. Added session authentication, CSRF handling, employee filtering/pagination/editing and validation. Full suite verified before the green commit.

Salary/reporting slice: tests committed at `8ab8cfc`; red salary-create request returned 404 instead of 201. Added immutable salary recording with strict lock versions and exact per-currency reporting. Full suite verified before commit.
