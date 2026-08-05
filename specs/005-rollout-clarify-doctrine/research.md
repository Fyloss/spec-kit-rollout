# Phase 0 Research: Rollout Clarify Doctrine (Pre-Clarify Briefing)

No `NEEDS CLARIFICATION` markers remain in spec.md (confirmed by
`checklists/requirements.md`, all items pass). This document records the
decisions made while resolving the feature's design questions against
`docs/foundation/vision.md` (§4, §5.1, §6, Decision D6) and the Feature 003
gate-script contract, rather than resolving open unknowns.

## Decision: Rollout Parameter Set is exactly five categories

**Decision**: The doctrine instructs elicitation of exactly five rollout
parameter categories when a marker is present and a parameter is not already
specified: rollout phases, target audience/segments, percentages, telemetry
gates, rollback conditions.

**Rationale**: spec.md FR-004 and the user's Input enumerate exactly these
five categories, mirroring the parameters `plan`'s `Delivery Strategy`
(Feature 6) will need per vision.md §5.1/§9. Using this fixed list keeps the
doctrine traceable to the vision document and avoids inventing additional
elicitation categories that later features don't expect.

**Alternatives considered**: A shorter list (e.g., only phases + percentage)
was rejected — it would leave audience/telemetry/rollback gaps that Feature
6 would then have to invent from nothing, defeating clarify's elicitation
purpose (spec.md "Why this priority" for Story 1). A longer, more granular
list (e.g., splitting "telemetry gates" into separate metric/threshold/
duration sub-fields) was rejected as unnecessary structure for an advisory,
prose-based elicitation flow — clarify already has its own question-asking
mechanism; this doctrine only tells it what topics to cover.

## Decision: Marker preservation is an explicit instruction, not a code guard

**Decision**: The doctrine explicitly instructs the agent that the `##
Delivery Considerations` section and its rollout requirement must never be
treated as underspecified noise to remove, shorten, or reword away — this is
stated as a standalone rule, not left implicit in the elicitation
instructions.

**Rationale**: vision.md Decision D6 specifically calls out clarify (along
with analyze and checklist) as a command whose default behavior — challenging
underspecified text — could otherwise strip or misjudge rollout content.
spec.md Story 3 and FR-003 require this guardrail to be explicit and
independent of the elicitation flow, since a sparse marker (e.g., only a
candidate flag name) is exactly the kind of content clarify would normally
flag for trimming. There is no code enforcement available here (this feature
ships no scripts), so the instruction must be unambiguous and stated first,
before the elicitation instructions, so the agent internalizes "preserve"
before "elicit."

**Alternatives considered**: Relying on the elicitation instructions alone
(i.e., assuming that telling the agent to ask about missing parameters
implies it shouldn't delete the section) was rejected — Story 3's premise is
that clarify's normal instincts would otherwise remove or reword sparse
content, so the doctrine must override that instinct explicitly rather than
assume it won't trigger.

## Decision: Exact marker convention reuse (heading + label), refine-in-place only

**Decision**: The doctrine instructs the agent to keep the existing `##
Delivery Considerations` heading and `Candidate flag(s):` label exactly as
already present (byte-for-byte per the Feature 003/004 convention), and to
add clarified rollout-parameter detail as additional prose within the same
section — never creating a new section, duplicating the marker, or moving it
elsewhere in `spec.md`.

**Rationale**: FR-006 and FR-007 require the refined marker to remain
recognizable to `scripts/bash/rollout-gate.sh` / `rollout-gate.ps1`'s
`extract_flags_line` matching (heading regex `^## Delivery Considerations`,
case-insensitive substring `candidate flag(s):`), so SC-003 (gate-script
parity before/after clarify) holds. Reusing the exact, already-implemented
convention from Feature 003/004 (rather than inventing refinement syntax)
guarantees this parity with zero changes to the gate scripts, consistent
with repo memory's documented match rules.

**Alternatives considered**: Introducing a distinct sub-heading per
parameter category (e.g., `### Telemetry Gates`) under the marker was
rejected — spec.md FR-006 requires updating "the same section," and
sub-headings risk the gate script's line-scan (which stops at the first
less-indented line after `hooks:`/heading boundaries per repo memory)
misbehaving if nested headings are introduced; keeping it as flat prose
within the one section avoids that risk entirely.

## Decision: No new contract artifact

**Decision**: This feature does not add a `contracts/` directory or a new
contract document. `data-model.md` documents the prompt-content entities this
feature introduces and links to
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the
marker's authoritative machine-readable shape.

**Rationale**: The marker's exact shape is already contracted by Feature 003
and reused (not altered) by Feature 004 and this feature. Duplicating that
contract text here would create a third source of truth that could drift out
of sync; the plan-workflow guidance says to skip contract generation when a
project has no new external interface to document. This feature adds no new
interface — it only adds instructions for refining existing marker content.

**Alternatives considered**: Writing a "clarify briefing contract"
describing `commands/brief-clarify.md`'s expected doctrine structure was
considered, but rejected for the same reason as Feature 004 — the file's
audience is the AI agent reading it directly at runtime, not a caller with a
separate machine interface; a contract doc would only restate spec.md's
functional requirements without adding verifiable value.

## Decision: Elicitation reuses clarify's existing Q&A flow; declines leave gaps, not blocks

**Decision**: The doctrine instructs the agent to ask about missing rollout
parameters through clarify's normal interactive question-and-answer flow
(no new mechanism), to skip parameters already present in the marker, and to
treat a developer's decline to answer a specific question as "leave that
parameter unspecified" rather than inventing a value or halting the rest of
clarify's flow (including its non-rollout questions).

**Rationale**: spec.md Assumptions state the elicitation questions use
clarify's existing flow explicitly. FR-005, FR-008, and FR-011 require,
respectively: no re-asking already-answered parameters, graceful handling of
declines, and no suppression of clarify's other non-rollout questions. This
keeps the rollout elicitation strictly additive — consistent with vision.md
§5.2's near-zero context-pollution guarantee for the common (non-rollout)
case, and non-disruptive to clarify's existing purpose for the rollout case.

**Alternatives considered**: A dedicated rollout-only Q&A sub-flow that runs
before or after clarify's normal questions (rather than being interleaved
via the same mechanism) was considered, but rejected as over-engineering
relative to this feature's scope (content-authoring only, per spec.md
Assumptions) — it would also risk violating FR-011 by implying rollout
questions are a separate, gated phase rather than additive to clarify's
existing purpose.
