# Phase 0 Research: Rollout Detection Doctrine (Pre-Specify Briefing)

No `NEEDS CLARIFICATION` markers remain in spec.md (confirmed by
`checklists/requirements.md`, all items pass). This document records the
decisions made while resolving the feature's design questions against
`docs/foundation/vision.md` and the Feature 003 gate-script contract, rather
than resolving open unknowns.

## Decision: Detection heuristic categories

**Decision**: The doctrine presents exactly the five categories named in
vision.md §4's "Rollout requirement detection (heuristics)" and echoed in
spec.md FR-001: high-risk/irreversible change (payments, auth, data
migration), major UX change, progressive/staged migration, explicit
cohort/audience language (beta, internal, canary, percentage, country/
region), and performance-/infrastructure-sensitive change.

**Rationale**: vision.md is the authoritative source for the extension's
doctrine; the spec's Input already reproduces this list verbatim. Using the
same five categories (no more, no fewer) keeps this feature's content
traceable to the vision document and avoids scope creep into heuristics the
vision doc doesn't name.

**Alternatives considered**: A shorter list (e.g., only cohort language) was
rejected — it would miss the "irreversible change" and "performance-
sensitive" cases vision.md explicitly calls out, under-detecting real
rollout candidates. A longer, more granular list (e.g., splitting "cohort
language" into separate beta/canary/percentage/region sub-categories) was
rejected as unnecessary precision for advisory, judgment-based heuristics —
the doctrine instructs the agent to weigh combined signals, not pattern-match
keywords mechanically (edge cases in spec.md).

## Decision: Exact marker convention reuse

**Decision**: The doctrine instructs the agent to write the heading exactly
as `## Delivery Considerations` (no trailing text) and to include a line
whose text contains the literal substring `Candidate flag(s):` (case
preserved for readability; the gate script's match is case-insensitive per
repo memory), followed by one or more comma-separated flag names, plus a
rollout-intent statement in the same section.

**Rationale**: SC-003 requires `scripts/bash/rollout-gate.sh` /
`rollout-gate.ps1` to deterministically report `hasFlags=true` with correct
flag names for a signal-matching feature. Repo memory (verified from
`extract_flags_line` in `scripts/bash/rollout-gate.sh`) documents the exact
match rule: heading regex `^## Delivery Considerations[[:space:]]*$` and
case-insensitive substring `candidate flag(s):`. Reusing this exact,
already-implemented convention (rather than inventing new marker syntax)
guarantees gate-script parity with zero changes to Feature 003's scripts.

**Alternatives considered**: Defining a new/different marker format for this
feature was rejected outright — spec.md FR-003 explicitly requires reuse of
the existing Feature 003 contract, and inventing a second convention would
break the single-source-of-truth self-gating mechanism vision.md §5.2
depends on.

## Decision: No new contract artifact

**Decision**: This feature does not add a `contracts/` directory or a new
contract document. `data-model.md` documents the prompt-content entities this
feature introduces and links to
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the
marker's authoritative machine-readable shape.

**Rationale**: The marker's exact shape is already contracted by Feature 003
and consumed by its gate scripts. Duplicating that contract text here would
create two sources of truth that could drift out of sync; the plan-workflow
guidance itself says to skip contract generation when a project has no new
external interface to document.

**Alternatives considered**: Writing a "briefing content contract"
describing `commands/brief-specify.md`'s expected doctrine structure was
considered, but rejected — the command file's audience is the AI agent
reading it directly at runtime, not a caller with a separate machine
interface; a contract doc would only restate spec.md's functional
requirements without adding verifiable value.

## Decision: Single clarifying question mechanism

**Decision**: The doctrine instructs the agent to ask its one clarifying
question through the same interactive flow `/speckit.specify` already uses
for any other clarification — no new prompt schema, tool, or file is
introduced.

**Rationale**: Spec.md's Assumptions section states this explicitly. Adding a
structured question mechanism for a single advisory question would be
over-engineering relative to the feature's scope (content-authoring only).

**Alternatives considered**: A dedicated Q&A markdown block/template was
rejected as unnecessary machinery for one ad hoc question whose answer only
determines "write the marker or don't."

## Decision: Provider-name exclusion is enforced only by instruction

**Decision**: The doctrine tells the agent never to name a specific
feature-flag provider in `spec.md`, deferring provider naming to the plan
phase (vision.md §5.1), with no automated enforcement (e.g., no lint script
scanning for provider names).

**Rationale**: This feature's scope (per spec.md Assumptions) is limited to
authoring `commands/brief-specify.md` content; it explicitly does not modify
scripts or add tooling. FR-004/FR-009 are satisfied by clear, explicit
briefing instructions, consistent with how the rest of the doctrine
(advisory framing, single-question rule) is enforced — through agent
instruction, not code.

**Alternatives considered**: Adding a provider-name grep check to
`scripts/bash/rollout-gate.sh` was rejected as out of scope (spec.md
Assumptions explicitly excludes gate-script changes) and would duplicate
responsibility that FR-009 already assigns to the briefing content itself.
