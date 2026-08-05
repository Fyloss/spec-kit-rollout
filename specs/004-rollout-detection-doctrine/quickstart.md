# Quickstart: Validating the Rollout Detection Doctrine

This guide validates `commands/brief-specify.md`'s doctrine content against
the four user stories in spec.md. It is a manual review + fixture-based
walkthrough — there is no application to build or run; the "system under
test" is the doctrine text itself, exercised by having an AI agent follow it
while producing a `spec.md` for a sample feature description.

## Prerequisites

- `commands/brief-specify.md` updated per this feature's tasks.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1`)
  available and executable (delivered by Feature 003; unchanged here).
- A scratch feature directory to hold fixture `spec.md` files, e.g.
  `specs/999-quickstart-fixture/` (delete after validation; do not commit).

## Scenario 1 — Clear rollout candidate (User Story 1, P1)

1. Using `commands/brief-specify.md` as the acting agent's briefing, run
   `/speckit.specify` with a description containing unambiguous signals,
   e.g.: *"Roll out the new checkout flow to 5% of production traffic
   first, then expand by country."*
2. **Expect**: the agent proposes rollout framing and writes a
   `## Delivery Considerations` section into the fixture's `spec.md`
   containing a `Candidate flag(s):` line and a rollout-intent statement.
3. Verify no feature-flag provider name (e.g., "LaunchDarkly") appears
   anywhere in the fixture `spec.md`.
4. Run:

   ```bash
   SPECIFY_FEATURE_DIRECTORY=specs/999-quickstart-fixture scripts/bash/rollout-gate.sh
   ```

   **Expect**: `hasFlags=true`, `flags=<the proposed candidate flag name(s)>`,
   `source=spec.md`. (Confirms SC-003.)

## Scenario 2 — Trivial feature, untouched (User Story 2, P1)

1. Run `/speckit.specify` with a description containing none of the five
   heuristic categories, e.g.: *"Fix a typo in the footer copyright text."*
2. **Expect**: the resulting fixture `spec.md` contains no
   `## Delivery Considerations` section and no other rollout-related
   content; the specify flow otherwise looks identical to running without
   the doctrine.
3. Run the gate script against the fixture directory. **Expect**:
   `hasFlags=false`.

## Scenario 3 — Ambiguous signal, one clarifying question (User Story 3, P2)

1. Run `/speckit.specify` with a deliberately ambiguous description, e.g.:
   *"Improve the internal reporting dashboard."*
2. **Expect**: the agent asks exactly one rollout-related clarifying
   question — count the questions asked; there must be exactly one, not
   zero, not several (SC-005).
3. Answer confirming rollout intent. **Expect**: the marker is written
   (same shape as Scenario 1).
4. Repeat with an answer denying/declining rollout intent. **Expect**: no
   marker, no other rollout-related content in the fixture `spec.md`.

## Scenario 4 — User declines a clear proposal (User Story 4, P3)

1. Run `/speckit.specify` with a description matching detection heuristics
   (reuse Scenario 1's description), but when the agent proposes the
   rollout framing, respond declining it (e.g., "no, this doesn't need a
   flag").
2. **Expect**: the resulting fixture `spec.md` contains no
   `## Delivery Considerations` section and no other rollout-related
   content.

## Cross-cutting checks

- Across all four scenarios, confirm the doctrine content itself (in
  `commands/brief-specify.md`) never mentions a specific feature-flag
  provider name (SC-004), and never includes `Delivery Strategy`
  wording, rollout task lists, or provider/MCP interaction instructions
  (FR-009) — a plain read-through of the file is sufficient for this check.
- Clean up scratch fixture directories (e.g.
  `specs/999-quickstart-fixture/`) after validation; do not leave them in
  the repository.
