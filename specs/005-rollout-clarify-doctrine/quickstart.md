# Quickstart: Validating the Rollout Clarify Doctrine

This guide validates `commands/brief-clarify.md`'s doctrine content against
the three user stories in spec.md. It is a manual review + fixture-based
walkthrough — there is no application to build or run; the "system under
test" is the doctrine text itself, exercised by having an AI agent follow it
while running `/speckit.clarify` against a sample fixture `spec.md`.

## Prerequisites

- `commands/brief-clarify.md` updated per this feature's tasks.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1`)
  available and executable (delivered by Feature 003; unchanged here).
- A scratch feature directory to hold fixture `spec.md` files, e.g.
  `specs/999-quickstart-fixture/` (delete after validation; do not commit).
- A fixture `spec.md` carrying a `## Delivery Considerations` marker with
  only a candidate flag name and a brief rollout-intent statement (as if
  written by Feature 004's doctrine but not yet clarified), for Scenarios 1
  and 3. A second fixture `spec.md` with no marker at all, for Scenario 2.

## Scenario 1 — Elicit missing rollout parameters (User Story 1, P1)

1. Run `scripts/bash/rollout-gate.sh` against the marker-bearing fixture.
   **Expect**: `hasFlags=true`, note the reported flag name(s).
2. Using `commands/brief-clarify.md` as the acting agent's briefing, run
   `/speckit.clarify` against that fixture.
3. **Expect**: the agent asks about the rollout phases, target
   audience/segments, percentages, telemetry gates, and rollback conditions
   not already present in the marker.
4. Answer the questions (answer some, decline at least one, per Scenario 4
   below in the same pass if convenient).
5. **Expect**: the `## Delivery Considerations` section is updated in place
   with the clarified details — same heading, same `Candidate flag(s):`
   line and value, no duplicate section, no relocation elsewhere in the
   fixture `spec.md`.
6. Run the gate script again against the fixture. **Expect**:
   `hasFlags=true` with the identical candidate flag name(s) as step 1
   (confirms SC-003).

## Scenario 2 — Non-rollout feature untouched (User Story 2, P1)

1. Run `/speckit.clarify` against the no-marker fixture.
2. **Expect**: the briefing emits a one-line no-op; no rollout-related
   questions are asked.
3. **Expect**: the resulting fixture `spec.md` contains no
   `## Delivery Considerations` section and no other rollout-related
   content.

## Scenario 3 — Sparse marker survives clarify's normal instincts (User Story 3, P2)

1. Using the same sparse marker-bearing fixture as Scenario 1 (before any
   clarification), run `/speckit.clarify`.
2. **Expect**: the section is not deleted, shortened, or reworded into a
   generic ambiguity note; the original candidate flag name(s) and
   rollout-intent statement remain present verbatim or near-verbatim.
3. Answer only some of the elicitation questions (e.g., phases and
   audience, but not telemetry gates).
4. **Expect**: the marker contains at least the original content plus the
   newly clarified phases/audience detail; telemetry gates remain
   unspecified rather than invented, and the marker is not flagged as an
   unresolved ambiguity requiring removal.

## Scenario 4 — Declining a specific question

1. During any of the above runs, decline to answer one specific rollout
   elicitation question (e.g., rollback conditions).
2. **Expect**: that parameter is left unspecified in the refined marker
   (or noted as still open); no value is invented for it, and the rest of
   clarify's flow (including its normal non-rollout questions) continues
   uninterrupted.

## Cross-cutting checks

- Across all scenarios, confirm the doctrine content itself (in
  `commands/brief-clarify.md`) never mentions a specific feature-flag
  provider name (SC-004), and never includes `Delivery Strategy` wording
  or plan/tasks-phase content, or provider/MCP interaction instructions
  (FR-010) — a plain read-through of the file is sufficient for this check.
- Confirm the doctrine content does not instruct suppressing or skipping
  clarify's other, non-rollout questions (FR-011) — a plain read-through
  of the file is sufficient for this check.
- Clean up scratch fixture directories (e.g.
  `specs/999-quickstart-fixture/`) after validation; do not leave them in
  the repository.
