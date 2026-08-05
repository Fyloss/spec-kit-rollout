# Phase 0 Research: Rollout Tasks Doctrine (Pre-Tasks Briefing)

No `NEEDS CLARIFICATION` markers remain in spec.md (confirmed by
`checklists/requirements.md`, all items pass). This document records the
decisions made while resolving the feature's design questions against
`docs/foundation/vision.md` (§4, §5.2), the Feature 003 gate-script
contract, and the Feature 004-006 doctrine precedent, rather than resolving
open unknowns.

## Decision: Gate script runs in default mode, not analyze mode

**Decision**: The doctrine instructs invoking
`scripts/bash/rollout-gate.sh` / `rollout-gate.ps1` with no mode flag
(equivalent to `--mode default`), which checks only `spec.md` for the
marker.

**Rationale**: FR-001 requires invoking the shared gate script "before
generating any rollout task content," and this feature's flag/no-flag
signal need is identical to Features 004-006's — only `spec.md`'s marker
state matters at this first gate. `analyze` mode (which additionally
searches `plan.md`/`tasks.md`) is reserved for Feature 9's `before_analyze`
briefing, which needs to detect the marker across all three artifacts to
validate chain consistency; this feature's second check (Delivery Strategy
presence) is a distinct, separate step performed directly against `plan.md`
content, not through the gate script's analyze mode.

**Alternatives considered**: Using `analyze` mode so a single gate-script
call could report on both `spec.md`'s marker and `plan.md`'s content was
rejected — the gate script's `analyze` mode contract
(`rollout-gate-cli.md`) only reports *marker heading* presence, not
specifically the `## Delivery Strategy` heading, so it cannot answer "does
plan.md have a complete Delivery Strategy section" — that requires a
distinct, feature-specific inspection this doctrine must instruct directly.

## Decision: Delivery Strategy presence is a second, explicit gate distinct from the marker check

**Decision**: The doctrine instructs a two-stage check: (1) gate script on
`spec.md` → no-op if `hasFlags=false`; (2) only if `hasFlags=true`,
separately inspect `plan.md` for a `## Delivery Strategy` heading → if
absent, emit a distinct one-line status message and add zero rollout tasks.

**Rationale**: FR-003/FR-004 and Story 3 require this explicitly — it is
the concrete mechanism for enforcing constitution Principle III (Strict
Content Lineage) at the tasks phase. Unlike Features 004-006, which each had
a single self-gate check, this feature's content source (`plan.md`'s
Delivery Strategy) is one hop further down the chain than the gate script's
`spec.md`-only check, so a second, explicit presence check is required to
avoid ever falling back to `spec.md`'s requirements text as a substitute
content source.

**Alternatives considered**: Treating `hasFlags=true` alone as sufficient
license to generate rollout tasks (assuming a Delivery Strategy section
must already exist whenever the marker is present) was rejected — spec.md's
Story 3 explicitly describes plans generated or edited without the rollout
extension installed, or with the section manually removed, as a real
scenario the doctrine must handle without fabricating content.

## Decision: No fallback to spec.md content, ever — including partial Delivery Strategy sections

**Decision**: The doctrine instructs that when the Delivery Strategy
section is absent, or present but only partially populated, the briefing
MUST NOT read `spec.md`'s requirements text as a substitute or supplemental
content source for rollout tasks under any circumstance — for missing
elements, the instruction is to omit the corresponding task, never to
invent or backfill it from the spec.

**Rationale**: FR-004, FR-006, FR-007, and FR-009 all reinforce this from
different angles (missing section, partial section, spec.md role limited to
gate state), and it is the literal text of constitution Principle III:
"Content MUST NEVER be regenerated sideways... spec content from plan" —
by extension, tasks content must never be regenerated from spec.md either,
since the one-direction chain for this phase is `tasks.md ← plan.md`
exclusively. This is the strictest content-lineage enforcement of any
`brief-*.md` doctrine so far, because Feature 006's plan-time back-fill
(writing the marker itself) was carved out as gate-state bookkeeping, not
content — this feature has no comparable carve-out to lean on, since
generating task content from spec.md would be actual content derivation.

**Alternatives considered**: Falling back to re-deriving a best-effort
rollout task set directly from `spec.md`'s requirements when `plan.md`
lacks a Delivery Strategy section (so the feature could still produce
*something* useful) was considered but rejected — this is precisely the
sideways-regeneration pattern Principle III and spec.md's Story 3 forbid;
producing plausible-but-ungrounded task content would risk contradicting
whatever the plan phase actually decided (or will decide once re-run).

## Decision: Six-task pattern repeats verbatim per named flag; no merged/deduplicated variant

**Decision**: When the Delivery Strategy section names more than one
candidate flag, the doctrine instructs repeating the full six-task pattern
once per flag, each set clearly scoped to its own flag name, rather than
producing one shared task set covering multiple flags.

**Rationale**: FR-010 and Story 1's Acceptance Scenario 3 require this
directly, to avoid an "ambiguous task set" where it's unclear which flag a
given environment/targeting/telemetry/rollback task applies to. This
mirrors the ordering principle applied to the six-task pattern itself
(FR-008) — clarity of what maps to what is the recurring design value
across this doctrine.

**Alternatives considered**: A single consolidated task set listing all
flags together per task (e.g., one "configure environments" task covering
all flags) was rejected — it collapses distinct per-flag configuration work
into one item, harder to track/complete independently, and spec.md's
Acceptance Scenario 3 explicitly calls out avoiding "a single ambiguous task
set."

## Decision: Task ordering encodes delivery sequence, not Delivery Strategy field order

**Decision**: The doctrine instructs a specific task order — create flag,
configure environments, configure targeting, integrate SDK, add telemetry
validation, define rollback conditions — justified by real delivery
dependency (flag must exist before environment/targeting configuration; SDK
integration should precede telemetry validation; rollback conditions belong
alongside or after telemetry validation), rather than simply mirroring
whatever order fields happen to appear in the Delivery Strategy section.

**Rationale**: FR-008 states the ordering requirement explicitly with this
exact dependency rationale, and vision.md §4's tasks-phase description lists
the same task categories in the same order ("create flag, configure
environments/targeting, integrate SDK, add telemetry validation, define
rollback"). Following it exactly keeps this doctrine's task list consistent
with the vision document's canonical phrasing, which downstream review
(analyze, checklist) is likely to compare against.

**Alternatives considered**: Deriving task order dynamically from whatever
order the Delivery Strategy section happens to list its elements was
rejected — the Delivery Strategy section's authoring doctrine (Feature 006)
does not itself mandate a fixed field order, so task order would become
non-deterministic and could produce a delivery-sequence-violating order
(e.g., "configure targeting" before "create flag") purely as an accident of
how a particular plan.md happened to be written.

## Decision: No new contract artifact

**Decision**: This feature does not add a `contracts/` directory or a new
contract document. `data-model.md` documents the rollout-task-set entity
this feature introduces and links to
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` (gate
script stdout shape) and `specs/006-rollout-plan-doctrine/data-model.md`
(Delivery Strategy section shape) as the two existing contracts this
doctrine consumes.

**Rationale**: Same rationale as Features 004-006 — the marker's shape is
already contracted by Feature 003 and reused unmodified since; the Delivery
Strategy section is prose content authored per Feature 006's doctrine, not
a machine-parsed interface. Introducing a new formal schema for either here
would create a fourth/fifth source of truth at risk of drifting from the
authoring doctrine that actually produces the content.

**Alternatives considered**: Writing a formal "rollout task" schema
contract (exact task title wording, field order, machine-parseable ID
scheme) was considered but rejected as premature — spec.md's Key Entities
describe the six tasks in prose matching vision.md §4's phrasing, and no
downstream feature in this repository's scope currently needs to
machine-parse `tasks.md`'s rollout tasks (Feature 10's `before_implement`
reads tasks.md as ordinary spec-chain content, the same way any SDD phase
consumes a prior phase's artifact).
