# TDD-led second iteration

This branch is a second implementation informed by the prototype preserved on `main` at `5436366`. It starts at the original requirements/scaffold commit `f29db7f`. Existing tests and implementation were reviewed and reused as a reference. This is not a claim that the prototype was developed test-first, nor that the second iteration was designed without that knowledge.

For each slice below, tests were introduced and executed before its implementation was added to this branch. Each red result was observed, not inferred. The corresponding green commit followed a passing applicable suite. Formatting and documentation changes do not imply new behavior tests.

| Slice | Test commit | Observed red result | Green commit / result |
| --- | --- | --- | --- |
| Compensation domain | `fd9f32d` | 10 missing-model errors | `27dcf37`: 26 tests pass |
| HR sessions and directory | `6639ec0` | Sign-in returned 404 in the directory scenario | `a056811`: 40 tests pass |
| Salary API and reporting | `8ab8cfc` | Salary creation returned 404 instead of 201 | `89c8846`: 55 tests pass |
| CSV import/export | `781768e` | Missing import service | `8e737de`: 68 tests pass |
| Deterministic seeds | `bb0e1a2` | Expected 10,000 employees; got 0 | `d5f3e18`: 69 tests pass |
| React sign-in/session | `24362ed` | Email field absent; no UI/root page | `e9c3009`: browser sign-in test passes |
| HR workspace | `d395836` | Directory heading absent after sign-in | `c901c2d`: all six browser tests pass |
| Container readiness | `72c4593` | Port 3300 refused connection before the new stack was started | Final setup commit records successful container smoke check |

The backend uses exact money tests, effective-date examples, concurrency tests, database constraints, authorization/request tests, and seed-repeatability tests. Browser tests use a disposable `salary_management_tdd_browser_test` database with CSRF protection enabled. [The coverage matrix](test-coverage.md) describes scope and limitations.

## What this evidence does and does not establish

The branch demonstrates an observable test-before-implementation integration sequence using a prior prototype. Some slices—particularly the HR workspace—are broader than an ideal smallest red/green cycle. Do not describe this as an independently discovered, from-scratch TDD exercise. The existing prototype's history is preserved, not rewritten or backdated.

For new requirements, write the smallest failing behavior test first, implement only enough to pass, then refactor with green tests. Confirm with the recruiter whether they want explicit failing-test commits or self-contained green feature commits. Keep their guidance with the submission artifacts.

Refactor after green: strict version parsing moved from the compensation-recording service to shared `LockVersion`, so employee editing no longer depends on an unrelated workflow service. Existing 69 backend tests still pass; no behavior change was intended.
