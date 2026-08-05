# Phase 1 Data Model: Rollout Clarify Doctrine (Pre-Clarify Briefing)

This feature adds no software data structures — its only deliverable is
Markdown prompt content in `commands/brief-clarify.md`. The "entities" below
are the content-level concepts that doctrine text organizes and instructs the
agent to reason about; they are not stored, serialized, or validated by any
code this feature ships.

## Entity: Rollout Parameter Set

**Description**: The five named categories of rollout detail clarify is
responsible for eliciting when a `## Delivery Considerations` marker is
present (spec.md FR-004; Key Entities).

**Fields** (as prose categories, not data fields):

| Category | Elicited detail |
|---|---|
| Rollout phases | Staged sequence of the rollout (e.g., internal → beta → GA) |
| Target audience/segments | Who receives the change first/next (e.g., internal users, a named cohort, a region) |
| Percentages | Traffic or user percentage at each phase |
| Telemetry gates | Metrics/signals that must hold before advancing a phase |
| Rollback conditions | Conditions that trigger reverting the rollout |

**Relationships**: Feeds the refined content added to the Delivery
Considerations Marker (below). Only categories not already present in the
marker are asked about (FR-005); a declined category is left unspecified
rather than invented (FR-008).

**Validation rules**: None encoded in software — the doctrine instructs
clarify's normal interactive elicitation for whichever categories are
missing, not a fixed script of questions. All five categories present before
clarify runs means no further rollout questions are asked (spec.md edge
cases).

**State/lifecycle**: N/A — a static reference list within the briefing
content, evaluated fresh on every `/speckit.clarify` invocation against the
current state of the marker in that feature's `spec.md`.

## Entity: Delivery Considerations Marker (refined)

**Description**: The same `## Delivery Considerations` section defined by
Feature 004 and consumed by the Feature 003 gate script. This feature
instructs the agent to refine its content in place — adding clarified
Rollout Parameter Set detail — without changing its heading, label
convention, or gate-script-recognizable shape.

**Fields**:

| Field | Description | Source of truth for exact shape |
|---|---|---|
| Heading | Literal text `## Delivery Considerations`, unchanged from what Feature 004's doctrine wrote | `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` + repo memory (`extract_flags_line` heading regex) |
| Candidate flag(s) line | Unchanged from what Feature 004's doctrine wrote — same flag name(s), same `Candidate flag(s):` label | Same 003 contract; consumed by gate script's `flags=` output field |
| Rollout-intent statement | Original prose from Feature 004's doctrine, preserved verbatim or near-verbatim (spec.md SC-005) | Feature 004's doctrine output (not redefined here) |
| Clarified rollout-parameter detail | New prose this feature's doctrine adds, covering whichever Rollout Parameter Set categories the developer answered | New to this feature (spec.md FR-006) |

**Relationships**: Read by `scripts/bash/rollout-gate.sh` /
`rollout-gate.ps1` (Feature 003) both before and after this feature's
clarify pass — both reads must report `hasFlags=true` with identical
candidate flag name(s) (SC-003). Consumed downstream by the `before_plan`
feature (Feature 6, `Delivery Strategy`), out of scope here.

**Validation rules**: MUST NOT contain any feature-flag provider name
(FR-009). MUST remain a single section — refined in place, never duplicated
or relocated (FR-006). MUST retain original candidate flag name(s) and
rollout-intent statement (SC-005). MUST NOT be removed, shortened, or
reworded into a generic ambiguity note when sparse (FR-003, Story 3).

**State/lifecycle**: Written once by Feature 004's doctrine at
`/speckit.specify` time; refined (never replaced or removed) by this
feature's doctrine at `/speckit.clarify` time. Further consumption/edits at
later phases (plan, tasks, implement) belong to separate, later features
(spec.md Assumptions, Out of scope).

## Entity: Rollout Elicitation Question (interaction, not data)

**Description**: Each question the doctrine instructs the agent to ask,
through clarify's normal interactive flow, about a specific missing Rollout
Parameter Set category.

**Fields**: N/A — an ephemeral interaction, not a stored record.

**Relationships**: An answer becomes Clarified rollout-parameter detail
(above) added to the marker. A decline leaves that category unspecified in
the marker rather than blocking the rest of clarify's flow, including its
non-rollout questions (FR-008, FR-011).

**Validation rules**: Only asked for categories not already present in the
marker (FR-005). Never asked at all when no marker is present (FR-002).
Additive to, never a replacement for, clarify's other non-rollout questions
(FR-011).
