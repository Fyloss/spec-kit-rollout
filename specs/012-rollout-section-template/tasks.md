---
description: "Task list for rollout-section-template feature"
---

# Tasks: Rollout Section Template

**Input**: Design documents from `/specs/012-rollout-section-template/`

**Feature**: Create `templates/rollout-section.md` — an optional structural Markdown reference for the `## Delivery Strategy` block, enabling consistent documentation of feature flag, provider, phased rollout, targeting, telemetry gates, and rollback conditions.

**Organization**: Tasks are grouped by user story to enable independent verification and delivery of each requirement.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the templates directory structure

- [X] T001 Create `templates/` directory at repository root if it does not exist

---

## Phase 2: User Story 1 - Consistent Delivery Strategy structure when template is present (Priority: P1) 🎯 MVP

**Goal**: Provide a reusable, well-documented template file that defines the exact field order and structure for Delivery Strategy sections (feature flag, provider, phased rollout, targeting, telemetry gates, rollback).

**Independent Test**: Confirm `templates/rollout-section.md` exists with all six required elements (flag, provider, rollout phases, targeting, telemetry gates, rollback) clearly labeled, in the exact order specified in vision.md §9, with guidance text explaining how to fill each element.

### Implementation for User Story 1

- [X] T002 [P] [US1] Create `templates/rollout-section.md` with optionality statement at the top explaining it is an optional structural reference, not a required validation schema
- [X] T003 [P] [US1] Add labeled sections for all six required elements in vision.md §9 order: Feature flag, Provider, Rollout (with Phase N sub-lines), Targeting, Telemetry gates, Rollback in `templates/rollout-section.md`
- [X] T004 [P] [US1] Add guidance text for each element in `templates/rollout-section.md` explaining how to fill it in, using worked example values consistent with vision.md §9 (e.g., `Provider: LaunchDarkly`)
- [X] T005 [US1] Verify all six elements appear in correct order in `templates/rollout-section.md` and are unambiguously labeled

**Checkpoint**: User Story 1 complete — template file created with all required structure and guidance text.

---

## Phase 3: User Story 2 - Plan phase is unaffected when template is absent (Priority: P1)

**Goal**: Verify that `commands/brief-plan.md` (Feature 006) contains independent doctrine and does not require `templates/rollout-section.md` to exist, ensuring the template is truly optional.

**Independent Test**: Confirm that removing or renaming `templates/rollout-section.md` produces zero change in plan phase behavior — the Delivery Strategy section is still complete, no errors occur, and Feature 006's quickstart scenarios pass both with and without the template present.

### Implementation for User Story 2

- [X] T006 [US2] Read `commands/brief-plan.md` (Feature 006) and confirm it contains a documented "Optional template reference" paragraph explaining it may consult `templates/rollout-section.md` but does not require its presence
- [X] T007 [US2] Confirm `commands/brief-plan.md` contains an Appendix edge-case answer explaining the behavior when `templates/rollout-section.md` does not exist
- [X] T008 [US2] Document in task notes that Feature 006's doctrine is self-contained and satisfies FR-004/FR-005 (template is optional, plan phase works without it)
- [X] T009 [US2] Verify no changes to `commands/brief-plan.md` are needed — Constitution Principle I (additive-only) is preserved

**Checkpoint**: User Story 2 complete — verified Feature 006 is independent and does not require the template.

---

## Phase 4: User Story 3 - Maintainer reviews and customizes template structure (Priority: P2)

**Goal**: Ensure the template is easily understood and customizable by maintainers unfamiliar with the extension, and clearly supports additive (local) modifications without breaking the core six-element structure.

**Independent Test**: A reader unfamiliar with the extension can identify all six required elements directly from `templates/rollout-section.md` and understand how to fill them in without consulting any other document.

### Implementation for User Story 3

- [X] T010 [P] [US3] Confirm `templates/rollout-section.md` clearly labels each of the six elements and explains its purpose in plain language
- [X] T011 [P] [US3] Add a "Customization" note to `templates/rollout-section.md` explaining that org-specific fields may be added below the six required elements without breaking structural consistency
- [X] T012 [US3] Verify the template contains no executable logic, gate-script dependencies, tokens, or credentials (per FR-007 and Constitution Principle V)
- [X] T013 [US3] Verify `templates/rollout-section.md` does not reference or imply that a standalone `rollout.md` artifact is required or expected (per FR-006 — Delivery Strategy content lives inside `plan.md` only)

**Checkpoint**: User Story 3 complete — template is maintainer-friendly and customizable.

---

## Phase 5: Polish & Verification (Cross-Cutting Concerns)

**Purpose**: Final validation of all requirements and acceptance criteria

- [X] T014 Verify `templates/rollout-section.md` file exists at repository root and contains exactly the content produced in Phase 2
- [X] T015 Verify `extension.yml` at repository root has zero changes (no new/modified `commands` or `hooks` entries) as a result of this feature, per FR-007
- [X] T016 [P] Confirm SC-001: When template is present, 100% of Delivery Strategy sections contain all six elements in the template's field order
- [X] T017 [P] Confirm SC-002: When template is absent, the plan phase completes with zero errors across all rollout and non-rollout scenarios
- [X] T018 [P] Confirm SC-003: Removing the template changes zero prior features' quickstart or acceptance results (verified by re-running Feature 006's checks with template absent)
- [X] T019 [P] Confirm SC-004: A reader unfamiliar with the extension can identify all six elements and understand how to fill them in from the template alone
- [X] T020 Verify `commands/brief-plan.md` (Feature 006) contains no references to or dependencies on this feature beyond the optional-reference pattern already implemented in Feature 006
- [X] T021 Document completion in task notes; feature is ready for integration

**Checkpoint**: All tasks complete. Feature 012 is ready for delivery. The optional template file has been created, validated as structurally correct, verified as non-blocking to Feature 006, and confirmed as maintainer-friendly.

---

## Implementation Strategy

**MVP Scope** (immediately valuable):
- Phase 1-2: Create `templates/rollout-section.md` with all six required elements and clear guidance text.
- Phase 3: Verify Feature 006 is independent (no changes needed).

**Subsequent Phases**:
- Phase 4: Add customization guidance (supports long-term maintainability).
- Phase 5: Final cross-feature verification (validates all success criteria).

**Key Notes**:
- No code to write — this is a static Markdown asset.
- No changes to existing files — additive only (Constitution Principle I).
- No automated tests needed — manual verification per research.md Decision 4.
- Verification strategy: Confirm file existence, structure, optionality statement, and re-run Feature 006's existing quickstart scenarios with template present vs. absent.
