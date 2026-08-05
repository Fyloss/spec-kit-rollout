# Quickstart: Validating the Rollout Analyze Doctrine

This guide validates `commands/brief-analyze.md`'s doctrine content against
the four user stories in spec.md. It is a manual review + fixture-based
walkthrough — there is no application to build or run; the "system under
test" is the doctrine text itself, exercised by having an AI agent follow it
while running `/speckit.analyze` against sample fixture
`spec.md`/`plan.md`/`tasks.md` files.

## Prerequisites

- `commands/brief-analyze.md` updated per this feature's tasks.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1`)
  available and executable (delivered by Feature 003; unchanged here).
- A scratch feature directory to hold fixture
  `spec.md`/`plan.md`/`tasks.md` files, e.g.
  `specs/999-quickstart-fixture/` (delete after validation; do not commit).
- Fixture A: a `spec.md` with a `## Delivery Considerations` marker, a
  `plan.md` with a complete `## Delivery Strategy` section, and a `tasks.md`
  with the corresponding six rollout tasks (Feature 007 shape), for
  Scenario 1.
- Fixture B: a `spec.md` with no marker, for Scenario 2.
- Fixture C: a `spec.md` with a marker but a `plan.md` with no `## Delivery
  Strategy` section, for Scenario 3.
- Fixture D: a `spec.md` with a marker, a `plan.md` with a complete
  `## Delivery Strategy` section, but a `tasks.md` with no rollout tasks,
  for Scenario 4.

## Scenario 1 — Consistent rollout chain reports no false orphans (User Story 1, P1)

1. Run `scripts/bash/rollout-gate.sh` against Fixture A's `spec.md`.
   **Expect**: `hasFlags=true`.
2. Confirm Fixture A's `plan.md` contains a `## Delivery Strategy` section
   and Fixture A's `tasks.md` contains at least one of the six rollout task
   categories.
3. Using `commands/brief-analyze.md` as the acting agent's briefing, run
   `/speckit.analyze` against Fixture A.
4. **Expect**: the report contains zero findings that treat the marker, the
   Delivery Strategy section, or any rollout task as an orphaned
   requirement, unmapped task, duplication, or ambiguity.
5. **Expect**: the report's Coverage Summary and Unmapped Tasks sections
   exclude the marker, the Delivery Strategy section, and the rollout tasks
   from being counted as gaps.

## Scenario 2 — Non-rollout feature analyze unaffected (User Story 2, P1)

1. Run `scripts/bash/rollout-gate.sh` against Fixture B's `spec.md`.
   **Expect**: `hasFlags=false` (or exit code 2).
2. Run `/speckit.analyze` against Fixture B.
3. **Expect**: the briefing emits a one-line no-op message.
4. **Expect**: the rest of the analyze report contains no rollout-chain
   finding of any kind and is identical to what it would be without the
   extension installed.

## Scenario 3 — Detect a chain broken between spec and plan (User Story 3, P2)

1. Run `scripts/bash/rollout-gate.sh` against Fixture C's `spec.md`.
   **Expect**: `hasFlags=true`.
2. Confirm Fixture C's `plan.md` contains no `## Delivery Strategy` section.
3. Run `/speckit.analyze` against Fixture C.
4. **Expect**: the report contains exactly one rollout-chain finding
   stating the marker is present but the Delivery Strategy section is
   missing from `plan.md`, at HIGH severity.
5. **Expect**: the finding is not worded or categorized as if the marker
   itself were orphaned or untraceable — the gap is the missing plan
   content, not the spec marker.

## Scenario 4 — Detect a chain broken between plan and tasks (User Story 4, P2)

1. Run `scripts/bash/rollout-gate.sh` against Fixture D's `spec.md`.
   **Expect**: `hasFlags=true`.
2. Confirm Fixture D's `plan.md` contains a complete `## Delivery Strategy`
   section and Fixture D's `tasks.md` contains no rollout tasks.
3. Run `/speckit.analyze` against Fixture D.
4. **Expect**: the report contains exactly one rollout-chain finding
   stating the Delivery Strategy is present but no rollout tasks exist in
   `tasks.md`, at HIGH severity.
5. **Expect**: this finding is distinguishable in wording and location from
   the Scenario 3 finding, so a reader can tell which link in the chain is
   broken.

## Cross-cutting checks

- Across all scenarios, confirm the doctrine content itself (in
  `commands/brief-analyze.md`) contains no instruction to edit `spec.md`,
  `plan.md`, or `tasks.md` to fix any detected gap (FR-010) — a plain
  read-through of the file is sufficient for this check.
- Confirm the doctrine content requires the gate script's default
  (spec.md-only) mode, not a new/extended mode (FR-001) — a plain
  read-through of the file is sufficient for this check.
- Confirm the two chain-break findings (Scenario 3, Scenario 4) are worded
  distinguishably from each other in the doctrine's own instructions, not
  just assumed to differ at runtime (FR-005, FR-007, FR-009).
- Confirm repeated `/speckit.analyze` runs on the same unchanged fixture
  produce identical rollout-chain finding wording and count (SC-005,
  determinism check).
- Clean up scratch fixture directories (e.g.
  `specs/999-quickstart-fixture/`) after validation; do not leave them in
  the repository.
