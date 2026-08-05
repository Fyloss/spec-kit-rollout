# Data Model: Rollout Checklist Doctrine (Pre-Checklist Briefing)

**Feature**: 009-rollout-checklist-doctrine
**Date**: 2026-07-08

This feature authors agent-facing prompt content, not executable code, so
there are no database tables, classes, or persisted records. The "entities"
below are the conceptual objects the doctrine in `commands/brief-checklist.md`
instructs the `/speckit.checklist` agent to recognize and reason about while
producing its standard checklist output.

## Entity: Rollout-Quality Category

The dedicated checklist category this briefing adds to whatever checklist
`/speckit.checklist` is already generating, when the shared gate script
reports `hasFlags=true`.

| Field | Value |
|---|---|
| Category heading | A distinct `##` category heading (e.g., `## Rollout Quality`), additive to whatever other categories the user's checklist request produces |
| Item count | Five baseline items (FR-004); the agent MAY add closely related items (e.g., a per-flag item) without dropping the baseline five |
| Item format | `- [ ] CHKxxx <item text>`, continuing the checklist's existing incrementing CHK ID sequence per `.github/agents/speckit.checklist.agent.md` |
| Item phrasing | Requirements-quality questions ("Is X defined?", "Are Y requirements consistent?"), never implementation-verification statements (FR-005) |
| Trigger | Shared gate script (Feature 003) reports `hasFlags=true` against `spec.md` |
| Suppression | Shared gate script reports `hasFlags=false` (including diagnostic exit code 2) → category is not added (FR-002) |

**The five baseline items** (FR-004), each checked against the artifact
named:

1. **Flag naming defined** — checks the `Candidate flag(s):` line in the
   spec's `## Delivery Considerations` marker (Feature 004) and/or the flag
   name(s) in the plan's `## Delivery Strategy` section (Feature 006) for a
   clear, specific name.
2. **Environments/targeting specified** — checks the Delivery Strategy's
   targeting rules and environment list for completeness and clarity.
3. **Telemetry gates defined** — checks the Delivery Strategy's telemetry
   gate thresholds for presence and measurability.
4. **Rollback conditions present** — checks the Delivery Strategy's
   rollback trigger for presence and clarity.
5. **Rollout phases ordered and complete** — checks the Delivery Strategy's
   phased rollout sequence for completeness and logical ordering.

**States** (mutually exclusive, evaluated per `/speckit.checklist` run):

1. **No marker** (`hasFlags=false`, including gate script diagnostic exit
   code 2) → briefing emits one-line no-op; no Rollout-Quality Category is
   added to the generated checklist.
2. **Marker present** → the Rollout-Quality Category with all five items is
   added, regardless of whether `plan.md` yet contains a `## Delivery
   Strategy` section (FR-007) and regardless of how many candidate flags
   are named (one shared category, FR-008).

**Validation rules** (from spec.md Functional Requirements):
- Item presence is feature-level, not per-flag (FR-008) — a multi-flag
  marker still yields one shared category.
- Category presence MUST NOT depend on `plan.md`'s Delivery Strategy section
  already existing or being complete (FR-007).
- The category is strictly additive — it MUST NOT remove, replace, or
  reorder any other checklist category (FR-009).
- This entity carries no checked/unchecked state of its own beyond the
  standard `- [ ]` / `- [x]` checklist mechanics — this feature only
  ensures the right items exist, never their checked state (Edge Cases).

## Entity: Delivery Strategy Reference

The `## Delivery Strategy` section inside `plan.md` (Feature 006) that the
Rollout-Quality Category's items are ultimately meant to be checked
against, once it exists.

| Field | Source | Shape | Reference |
|---|---|---|---|
| Flag name(s) | `plan.md` | Named in Delivery Strategy | Feature 006 (`specs/006-rollout-plan-doctrine/data-model.md`) |
| Environments/targeting | `plan.md` | Delivery Strategy targeting rules | Same |
| Telemetry gates | `plan.md` | Delivery Strategy telemetry thresholds | Same |
| Rollback conditions | `plan.md` | Delivery Strategy rollback trigger | Same |
| Rollout phases | `plan.md` | Delivery Strategy phased rollout sequence | Same |

**Relationships**:
- A Rollout-Quality Category always references the Delivery Strategy
  Reference conceptually (its five items check that section's eventual
  completeness), even when the Delivery Strategy section does not yet
  exist at checklist-generation time (state 2 above holds regardless).
- The Rollout-Quality Category is additive to, never a replacement for, any
  of `/speckit.checklist`'s other existing categories.

## No new persisted state

Neither entity is written to disk by this feature beyond the checklist
items themselves, which are written into whatever `checklists/[domain].md`
file `/speckit.checklist` is already producing, following that command's
existing append-only file-handling rules. This feature does not introduce a
new checklist file, command, or invocation path.
