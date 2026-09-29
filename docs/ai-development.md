# AI-assisted development record

The stakeholder provided the assessment and clarified PostgreSQL, React, annual/monthly CTC, named components, currency, and increment history. AI was used to inspect the scaffold, draft requirements, implement a prototype, and execute tests and browser checks.

The prototype was not consistently test-first. After this was discussed, the stakeholder selected a separate TDD-led second iteration. The prototype remains on `main`; this `tdd-rebuild` branch starts from the original requirements baseline. Tests and code from the prototype were deliberately used as a reference, with behavior specifications committed and run before their corresponding implementation was added to this branch. See [the TDD record](tdd.md) for actual failing and passing observations.

Examples of working instructions: preserve annual CTC as canonical; derive monthly equivalents using decimal arithmetic; enforce component reconciliation; preserve effective-dated versions; reject stale concurrent edits; isolate tests from review data; verify CSV rollback and formula escaping; record setup and test evidence honestly.

AI assistance does not replace understanding the code. Interview preparation should cover money precision, rounding, temporal salary selection, locking, authentication/CSRF, atomic CSV imports, reporting assumptions, and why a single Rails service serves React. The developer should review the implementation and explain trade-offs in their own words. No real employee data was used.
