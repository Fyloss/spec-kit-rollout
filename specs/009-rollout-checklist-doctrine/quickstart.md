# Quickstart: Validating the Rollout Checklist Doctrine

This guide validates `commands/brief-checklist.md`'s doctrine content
against the three user stories in spec.md. It is a manual review +
fixture-based walkthrough — there is no application to build or run; the
"system under test" is the doctrine text itself, exercised by having an AI
agent follow it while running `/speckit.checklist` against sample fixture
`spec.md`/`plan.md` files.

## Prerequisites

- `commands/brief-checklist.md` updated per this feature's tasks.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1`)
  available and executable (delivered by Feature 003; unchanged here).
- A scratch feature directory to hold fixture `spec.md`/`plan.md` files,
  e.g. `specs/999-quickstart-fixture/` (delete after validation; do not
  commit).
- Fixture A: a `spec.md` with a `## Delivery Considerations` marker and a
  `plan.md` with a complete `## Delivery Strategy` section, for Scenario 1.
- Fixture B: a `spec.md` with no marker, for Scenario 2.
- Fixture C: a `spec.md` with a `## Delivery Considerations` marker and no
  `plan.md` (or a `plan.md` with no `## Delivery Strategy` section), for
  Scenario 3.

## Scenario 1 — Add rollout-quality checklist items to a flagged feature (User Story 1, P1)

1. Run `scripts/bash/rollout-gate.sh` against Fixture A's `spec.md`.
   **Expect**: `hasFlags=true`.
2. Using `commands/brief-checklist.md` as the acting agent's briefing, run
   `/speckit.checklist` against Fixture A (any checklist focus request,
   e.g., "generate a UX checklist").
3. **Expect**: the resulting checklist file contains a rollout-quality
   category with items covering flag naming, environments/targeting,
   telemetry gates, rollback conditions, and rollout phase
   ordering/completeness — in addition to the UX category the user
   requested.
4. **Expect**: each rollout-quality item is phrased as a requirements-quality
   question (e.g., "Is the feature flag name specific and unambiguous?"),
   not as an implementation-verification statement, consistent with the
   format of the other categories in the same checklist file.
5. **Expect**: the rollout-quality items are worded to be checked against
   Fixture A's actual Delivery Strategy content (flag name, environments,
   telemetry gates, rollback conditions, phases), not generic boilerplate.

## Scenario 2 — Non-rollout feature gets no rollout checklist items (User Story 2, P1)

1. Run `scripts/bash/rollout-gate.sh` against Fixture B's `spec.md`.
   **Expect**: `hasFlags=false` (or exit code 2).
2. Run `/speckit.checklist` against Fixture B.
3. **Expect**: the briefing emits a one-line no-op message.
4. **Expect**: the resulting checklist file contains no rollout-quality
   category and no rollout-related item of any kind.

## Scenario 3 — Rollout items still appear before the Delivery Strategy exists (User Story 3, P2)

1. Run `scripts/bash/rollout-gate.sh` against Fixture C's `spec.md`.
   **Expect**: `hasFlags=true`.
2. Confirm Fixture C has no `plan.md`, or a `plan.md` with no `## Delivery
   Strategy` section.
3. Run `/speckit.checklist` against Fixture C.
4. **Expect**: the rollout-quality category is still added with all five
   items.
5. **Expect**: none of the items assert that the Delivery Strategy is
   missing or incomplete — they are phrased as checks to perform once the
   plan exists, not as findings.

## Cross-cutting checks

- Across all scenarios, confirm the doctrine content itself (in
  `commands/brief-checklist.md`) contains no instruction to author Delivery
  Strategy content, invoke any provider MCP tool, or add any checklist
  category other than the rollout-quality one (FR-010) — a plain
  read-through of the file is sufficient for this check.
- Confirm the doctrine requires the gate script's default (spec.md-only)
  mode (FR-001) — a plain read-through of the file is sufficient for this
  check.
- Confirm the doctrine instructs a single shared rollout-quality category
  even when the marker names multiple candidate flags (FR-008) — construct
  a fixture with two flag names and confirm only one category (not two) is
  produced.
- Confirm the doctrine never instructs removing, replacing, or reordering
  any other checklist category (FR-009) — a plain read-through of the file
  is sufficient for this check.
- Run `scripts/bash/rollout-gate.sh` against each fixture's `spec.md` before
  and after `/speckit.checklist` runs to confirm `hasFlags`/`flags` parity,
  confirming the briefing never mutates `spec.md` as a side effect.
- Clean up scratch fixture directories (e.g.
  `specs/999-quickstart-fixture/`) after validation; do not leave them in
  the repository.
