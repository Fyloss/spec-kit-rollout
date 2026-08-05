# Phase 0 Research: Rollout Plan Doctrine (Pre-Plan Briefing)

No `NEEDS CLARIFICATION` markers remain in spec.md (confirmed by
`checklists/requirements.md`, all items pass). This document records the
decisions made while resolving the feature's design questions against
`docs/foundation/vision.md` (§4, §5.1, §5.2, §9) and the Feature 003 gate-
script contract, plus the Feature 004/005 doctrine precedent, rather than
resolving open unknowns.

## Decision: The `/plan` arguments sniff reuses specify's rollout-signal heuristics, not a new set

**Decision**: The doctrine instructs the same minimal, cheap sniff heuristic
already used by `/speckit.specify` (vision.md §4): high-risk/irreversible
changes, major UX changes, progressive migrations, explicit cohort/
percentage language, performance/infra-sensitive changes — applied to the
current `/plan` invocation's own arguments, only in the no-marker branch.

**Rationale**: spec.md FR-002 and its Assumptions state the sniff should
reuse the same category of signals rather than defining a new heuristic set,
since both are advisory, cheap, natural-language sniffs over free-text
input. Reusing the exact category list keeps the two detection points
(specify-time, plan-time) consistent and avoids the doctrine drifting into
a second, subtly different definition of "rollout intent" that a reviewer
would have to reconcile against vision.md §4.

**Alternatives considered**: Defining a plan-specific signal list (e.g.,
narrower, focused only on percentage/phase language since that's more
common at plan time) was rejected — it would create two divergent
definitions of "rollout intent" across the specify and plan doctrines with
no clear boundary, and spec.md's Assumptions explicitly rule this out.

## Decision: Marker back-fill uses the exact Feature 004 convention, byte-for-byte

**Decision**: When the `/plan` arguments sniff finds rollout signals and no
marker exists, the doctrine instructs the agent to write a `##
Delivery Considerations` marker into `spec.md` using the exact heading and
`Candidate flag(s):` label convention established by Feature 004 — not a
new or plan-specific marker format.

**Rationale**: FR-004 requires the back-filled marker to follow "the exact
marker convention established by Feature 004... recognized by the shared
gate script." This guarantees `scripts/bash/rollout-gate.sh` /
`rollout-gate.ps1`'s `extract_flags_line` matching (heading regex `^##
Delivery Considerations`, case-insensitive substring `candidate flag(s):`,
per repo memory) succeeds on the back-filled marker exactly as it does on a
marker written at specify time, so downstream phases (clarify, analyze,
checklist, a later plan re-run) treat both origins identically. Reusing the
already-implemented convention avoids inventing new gate-script-recognizable
syntax.

**Alternatives considered**: A distinct "back-filled at plan time" variant
heading (e.g., `## Delivery Considerations (late)`) was considered for
traceability, but rejected — it would fail the gate script's exact heading
match unless the script were also changed (out of scope per spec.md
Assumptions: "MUST NOT modify... the gate scripts"), and spec.md FR-004
requires the doctrine to "proceed as if the marker had been present from
the start," implying no visible distinction from an ordinary marker.

## Decision: Delivery Strategy content lineage — spec + marker, never invented independently

**Decision**: The doctrine instructs the agent to derive every element of
the `## Delivery Strategy` section from the spec's stated requirements and
any rollout parameters already clarified in the marker (Feature 005's
phases/audience/percentages/telemetry gates/rollback conditions), and to
propose a reasonable draft value grounded in those requirements for any
element still missing — never inventing content unconnected to the spec.

**Rationale**: FR-006 and FR-007 require this explicitly, and vision.md
§5.2's "Content lineage" rule states `spec.md` is consulted by the gate only
for flag/no-flag state, but the normal SDD content chain (`plan ← spec`)
still applies to what the Delivery Strategy actually contains. This keeps
the plan-phase content traceable back to reviewable spec requirements rather
than being an ungrounded agent invention, consistent with how the rest of
`plan.md` is expected to derive from `spec.md`.

**Alternatives considered**: Treating the marker's clarified parameters as
the *sole* source (ignoring the spec's other requirements) was rejected —
FR-006 explicitly requires grounding in "the spec's stated requirements
*and* any rollout parameters already clarified," since the marker alone
(especially if sparse, e.g., only a flag name) would be an insufficient
basis for a "complete" Delivery Strategy per FR-007/SC-001.

## Decision: Provider name is explicitly permitted here, unlike Features 004-005

**Decision**: The doctrine instructs the agent to write `Provider:
LaunchDarkly` explicitly in the Delivery Strategy section, in contrast to
`brief-specify.md` and `brief-clarify.md`, which both forbid naming a
provider.

**Rationale**: spec.md FR-005 and Assumptions state this directly, and
vision.md §5.1's phase table draws the line at `before_plan`: "plan —
Introduce a `Delivery Strategy` section: flag name, provider, phased
rollout..." while `specify`/`clarify` explicitly avoid it ("Do not name a
provider at this stage"). Vision.md §1 also scopes V1 to LaunchDarkly only,
so naming it here is not premature — it is the first phase where a concrete
provider commitment is appropriate content.

**Alternatives considered**: Keeping provider-name avoidance consistent
across all doctrine files (specify/clarify/plan alike) was rejected — it
directly contradicts FR-005's literal requirement (`Provider: LaunchDarkly`)
and vision.md §9's worked example, which names the provider by that exact
field.

## Decision: No new contract artifact

**Decision**: This feature does not add a `contracts/` directory or a new
contract document. `data-model.md` documents the prompt-content entities
this feature introduces (the Delivery Strategy section and the `/plan`
arguments sniff) and links to
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the
marker's authoritative machine-readable shape.

**Rationale**: The marker's exact shape is already contracted by Feature 003
and reused (not altered) by Features 004 and 005, and now by this feature's
back-fill path. Duplicating that contract text here would create a fourth
source of truth that could drift out of sync. The `Delivery Strategy`
section itself is prose content authored per doctrine instructions, not a
machine-parsed interface with its own schema — Feature 7 (`before_tasks`)
will read it as spec-chain content, the same way any downstream SDD phase
reads `plan.md`, not via a dedicated parser this feature would need to
contract.

**Alternatives considered**: Writing a "Delivery Strategy schema" contract
(e.g., specifying exact field names/order machine-readably for Feature 7 to
parse) was considered, but rejected as premature — spec.md's Key Entities
describe the six elements in prose, matching vision.md §9's example format,
and Feature 7 is out of scope for this feature to design around. Introducing
a formal schema now risks over-constraining a feature not yet planned.

## Decision: `/plan` arguments sniff is documented as a distinct entity from the gate script check

**Decision**: data-model.md and the doctrine text treat the "`/plan`
arguments sniff" as a separate concept from the shared gate script's
`spec.md` marker check — the gate check runs first and is authoritative
when it reports a marker; the sniff is consulted only in the no-marker
branch and never overrides or duplicates an existing marker.

**Rationale**: spec.md's Key Entities section defines these as two distinct
concepts, and the Edge Cases section resolves the interaction directly:
"the existing marker takes precedence... the sniff is only consulted in the
no-marker branch." Keeping them conceptually and textually separate in the
doctrine avoids ambiguity about ordering (which check runs first, which
wins) that could otherwise cause a marker to be double-written or a
back-fill to run redundantly against an already-flagged feature.

**Alternatives considered**: Merging both checks into a single "detect
rollout intent" step (checking spec.md and `/plan` arguments together,
whichever finds a signal first) was rejected — it would blur the exit-code-2/
no-marker branching contract already established by Feature 003
(`hasFlags`/exit codes) and complicate the doctrine's branching logic for
no added benefit; spec.md's edge cases are already written assuming a
strict gate-first, sniff-second order.
