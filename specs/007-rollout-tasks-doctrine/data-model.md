# Phase 1 Data Model: Rollout Tasks Doctrine (Pre-Tasks Briefing)

This feature adds no software data structures — its only deliverable is
Markdown prompt content in `commands/brief-tasks.md`. The "entities" below
are the content-level concepts that doctrine text organizes and instructs
the agent to reason about; they are not stored, serialized, or validated by
any code this feature ships.

## Entity: Rollout task set

**Description**: The six ordered tasks this feature's doctrine instructs
the agent to append to `tasks.md`, once per candidate flag, when `plan.md`
contains a complete or partial `## Delivery Strategy` section (Feature
006). This is the concrete, actionable deliverable the rollout chain
(vision.md §4) exists to produce at the tasks phase.

**Fields** (as prose task elements, not data fields):

| Order | Task | Derived from Delivery Strategy element |
|---|---|---|
| 1 | Create the feature flag | Feature flag name |
| 2 | Configure environments | Phased rollout sequence (environment scope per phase) |
| 3 | Configure targeting rules | Targeting rules |
| 4 | Integrate the application SDK | (implied by flag + provider; no dedicated Delivery Strategy field, but required to consume the flag) |
| 5 | Add telemetry validation | Telemetry gates |
| 6 | Define rollback conditions | Rollback conditions |

**Relationships**: Derived exclusively from `plan.md`'s Delivery Strategy
section (Feature 006) — never from `spec.md`'s requirements text directly
(FR-006, FR-007). One full task set is produced per named flag when the
Delivery Strategy section names more than one candidate flag (FR-010,
Acceptance Scenario 3). Consumed downstream by Feature 10's
`before_implement` briefing (out of scope here), which acts on `tasks.md` +
`plan.md` together per vision.md §4.

**Validation rules**: MUST NOT appear at all when the gate script reports
`hasFlags=false` (including the diagnostic exit code) (FR-002, Story 2).
MUST NOT appear when `hasFlags=true` but `plan.md` has no `## Delivery
Strategy` section (FR-004, Story 3) — the briefing reports the gap instead.
When the Delivery Strategy section is only partially populated, MUST emit
tasks only for the elements actually present, never fabricating a value for
a missing element (FR-009, Edge Cases). MUST be ordered per the fixed
sequence above regardless of the order fields appear in the Delivery
Strategy section (FR-008). MUST NOT include any provider MCP tool-invocation
or live provider-execution instruction (FR-011).

**State/lifecycle**: Authored fresh on each `/speckit.tasks` invocation for
a feature whose gate check passes and whose plan has a Delivery Strategy
section; appended to that feature's `tasks.md` alongside the normal
(non-rollout) task breakdown Spec Kit's core `tasks-template.md` already
produces. Not refined in place across multiple `/speckit.tasks` re-runs the
way the marker is refined across clarify passes (Feature 005) — a later
re-run would regenerate the rollout task set from the (possibly further
revised) Delivery Strategy section.

## Entity: Delivery Strategy presence check

**Description**: The second, feature-specific gate this doctrine performs —
distinct from the shared gate script's `spec.md` marker check (Feature
003) — that inspects `plan.md` directly for a `## Delivery Strategy`
heading before any rollout task content is generated (spec.md Key
Entities, FR-003).

**Fields**: N/A — an ephemeral, prose-level check, not a stored record.
Evaluated by scanning `plan.md` for the literal `## Delivery Strategy`
heading Feature 006's doctrine writes.

**Relationships**: Runs only after the shared gate script (Feature 003)
reports `hasFlags=true` on `spec.md` — never runs, and never substitutes for,
the first gate. When it finds no heading, its outcome (a one-line status
message, zero rollout tasks) is functionally similar to the first gate's
no-op outcome, but the message text is distinct so a reader can tell "no
rollout intent at all" (Story 2) apart from "rollout intent present but the
plan hasn't caught up yet" (Story 3).

**Validation rules**: MUST only run when `hasFlags=true` (FR-003). MUST NOT
trigger any fallback to `spec.md` content when it fails to find the heading
(FR-004) — the only permitted outcome is the one-line status message plus
zero rollout tasks. MUST NOT be skipped or bypassed even when the gate
script's `flags=` output already names a candidate flag — a named candidate
flag in `spec.md` is not itself sufficient evidence that `plan.md` has a
Delivery Strategy section.

**State/lifecycle**: Performed fresh on every `/speckit.tasks` invocation
where the shared gate script reports a marker present; not persisted or
cached between runs.

## Entity: Delivery Strategy section (read-only reference)

**Description**: The `## Delivery Strategy` block in `plan.md`, authored by
Feature 006's doctrine — this feature's sole content source, consumed
read-only. Full field definitions live in
`specs/006-rollout-plan-doctrine/data-model.md`; not duplicated here to
avoid a second source of truth.

**Relationships**: Upstream input to this feature's Rollout task set entity
(above). This feature never writes to or modifies the Delivery Strategy
section — it only reads it.

**Validation rules**: N/A from this feature's perspective (validation of the
section's own completeness is Feature 006's concern); this feature only
checks for the section's *presence* (via the Delivery Strategy presence
check, above) and, when present, reads whichever of its six elements are
actually populated.
