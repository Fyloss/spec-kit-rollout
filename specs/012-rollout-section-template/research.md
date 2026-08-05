# Phase 0 Research: Rollout Section Template

**Feature**: 012-rollout-section-template | **Date**: 2026-07-08

No `NEEDS CLARIFICATION` markers remain in the Technical Context — the spec
passed its quality checklist on first draft with zero clarification markers
(consistent with Features 004-011). This document records the design
decisions made while translating the spec's requirements into a concrete
file, and the rationale for structural choices in the plan.

## Decision 1: Exact field set and order

**Decision**: The template's six required elements, in this exact order, are:
`Feature flag`, `Provider`, `Rollout:` (with ordered `Phase N:` sub-lines),
`Targeting`, `Telemetry gates`, `Rollback`.

**Rationale**: `docs/foundation/vision.md` §9 gives a verbatim worked example
of the `## Delivery Strategy` block with this exact field set and order, and
spec.md's FR-002 explicitly requires "the structure and order shown in
vision.md §9." `commands/brief-plan.md` (Feature 006, already implemented)
independently arrived at and documents the same six-element structure in its
own Step 3 doctrine (flag name, `Provider: LaunchDarkly`, phased rollout,
targeting, telemetry gates, rollback) — so this template does not invent a
new structure, it mirrors an already-doubly-confirmed one (vision.md source
+ Feature 006's independent implementation), minimizing any risk of the
template drifting from what the plan phase already produces.

**Alternatives considered**:
- Inventing a richer/different field set (e.g., adding an owner or ticket
  reference field): rejected — out of scope per FR-002's "at minimum" wording
  interpreted narrowly for V1, and spec.md User Story 3 explicitly frames
  *additive* customization as a maintainer's own later, local choice, not
  something this feature should pre-bake.

## Decision 2: No `contracts/` directory

**Decision**: This feature does not add a `contracts/` directory, matching
Features 004-010's precedent rather than Feature 011's.

**Rationale**: Feature 011 added a `contracts/` directory because its
deliverable was a genuinely new external interface (a per-client adapter
mapping with real write/fallback semantics) not documented anywhere else.
This feature's deliverable is a single passive Markdown reference file whose
entire "contract" — the six elements, in vision.md §9's order, at path
`templates/rollout-section.md`, optional — is already fully and precisely
specified by spec.md's FR-001 through FR-003 and vision.md §9's worked
example. Adding a `contracts/` doc would duplicate that content with no new
information, the same reasoning Features 004-010 used to skip a contracts
directory for reused/already-fully-specified shapes.

## Decision 3: Zero changes to `commands/brief-plan.md`

**Decision**: This feature does not modify `commands/brief-plan.md`, even
though that file references `templates/rollout-section.md`.

**Rationale**: Feature 006's implementation already contains a paragraph
(verified present at read time: "Optional template reference: If a file
named `templates/rollout-section.md` exists in this extension package, you
may consult it... do not assume this file exists and do not require its
presence...") and a matching Appendix edge-case entry ("What if
`templates/rollout-section.md` does not exist?... Your instructions do not
require it."). Both already satisfy this feature's FR-004/FR-005 from the
006 side. Spec.md's own Assumptions section states this explicitly: "this
feature only adds an optional structural reference file and does not change
Feature 006's core requirement to work without it." Editing 006's doctrine
here would violate Constitution Principle I's additive-only posture by
touching a file outside this feature's declared scope for no functional
gain.

**Alternatives considered**:
- Re-verifying/rewording Feature 006's optional-reference paragraph for
  extra safety: rejected as unnecessary — the paragraph was read in full
  during this planning phase and already matches FR-004/FR-005 verbatim in
  intent; no gap was found that would require a 006 change.

## Decision 4: Verification approach (no automated tests)

**Decision**: Verification is a manual/scripted read-through per
quickstart.md: confirm file existence, field completeness/order, explicit
optionality statement, and a before/after diff-free re-run of Feature 006's
own existing quickstart scenarios with the template file present vs. absent/
renamed.

**Rationale**: Matches the content-only verification pattern established by
Features 004-009 (no code, no CI, no unit tests — a static Markdown asset
has nothing to unit-test). SC-002/SC-003 specifically require demonstrating
*zero behavioral difference* across presence/absence, which is best shown by
literally toggling the file's presence and re-running 006's already-passing
quickstart, not by writing new automation.

**Alternatives considered**:
- Building a lint/schema check for the template's six-element shape:
  rejected — spec.md's own Assumptions section states "No automated schema
  validation of the template's shape is required in V1 (per vision.md, this
  is a reference structure, not a linted contract)."
