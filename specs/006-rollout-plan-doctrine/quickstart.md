# Quickstart: Validating the Rollout Plan Doctrine

This guide validates `commands/brief-plan.md`'s doctrine content against the
three user stories in spec.md. It is a manual review + fixture-based
walkthrough — there is no application to build or run; the "system under
test" is the doctrine text itself, exercised by having an AI agent follow it
while running `/speckit.plan` against sample fixture `spec.md` files.

## Prerequisites

- `commands/brief-plan.md` updated per this feature's tasks.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1`)
  available and executable (delivered by Feature 003; unchanged here).
- A scratch feature directory to hold fixture `spec.md`/`plan.md` files,
  e.g. `specs/999-quickstart-fixture/` (delete after validation; do not
  commit).
- A fixture `spec.md` carrying a `## Delivery Considerations` marker with a
  candidate flag name and clarified rollout parameters (as if produced by
  Features 004-005), for Scenario 1. A second fixture `spec.md` with no
  marker and no rollout language planned for its `/plan` arguments, for
  Scenario 2. A third fixture `spec.md` with no marker, for Scenario 3
  (rollout language supplied via `/plan` arguments instead).

## Scenario 1 — Delivery Strategy for an already-flagged feature (User Story 1, P1)

1. Run `scripts/bash/rollout-gate.sh` against the marker-bearing fixture.
   **Expect**: `hasFlags=true`, note the reported flag name(s).
2. Using `commands/brief-plan.md` as the acting agent's briefing, run
   `/speckit.plan` against that fixture.
3. **Expect**: the resulting fixture `plan.md` contains a `## Delivery
   Strategy` section with a feature flag name, `Provider: LaunchDarkly`, a
   phased rollout sequence, targeting rules, telemetry gates, and rollback
   conditions.
4. Repeat using a fixture whose marker has only some rollout parameters
   clarified (e.g., phases and audience given, telemetry gates left open).
   **Expect**: the Delivery Strategy section is still complete — the agent
   proposes a reasonable draft value grounded in the spec's requirements for
   the missing telemetry-gates element rather than omitting it.
5. If a `templates/rollout-section.md` file is present in the extension,
   confirm the agent may consult it for structure but that removing it does
   not prevent a correct Delivery Strategy section from being produced
   (repeat step 2-3 without the file present, if convenient).

## Scenario 2 — Non-rollout feature untouched (User Story 2, P1)

1. Run `/speckit.plan` against the no-marker, no-rollout-language fixture.
2. **Expect**: the briefing emits a one-line no-op.
3. **Expect**: the resulting fixture `plan.md` contains no `## Delivery
   Strategy` section and no other rollout-related content.
4. Run `scripts/bash/rollout-gate.sh` against the fixture's `spec.md`.
   **Expect**: `hasFlags=false` (or exit code 2), confirming no marker was
   introduced by this plan pass.

## Scenario 3 — Late-introduced rollout intent at plan time (User Story 3, P2)

1. Confirm the fixture `spec.md` has no `## Delivery Considerations` marker
   (`hasFlags=false`/exit code 2 via the gate script).
2. Run `/speckit.plan` against that fixture, supplying `/plan` arguments
   that contain rollout language (e.g., cohort or percentage language, or
   phased-release language such as "release to 5% first").
3. **Expect**: the briefing back-fills a `## Delivery Considerations` marker
   into the fixture's `spec.md`, using the same heading and `Candidate
   flag(s):` label convention as Feature 004's doctrine.
4. Run `scripts/bash/rollout-gate.sh` against the fixture again. **Expect**:
   `hasFlags=true`, confirming the back-filled marker is recognized (mirrors
   the SC-003 verification pattern used in Feature 005).
5. **Expect**: in the same run, the resulting fixture `plan.md` contains a
   `## Delivery Strategy` section populated from the `/plan` arguments'
   rollout language and the spec's existing requirements.
6. Repeat with `/plan` arguments containing no rollout language against a
   no-marker fixture. **Expect**: no marker is written and the briefing
   proceeds exactly as in Scenario 2 (one-line no-op).

## Cross-cutting checks

- Across all scenarios, confirm the doctrine content itself (in
  `commands/brief-plan.md`) contains no task-breakdown instructions and no
  feature-flag-provider MCP interaction instructions (SC-004) — a plain
  read-through of the file is sufficient for this check.
- Confirm the doctrine content explicitly names `LaunchDarkly` as the
  provider within the Delivery Strategy section's instructions (unlike
  Features 004-005's doctrine, which forbid naming a provider) — a plain
  read-through of the file is sufficient for this check.
- Confirm the doctrine content does not require `templates/rollout-section.md`
  to exist (FR-008) — a plain read-through of the file is sufficient for
  this check.
- Clean up scratch fixture directories (e.g.
  `specs/999-quickstart-fixture/`) after validation; do not leave them in
  the repository.
