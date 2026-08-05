# Phase 1 Data Model: Rollout Plan Doctrine (Pre-Plan Briefing)

This feature adds no software data structures — its only deliverable is
Markdown prompt content in `commands/brief-plan.md`. The "entities" below
are the content-level concepts that doctrine text organizes and instructs
the agent to reason about; they are not stored, serialized, or validated by
any code this feature ships.

## Entity: Delivery Strategy section

**Description**: A `## Delivery Strategy` block this feature's doctrine
instructs the agent to add to `plan.md` when a `## Delivery Considerations`
marker is present (pre-existing or just back-filled) — the plan-phase
counterpart to the spec-phase marker (spec.md Key Entities).

**Fields** (as prose elements, not data fields):

| Element | Content |
|---|---|
| Feature flag name | The candidate flag name, reused from the marker's `Candidate flag(s):` value |
| Provider | Literal `Provider: LaunchDarkly` (vision.md §1 V1 scope) |
| Phased rollout sequence | Staged rollout steps (e.g., internal → 5% → 25% → 100%), per vision.md §9's example |
| Targeting rules | Audience/segment targeting detail, grounded in clarified marker parameters (Feature 005) or the spec's requirements |
| Telemetry gates | Metrics/signals that must hold before advancing a phase |
| Rollback conditions | Conditions that trigger reverting the rollout |

**Relationships**: Derived from the spec's stated requirements and the
Delivery Considerations Marker's clarified rollout parameters (below) —
never invented independently of the spec (FR-006). Consumed downstream by
Feature 7's `before_tasks` briefing (out of scope here) to emit ordered
rollout tasks, per vision.md §4.

**Validation rules**: MUST contain all six elements (flag name, provider,
phased rollout, targeting, telemetry gates, rollback) even when some marker
parameters are still missing — draft values are proposed for missing
elements rather than omitting them (FR-007, SC-001). MUST NOT appear at all
when no marker is present and the `/plan` arguments sniff finds no rollout
signals (FR-003, SC-002). MUST NOT include task-breakdown content or
provider/MCP interaction instructions (FR-009).

**State/lifecycle**: Authored fresh on each `/speckit.plan` invocation for a
flagged feature; not refined in place across multiple plan runs the way the
marker is refined across clarify passes — a later `/speckit.plan` re-run
would regenerate it from the (possibly further-clarified) marker and spec.

## Entity: `/plan` arguments sniff

**Description**: A lightweight, no-marker-branch check of the current
`/plan` invocation's own arguments for rollout signals, used only to decide
whether to back-fill a `## Delivery Considerations` marker into `spec.md`
before producing the Delivery Strategy section (spec.md Key Entities).

**Fields**: N/A — an ephemeral, prose-level check, not a stored record.
Evaluated against the same signal categories as the specify-time detection
doctrine (vision.md §4): high-risk/irreversible changes, major UX changes,
progressive migrations, cohort/percentage language, performance/infra-
sensitive changes.

**Relationships**: Distinct from the shared gate script's `spec.md` marker
check (Feature 003) — the gate check runs first and is authoritative when it
reports a marker present; this sniff is consulted only in the gate's
no-marker branch (spec.md Edge Cases) and never overrides or duplicates an
existing marker. When it finds signals, it triggers a back-fill of the
Delivery Considerations Marker (below), then the Delivery Strategy section
is produced as if the marker had existed from the start (FR-004).

**Validation rules**: Only performed when the gate reports no marker
(`hasFlags=false` or exit code 2 per the Feature 003 contract) (FR-002).
When it finds no signals either, the briefing emits a one-line no-op and
adds no rollout content (FR-003). Never runs, and never overrides, when the
gate already reports a marker present.

## Entity: Delivery Considerations Marker (back-filled)

**Description**: The same `## Delivery Considerations` section defined by
Feature 004, refined by Feature 005's clarify doctrine, and — new in this
feature — potentially back-filled directly by the plan-phase doctrine when
rollout intent is introduced late (Story 3, FR-004).

**Fields**:

| Field | Description | Source of truth for exact shape |
|---|---|---|
| Heading | Literal text `## Delivery Considerations`, identical to what Feature 004's doctrine writes | `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` + repo memory (`extract_flags_line` heading regex) |
| Candidate flag(s) line | Same `Candidate flag(s):` label and convention as Feature 004; when back-filled, a flag name derived from the `/plan` arguments' rollout language | Same 003 contract; consumed by gate script's `flags=` output field |
| Rollout-intent statement | When back-filled, brief prose capturing the rollout signal found in the `/plan` arguments (mirrors Feature 004's original statement) | New instance of Feature 004's convention, authored by this feature's doctrine only in the back-fill path |

**Relationships**: Read by `scripts/bash/rollout-gate.sh` /
`rollout-gate.ps1` (Feature 003) on any subsequent phase run, including a
later `/speckit.plan` re-run, exactly as it would read a marker written at
specify time. Feeds the Delivery Strategy section (above) once present.

**Validation rules**: MUST use the exact heading and label convention
established by Feature 004 so the gate script recognizes it identically
(SC-003 verification pattern, reused from Feature 005). MUST NOT be written
when the `/plan` arguments sniff finds no signals and no marker already
exists (FR-003). MUST NOT be duplicated or overwritten when a marker already
exists — the sniff/back-fill path only applies in the no-marker branch
(spec.md Edge Cases).

**State/lifecycle**: Written once by Feature 004's doctrine at
`/speckit.specify` time, OR back-filled once by this feature's doctrine at
`/speckit.plan` time when specify-time detection missed it. Refined by
Feature 005's doctrine at `/speckit.clarify` time (if that phase runs after
the marker exists). Read (not further modified) by this feature's doctrine
when producing the Delivery Strategy section. Further consumption at later
phases (tasks, analyze, checklist, implement) belongs to separate, later
features (spec.md Out of scope).
