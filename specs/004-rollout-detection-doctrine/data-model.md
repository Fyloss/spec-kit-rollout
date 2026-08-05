# Phase 1 Data Model: Rollout Detection Doctrine (Pre-Specify Briefing)

This feature adds no software data structures — its only deliverable is
Markdown prompt content in `commands/brief-specify.md`. The "entities" below
are the content-level concepts that doctrine text organizes and instructs the
agent to reason about; they are not stored, serialized, or validated by any
code this feature ships.

## Entity: Detection Heuristic Set

**Description**: The five named categories of signal the agent weighs when
judging whether a feature description is a progressive-delivery ("rollout")
candidate (spec.md FR-001; vision.md §4).

**Fields** (as prose categories, not data fields):

| Category | Example signals |
|---|---|
| High-risk / irreversible change | Payments, authentication, data migrations |
| Major UX change | Significant redesign of a user-facing flow |
| Progressive / staged migration | Multi-step rollout of a replacement system |
| Explicit cohort / audience language | beta, internal, canary, a percentage, a country/region |
| Performance- / infrastructure-sensitive change | Changes with meaningful perf or infra blast radius |

**Relationships**: Feeds the agent's decision to propose (or not propose) a
Delivery Considerations Marker (below). Ambiguous or partial matches feed the
Single Clarifying Question flow instead of an immediate proposal.

**Validation rules**: None encoded in software — the doctrine instructs
judgment-based weighing of combined signals (spec.md edge cases), not
mechanical keyword matching. A single ambiguous keyword (e.g., "internal"
used in an unrelated sense) alone must not trigger the marker.

**State/lifecycle**: N/A — this is a static reference list within the
briefing content, evaluated fresh on every `/speckit.specify` invocation.

## Entity: Delivery Considerations Marker

**Description**: The `## Delivery Considerations` section the agent writes
into a feature's `spec.md` when the Detection Heuristic Set matches (or an
ambiguous case resolves to "yes"). Contains one or more candidate flag names
and a rollout-intent statement.

**Fields**:

| Field | Description | Source of truth for exact shape |
|---|---|---|
| Heading | Literal text `## Delivery Considerations`, no trailing characters on the line | `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` + repo memory (`extract_flags_line` heading regex) |
| Candidate flag(s) line | A line containing the literal substring `Candidate flag(s):` followed by one or more comma-separated flag names | Same 003 contract; consumed by gate script's `flags=` output field |
| Rollout-intent statement | Free-text prose explaining why the feature is a rollout candidate and the intended rollout approach | spec.md FR-003 (new to this feature; not previously specified by 003, which only cares about the flag(s) line for gating) |

**Relationships**: Read by `scripts/bash/rollout-gate.sh` /
`rollout-gate.ps1` (Feature 003) to produce `hasFlags`/`flags`/`source`.
Consumed downstream by the `before_clarify`, `before_plan`, `before_tasks`,
`before_analyze`, `before_checklist`, and `before_implement` hooks/features
named in vision.md §5.1 (all out of scope for this feature).

**Validation rules**: MUST NOT contain any feature-flag provider name
(FR-004). MUST be the only rollout-related content added when heuristics
match — exactly one section, even when multiple heuristic categories match
at once (spec.md edge cases). MUST be entirely absent when no heuristic
matches (FR-005) or when the user declines a proposal (FR-008).

**State/lifecycle**: Written once, at `/speckit.specify` time, by the acting
agent following this feature's doctrine. Not modified by this feature after
that point — preservation and elaboration at later phases belongs to
separate, later features (spec.md Assumptions).

## Entity: Single Clarifying Question (interaction, not data)

**Description**: The exactly-one question the doctrine instructs the agent
to ask when heuristic signals are ambiguous, using the normal interactive
`/speckit.specify` flow (no new mechanism).

**Fields**: N/A — an ephemeral interaction, not a stored record.

**Relationships**: Gates whether the Delivery Considerations Marker is
written (marker written only if the answer confirms rollout intent; no
answer or a decline means no marker — FR-007, FR-008, edge cases).

**Validation rules**: Exactly one question per ambiguous case — never zero,
never more than one (FR-007, SC-005).
