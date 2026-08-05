# Research: Rollout Analyze Doctrine (Pre-Analyze Briefing)

**Feature**: 008-rollout-analyze-doctrine
**Date**: 2026-07-08

No `[NEEDS CLARIFICATION]` markers remain in spec.md — the spec passed its
quality checklist on first draft (same pattern as Features 004-007). This
document records the design decisions carried into plan.md and the
doctrine content itself, and the alternatives considered for each.

## Decision: Reuse the shared gate script's default (spec.md-only) mode, not a new "analyze mode"

**Rationale**: The spec's own input explicitly names the shared gate
(Feature 003) as the mechanism for the initial marker check, and FR-001
requires invoking it "before evaluating rollout-chain consistency." The
gate script's contract (`specs/003-rollout-gate-mechanism/contracts/
rollout-gate-cli.md`) only reports on `spec.md`; it has no built-in notion
of `plan.md`/`tasks.md` content. Rather than extending the gate script or
its contract to also inspect those files (which would require a
cross-cutting change to `scripts/bash/rollout-gate.sh` and
`scripts/powershell/rollout-gate.ps1`, both gated by constitution
Principle III's "any change to marker/heading contract must update both
scripts" rule), this feature's doctrine performs its own direct reads of
`plan.md` and `tasks.md` as a second stage — exactly the two-stage pattern
Feature 007 already established for tasks-doctrine (gate script for
spec.md, direct read for plan.md's Delivery Strategy heading).

**Alternatives considered**:
- Extend `rollout-gate.sh`/`rollout-gate.ps1` with a new `--mode=analyze`
  flag that also checks `plan.md`/`tasks.md`. Rejected: doubles the surface
  area of the shared contract for a check needed by exactly one doctrine
  file so far, and constitution Principle III requires any such contract
  change to update both script implementations plus the contract doc in
  lockstep — disproportionate cost for a single consumer. The two-stage
  direct-read pattern already proven in Feature 007 is cheaper and equally
  correct.
- Have the analyze briefing re-implement its own from-scratch marker
  detection instead of calling the gate script at all. Rejected: FR-001
  explicitly requires invoking the gate script; duplicating marker-detection
  logic in prose would risk drifting from the single source of truth the
  gate script represents.

## Decision: Two distinct, separately-worded HIGH-severity findings for the two possible chain breaks

**Rationale**: FR-005, FR-007, and FR-009 require the marker-to-plan break
and the plan-to-tasks break to be reported as distinct findings, "wording
and location" distinguishable per SC-004/User Story 4 Acceptance Scenario
2. Reusing the existing `/speckit.analyze` findings-table format (`ID |
Category | Severity | Location(s) | Summary | Recommendation`, defined in
`.github/agents/speckit.analyze.agent.md`) keeps this feature purely
additive to the existing report shape rather than inventing a new report
section. HIGH severity is used (not CRITICAL) because the existing severity
rubric reserves CRITICAL for constitution-MUST violations or zero-coverage
requirements blocking baseline functionality, while HIGH already covers
"conflicting requirement" / lineage-adjacent concerns — a broken rollout
chain is a Principle III lineage concern per FR-009, matching HIGH's
existing definition rather than requiring a rubric change.

**Alternatives considered**:
- A single combined "rollout chain broken" finding covering either break.
  Rejected: FR-005/FR-007 explicitly require the two findings be
  distinguishable so a reader knows which link failed; a merged finding
  would force the reader to re-derive that from the Location(s) column,
  which is a worse experience for the exact ambiguity the requirements are
  written to avoid.
- CRITICAL severity for both findings. Rejected: FR-009 anchors the choice
  to the "existing heuristic for lineage and coverage breaks (HIGH)" and
  the analyze agent's rubric (`.github/agents/speckit.analyze.agent.md`)
  reserves CRITICAL for constitution-MUST violations / zero-coverage
  blocking requirements — a broken rollout chain doesn't block the
  feature's own baseline functionality (it blocks trust in rollout
  traceability), so HIGH is the correct existing bucket, not a new one.

## Decision: Presence-only matching for rollout tasks (reuse Feature 007's six categories), not per-flag or per-category completeness

**Rationale**: FR-006 explicitly requires matching "by presence rather than
exact count or full per-flag completeness," and the Edge Cases section
states a partially populated Delivery Strategy legitimately yields fewer
tasks. This keeps the analyze briefing consistent with Feature 007's own
doctrine (which allows partial task sets) rather than inventing a stricter
completeness bar that would falsely flag a legitimately partial — but still
chain-consistent — feature as broken.

**Alternatives considered**:
- Require all six task categories to be present for chain-consistency.
  Rejected: explicitly contradicted by the Edge Cases section and FR-006.
- Per-flag chain verification (each candidate flag has its own complete
  chain). Rejected: explicitly deferred as out of scope by the Edge Cases
  section and the spec's Assumptions — feature-level presence/absence is
  sufficient for the stated acceptance criteria.

## Decision: Suppression instruction is a first-class, standalone doctrine step, not folded into the chain-check step

**Rationale**: FR-003 (suppress false-positive orphan/coverage-gap/
duplication/ambiguity findings for rollout content) is logically prior to
and independent of FR-004-FR-008 (the chain-consistency check itself) — a
briefing could in principle suppress false positives without ever checking
chain consistency, or vice versa. Keeping them as two clearly separated
instructions (mirroring the two-stage structure already used in Features
006-007's doctrine files) avoids the agent conflating "don't report this as
orphaned" with "this chain link is broken," which the spec (User Story 3
Acceptance Scenario 2) explicitly calls out as a miscategorization risk to
avoid ("the gap is the missing plan content, not the spec marker").

**Alternatives considered**:
- Single unified instruction combining suppression and chain-checking.
  Rejected: risks exactly the miscategorization the spec explicitly warns
  against (treating a missing Delivery Strategy section as if the marker
  itself were orphaned).

## Decision: No `contracts/` directory for this feature

**Rationale**: Consistent with Features 004-007 — this feature authors
agent-facing prompt content, not a new machine-readable interface. It reuses
three existing shapes (the gate script's stdout contract, Feature 006's
Delivery Strategy heading convention, Feature 007's six rollout-task
categories) plus the existing analyze findings-table format, avoiding a
fourth/fifth source of truth for content this feature only validates.

**Alternatives considered**:
- A new `contracts/rollout-chain-finding.md` documenting the two finding
  shapes. Rejected: the findings reuse the exact existing `/speckit.analyze`
  table columns with no new schema; a contract doc would duplicate
  `.github/agents/speckit.analyze.agent.md` without adding information.

## Decision: No agent-context update script invocation

**Rationale**: Consistent with Features 006-007 — this repository's
`.specify/scripts/bash/` contains only `setup-plan.sh`,
`check-prerequisites.sh`, `create-new-feature.sh`, `setup-tasks.sh`, and
`common.sh`; there is no agent-context-update script to run in Phase 1.

**Alternatives considered**: None — this is a factual repository-state
observation, not a design choice.
