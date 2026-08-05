# Quickstart: Validating the Rollout Tasks Doctrine

This guide validates `commands/brief-tasks.md`'s doctrine content against
the three user stories in spec.md. It is a manual review + fixture-based
walkthrough — there is no application to build or run; the "system under
test" is the doctrine text itself, exercised by having an AI agent follow it
while running `/speckit.tasks` against sample fixture `spec.md`/`plan.md`
files.

## Prerequisites

- `commands/brief-tasks.md` updated per this feature's tasks.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1`)
  available and executable (delivered by Feature 003; unchanged here).
- A scratch feature directory to hold fixture `spec.md`/`plan.md`/`tasks.md`
  files, e.g. `specs/999-quickstart-fixture/` (delete after validation; do
  not commit).
- Fixture A: a `spec.md` with a `## Delivery Considerations` marker and a
  `plan.md` with a complete `## Delivery Strategy` section (flag name,
  provider, phased rollout, targeting, telemetry gates, rollback), for
  Scenario 1.
- Fixture B: a `spec.md` with no marker, for Scenario 2.
- Fixture C: a `spec.md` with a marker but a `plan.md` with no `## Delivery
  Strategy` section, for Scenario 3.

## Scenario 1 — Emit ordered rollout tasks from an existing Delivery Strategy (User Story 1, P1)

1. Run `scripts/bash/rollout-gate.sh` against Fixture A's `spec.md`.
   **Expect**: `hasFlags=true`, note the reported flag name(s).
2. Confirm Fixture A's `plan.md` contains a `## Delivery Strategy` section.
3. Using `commands/brief-tasks.md` as the acting agent's briefing, run
   `/speckit.tasks` against Fixture A.
4. **Expect**: the resulting fixture `tasks.md` contains six ordered rollout
   tasks — create the feature flag, configure environments, configure
   targeting rules, integrate the application SDK, add telemetry
   validation, define rollback conditions — each traceable to the specific
   value already written in the Delivery Strategy section (not language
   re-derived from `spec.md`'s requirements text).
5. Repeat using a fixture `plan.md` whose Delivery Strategy section names
   two candidate flags. **Expect**: the six-task pattern is repeated once
   per flag, each set clearly scoped to its own flag name — not merged into
   one ambiguous task set.
6. Repeat using a fixture `plan.md` whose Delivery Strategy section is only
   partially populated (e.g., rollback conditions omitted). **Expect**:
   tasks are emitted only for the elements actually present; no fabricated
   rollback task appears.

## Scenario 2 — Leave a non-rollout feature's tasks untouched (User Story 2, P1)

1. Run `scripts/bash/rollout-gate.sh` against Fixture B's `spec.md`.
   **Expect**: `hasFlags=false` (or exit code 2).
2. Run `/speckit.tasks` against Fixture B.
3. **Expect**: the briefing emits a one-line no-op message.
4. **Expect**: the resulting fixture `tasks.md` contains no rollout tasks
   and no other rollout-related content.

## Scenario 3 — Withhold rollout tasks when the plan has no Delivery Strategy (User Story 3, P2)

1. Run `scripts/bash/rollout-gate.sh` against Fixture C's `spec.md`.
   **Expect**: `hasFlags=true`.
2. Confirm Fixture C's `plan.md` contains no `## Delivery Strategy` section.
3. Run `/speckit.tasks` against Fixture C.
4. **Expect**: the briefing emits a one-line status message reporting the
   missing Delivery Strategy (distinct wording from Scenario 2's no-op
   message) and adds zero rollout tasks.
5. **Expect**: the resulting fixture `tasks.md` contains no task whose
   content was derived from `spec.md`'s requirements text as a substitute
   for the missing Delivery Strategy.

## Cross-cutting checks

- Across all scenarios, confirm the doctrine content itself (in
  `commands/brief-tasks.md`) contains no instruction to invoke a provider
  MCP tool or execute a live provider action (FR-011) — a plain
  read-through of the file is sufficient for this check.
- Confirm the doctrine content instructs consulting `spec.md` only through
  the gate script's state output, never mining it directly for rollout task
  content (FR-007) — a plain read-through of the file is sufficient for
  this check.
- Confirm the doctrine content specifies the fixed task order (flag →
  environments/targeting → SDK → telemetry → rollback) rather than an
  order dependent on the Delivery Strategy section's own field order
  (FR-008) — a plain read-through of the file is sufficient for this check.
- Clean up scratch fixture directories (e.g.
  `specs/999-quickstart-fixture/`) after validation; do not leave them in
  the repository.
