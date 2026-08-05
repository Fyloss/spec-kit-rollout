# Quickstart: Rollout Section Template

**Feature**: 012-rollout-section-template | **Date**: 2026-07-08

This guide validates that `templates/rollout-section.md` (once created during
the implement phase) satisfies both this feature's own requirements and
Feature 006's pre-existing "works with or without the template" guarantee.
No code, build, or test framework is involved — every step is a direct file
read or a diff-free re-run of an existing quickstart.

## Prerequisites

- Repository checked out locally; no dependencies to install.
- `commands/brief-plan.md` (Feature 006) already implemented and unmodified.
- `specs/006-rollout-plan-doctrine/quickstart.md` available for the
  before/after re-run in Scenario 3.

## Scenario 1 — Template file exists and is complete (User Story 1, SC-001, SC-004)

1. Confirm the file exists: `templates/rollout-section.md`.
2. Read the file and check, in order, for these six labeled elements:
   `Feature flag`, `Provider`, `Rollout` (with multiple ordered `Phase N`
   stages), `Targeting`, `Telemetry gates`, `Rollback`.
3. Confirm each element has guidance text explaining its purpose, readable
   without consulting any other document.

**Expected outcome**: All six elements present, correctly ordered per
vision.md §9, each with self-contained guidance text. (SC-001, SC-004)

## Scenario 2 — Template explicitly documents its own optionality (FR-003, User Story 3)

1. Read `templates/rollout-section.md` in full.
2. Confirm it contains an explicit statement that the file is optional — a
   structural reference, not a required artifact or a validation schema.

**Expected outcome**: Optionality statement present and unambiguous. (FR-003)

## Scenario 3 — Plan phase is unaffected by the template's absence (User Story 2, SC-002, SC-003)

1. Temporarily rename `templates/rollout-section.md` (e.g., to
   `templates/rollout-section.md.bak`), or note its absence if not yet
   created.
2. Re-run Feature 006's own quickstart scenarios
   (`specs/006-rollout-plan-doctrine/quickstart.md`) — both the rollout-intent
   and no-rollout-intent cases — using `commands/brief-plan.md`'s doctrine
   exactly as before.
3. Confirm every scenario produces the same outcome as it did with the
   template present: a complete `## Delivery Strategy` section for
   rollout-intent features, no behavior change for non-rollout features, and
   zero errors/warnings/missing-file messages surfaced to the user.
4. Restore the file (rename it back / recreate it).

**Expected outcome**: Zero difference in Feature 006's quickstart results
between template-present and template-absent runs. (SC-002, SC-003, FR-004,
FR-005)

## Scenario 4 — No regression to other features' quickstarts (FR-008, SC-003)

1. With the template file absent (from Scenario 3, step 1), spot-check one
   or two other already-implemented features' quickstart docs unrelated to
   rollout content (e.g., Feature 003's gate-script quickstart) if readily
   re-runnable.
2. Confirm no pass/fail outcome changes.

**Expected outcome**: No other feature's existing quickstart or acceptance
result is affected by the template file's presence or absence. (FR-008,
SC-003)

## Cleanup

- Ensure `templates/rollout-section.md` is restored to its final, committed
  state (not left renamed/backed-up) before concluding verification.
