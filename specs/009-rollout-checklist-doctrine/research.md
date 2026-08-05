# Research: Rollout Checklist Doctrine (Pre-Checklist Briefing)

**Feature**: 009-rollout-checklist-doctrine
**Date**: 2026-07-08

No `[NEEDS CLARIFICATION]` markers remain in spec.md — the spec passed its
quality checklist on first draft (same pattern as Features 004-008). This
document records the design decisions carried into plan.md and the
doctrine content itself, and the alternatives considered for each.

## Decision: Phrase rollout-quality items as requirements-quality checks, not implementation-verification statements

**Rationale**: `.github/agents/speckit.checklist.agent.md` establishes
`/speckit.checklist`'s core operating principle — checklists are "unit
tests for requirements writing," and items MUST be phrased as questions
about whether requirements are complete/clear/consistent (e.g., "Is X
defined?", "Are Y requirements consistent?"), never as implementation
verification ("Verify X works", "Test that Y happens"). FR-005 requires
rollout-quality items to be "phrased as a verifiable checklist item...not
as a status report, finding, or pass/fail assertion," which is this
convention applied to rollout content specifically. Deviating from it would
make the rollout-quality category inconsistent with every other category
`/speckit.checklist` produces, undermining the "additive" goal (FR-003,
FR-009) of blending in rather than reading as a foreign block.

**Alternatives considered**:
- Phrase items as direct status assertions (e.g., "Flag naming is
  defined"). Rejected: reads as a finding/report, not a requirements-quality
  question, and would need to flip between true/false wording depending on
  actual spec/plan content — contradicting FR-007's requirement that item
  presence not depend on the target artifact already being complete.
- Phrase items as implementation-verification statements (e.g., "Verify the
  feature flag was created"). Rejected: explicitly prohibited by
  `speckit.checklist.agent.md`'s "ABSOLUTELY PROHIBITED" list and outside
  this feature's scope (provider execution is Feature 10, `before_implement`).

## Decision: One shared rollout-quality category, not one per checklist type or per flag

**Rationale**: FR-003 requires the category to be additive to "whatever
category/categories the user's checklist request already produces" (e.g., a
UX checklist, a security checklist), not a replacement or a parallel
checklist file. FR-008 requires a single shared category when the marker
names multiple candidate flags, consistent with Feature 008's precedent of
evaluating rollout content at the feature level rather than per-flag
granularity.

**Alternatives considered**:
- A dedicated `checklists/rollout.md` file created regardless of what the
  user asked for. Rejected: `/speckit.checklist`'s own file-handling model
  is user-request-driven (`checklists/[domain].md`, named by the user's
  focus); forcing a fixed extra file for every checklist invocation would
  work against that model and duplicate content across files when a user
  runs checklist multiple times.
- One rollout-quality category duplicated per named flag. Rejected:
  explicitly excluded by FR-008 and the spec's Edge Cases section, mirroring
  Feature 008's precedent (per-flag chain granularity is out of scope).

## Decision: Add the category unconditionally on marker presence, independent of Delivery Strategy completeness

**Rationale**: FR-007 and User Story 3 establish that checklist items
describe what to verify, not a current state — so the rollout-quality
category must appear whether or not `plan.md` yet has a `## Delivery
Strategy` section (e.g., checklist run before `/speckit.plan`). This mirrors
how every other checklist category is generated: `/speckit.checklist` adds
requirements-quality items for a domain regardless of whether that domain's
content is already perfect or even authored yet.

**Alternatives considered**:
- Only add the category once `plan.md` already has a Delivery Strategy
  section. Rejected: explicitly contradicted by FR-007 and User Story 3 —
  checklists are meant to be worked through before/during authoring, not
  gated on the target content already existing.
- Word items conditionally ("If the plan lacks a Delivery Strategy,
  flag..."). Rejected: this would make items read as findings/branches
  rather than the fixed, checkable-anytime question format every other
  category already uses.

## Decision: Reuse the shared gate script's default mode only (no new mode), same two-tier pattern as Features 004-005, 007-008

**Rationale**: FR-001 requires invoking the gate script (Feature 003) in
default mode against `spec.md` only, before deciding whether to add
rollout content. Unlike Features 007-008 (which additionally read
`plan.md`/`tasks.md` directly as a second stage because their content
depends on Delivery Strategy specifics), this feature's item text is fixed
regardless of Delivery Strategy completeness (see prior decision), so no
second-stage direct read of `plan.md` is required by the doctrine itself —
though the items themselves instruct checking `plan.md`'s Delivery Strategy
section when it exists (FR-006), that check happens when the checklist is
later worked through, not by the briefing doctrine at generation time.

**Alternatives considered**:
- Have the briefing itself read `plan.md` at checklist-generation time and
  vary item wording based on what it finds. Rejected: contradicts the
  "phrase items as fixed, checkable-anytime questions" decision above and
  adds complexity with no acceptance-criteria benefit.

## Decision: No `contracts/` directory for this feature

**Rationale**: Consistent with Features 004-008 — this feature authors
agent-facing prompt content, not a new machine-readable interface. It reuses
two existing shapes (the gate script's stdout contract, Feature 006's
Delivery Strategy heading convention) plus the existing
`/speckit.checklist` category/ID format, avoiding a new source of truth for
content this feature only augments.

**Alternatives considered**:
- A new `contracts/rollout-checklist-category.md` documenting the five-item
  shape. Rejected: the category reuses the exact existing `- [ ] CHKxxx
  <item text>` format with no new schema; a contract doc would duplicate
  `.github/agents/speckit.checklist.agent.md` without adding information.

## Decision: No agent-context update script invocation

**Rationale**: Consistent with Features 006-008 — this repository's
`.specify/scripts/bash/` contains only `setup-plan.sh`,
`check-prerequisites.sh`, `create-new-feature.sh`, `setup-tasks.sh`, and
`common.sh`; there is no agent-context-update script to run in Phase 1.

**Alternatives considered**: None — this is a factual repository-state
observation, not a design choice.
