# Data Model: Rollout Analyze Doctrine (Pre-Analyze Briefing)

**Feature**: 008-rollout-analyze-doctrine
**Date**: 2026-07-08

This feature authors agent-facing prompt content, not executable code, so
there are no database tables, classes, or persisted records. The "entities"
below are the conceptual objects the doctrine in `commands/brief-analyze.md`
instructs the `/speckit.analyze` agent to recognize and reason about while
producing its standard report.

## Entity: Rollout Chain

The three-link sequence whose end-to-end consistency this briefing
validates during `/speckit.analyze`.

| Field | Source | Shape | Reference |
|---|---|---|---|
| Marker presence | `spec.md` | `## Delivery Considerations` heading + `Candidate flag(s):` line | [rollout-gate-cli.md](../003-rollout-gate-mechanism/contracts/rollout-gate-cli.md) |
| Candidate flag name(s) | `spec.md` | Comma-separated names on the `Candidate flag(s):` line | Same contract |
| Delivery Strategy presence | `plan.md` | `## Delivery Strategy` heading | Feature 006 (`specs/006-rollout-plan-doctrine/data-model.md`) |
| Rollout task presence | `tasks.md` | At least one of six task categories: create flag, configure environments, configure targeting, integrate SDK, add telemetry validation, define rollback conditions | Feature 007 (`specs/007-rollout-tasks-doctrine/data-model.md`) |

**States** (mutually exclusive, evaluated top-to-bottom):

1. **No marker** (`hasFlags=false`, including gate script diagnostic exit
   code 2) → briefing emits one-line no-op; chain is not evaluated further.
2. **Marker present, no Delivery Strategy** → chain is broken at link 1;
   emit the FR-005 finding.
3. **Delivery Strategy present, no rollout tasks** → chain is broken at
   link 2; emit the FR-007 finding.
4. **Marker present, Delivery Strategy present, ≥1 rollout task present** →
   chain is consistent; emit zero gap/orphan findings for rollout content
   (FR-008), and actively suppress false-positive orphan/coverage-gap/
   duplication/ambiguity findings for the marker, the Delivery Strategy
   section, and the rollout tasks (FR-003).

**Validation rules** (from spec.md Functional Requirements):
- Presence is feature-level, not per-flag (FR-006, Edge Cases) — a
  multi-flag marker with only some flags fully chained still counts as
  chain-consistent overall.
- Task-category presence, not exact count or full per-flag completeness,
  satisfies link 2 (FR-006).
- This entity is read-only for this feature — no chain-repair or
  regeneration is ever instructed (FR-010).

## Entity: Rollout-Chain Finding

A distinct entry in analyze's standard findings table (`ID | Category |
Severity | Location(s) | Summary | Recommendation`, per
`.github/agents/speckit.analyze.agent.md`) reporting a specific, named
break in the rollout chain. Emitted only when that break actually exists
(state 2 or state 3 above) — never in state 1 or state 4.

| Field | Value for the marker-to-plan break (FR-005) | Value for the plan-to-tasks break (FR-007) |
|---|---|---|
| Category | Coverage Gap (fixed label — MUST NOT vary between runs or be substituted with an equivalent term, to preserve SC-005 determinism) | Same |
| Severity | HIGH | HIGH |
| Location(s) | `spec.md` (marker) / `plan.md` (missing section) | `plan.md` (Delivery Strategy) / `tasks.md` (missing tasks) |
| Summary wording | States the marker is present but Delivery Strategy is missing from `plan.md` — MUST NOT be worded as if the marker itself were orphaned (Story 3 Acceptance Scenario 2) | States Delivery Strategy is present but no rollout tasks exist in `tasks.md` — MUST be distinguishable in wording/location from the marker-to-plan finding (Story 4 Acceptance Scenario 2) |
| Recommendation | Report-only — MUST NOT instruct editing any artifact (FR-010) | Same |

**Relationships**:
- A Rollout-Chain Finding always references exactly one Rollout Chain break
  state (never both simultaneously — states 2 and 3 are mutually
  exclusive per the state list above, since state 3 requires the Delivery
  Strategy section to already be present).
- Rollout-Chain Findings are additive to, never a replacement for, any of
  analyze's other existing finding categories — they are simply excluded
  from being mistakenly generated as orphan/duplication/ambiguity findings
  for the same underlying content (FR-003 is a suppression rule about
  *other* categories, not about this entity).

## No new persisted state

Neither entity is written to disk by this feature. Both are conceptual
framings the doctrine text in `commands/brief-analyze.md` gives to the
`/speckit.analyze` agent so it reasons correctly about content that already
exists in `spec.md`, `plan.md`, and `tasks.md` (written by Features
004-007), and reports (never edits) any inconsistency it finds via the
existing findings-table mechanism.
