---
description: "Task list for Rollout Tasks Doctrine (Pre-Tasks Briefing)"
---

# Tasks: Rollout Tasks Doctrine (Pre-Tasks Briefing)

**Input**: Design documents from `/specs/007-rollout-tasks-doctrine/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent authoring, validation, and integration of each doctrine phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (independent doctrine sections, distinct validation scenarios)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the foundation for doctrine authoring

- [X] T001 Review vision.md §4 and §5.2 for rollout intent and content-lineage principles
- [X] T002 Review Feature 003 (rollout-gate-cli.md) and Feature 006 (Delivery Strategy section contract)
- [X] T003 Verify `scripts/bash/rollout-gate.sh` and `scripts/powershell/rollout-gate.ps1` are available and functional
- [X] T004 Confirm `commands/brief-specify.md`, `brief-clarify.md`, and `brief-plan.md` already inject their doctrine via `before_*` hooks in `extension.yml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Author the shared doctrine framework

**⚠️ CRITICAL**: The entire doctrine must be grounded in these foundational elements before any scenario-specific logic is added

- [X] T005 Author the `before_tasks` hook doctrine header and gate-invocation section in `commands/brief-tasks.md` (invoke shared gate script in default mode, capture `hasFlags` state)
- [X] T006 Author the flag-present check: if `hasFlags=true`, instruct scanning `plan.md` for `## Delivery Strategy` section heading
- [X] T007 Author the two-stage gate logic: (1) spec.md gate via gate script; (2) plan.md presence gate (only if hasFlags=true)

**Checkpoint**: Doctrine framework is in place; all three scenarios can now be implemented independently

---

## Phase 3: User Story 1 - Emit ordered rollout tasks from an existing Delivery Strategy (Priority: P1) 🎯

**Goal**: Author doctrine that generates six ordered, concrete rollout tasks from the plan's Delivery Strategy section

**Independent Test**: Validate Scenario 1 (Section Scenario 1 in quickstart.md): Run `/speckit.tasks` against a feature with a complete Delivery Strategy, confirm all six tasks appear in `tasks.md` with values traced to Delivery Strategy, not spec.md

### Implementation for User Story 1

- [X] T008 [P] [US1] Author the doctrine section for extracting the flag name from `## Delivery Strategy` section and creating the "Create the feature flag" task in `commands/brief-tasks.md`
- [X] T009 [P] [US1] Author the doctrine section for extracting phased rollout sequence and creating the "Configure environments" task in `commands/brief-tasks.md`
- [X] T010 [P] [US1] Author the doctrine section for extracting targeting rules and creating the "Configure targeting rules" task in `commands/brief-tasks.md`
- [X] T011 [P] [US1] Author the doctrine section for extracting (or inferring) SDK integration requirement and creating the "Integrate the application SDK" task in `commands/brief-tasks.md`
- [X] T012 [P] [US1] Author the doctrine section for extracting telemetry gates and creating the "Add telemetry validation" task in `commands/brief-tasks.md`
- [X] T013 [P] [US1] Author the doctrine section for extracting rollback conditions and creating the "Define rollback conditions" task in `commands/brief-tasks.md`
- [X] T014 [US1] Ensure all six tasks follow the fixed task order (flag → environments → targeting → SDK → telemetry → rollback) regardless of Delivery Strategy section field order in `commands/brief-tasks.md`
- [X] T015 [US1] Author the doctrine section for repeating the six-task pattern once per candidate flag when Delivery Strategy names multiple flags in `commands/brief-tasks.md`

**Checkpoint**: User Story 1 doctrine complete. Six-task generation fully implemented.

---

## Phase 4: User Story 2 - Leave a non-rollout feature's tasks untouched (Priority: P1)

**Goal**: Author doctrine that produces zero rollout content and near-zero context overhead for non-rollout features

**Independent Test**: Validate Scenario 2 (Section Scenario 2 in quickstart.md): Run `/speckit.tasks` against a feature with no marker, confirm briefing emits one-line no-op and `tasks.md` gains zero rollout content

### Implementation for User Story 2

- [X] T016 [US2] Author the doctrine section for the no-op case: if `hasFlags=false` (including gate script diagnostic exit code), emit a single one-line status message and stop in `commands/brief-tasks.md`
- [X] T017 [US2] Verify the no-op message is distinct, clear, and allows readers to confirm "no rollout signal detected" in `commands/brief-tasks.md`

**Checkpoint**: User Story 2 doctrine complete. Non-rollout features pass through with zero overhead.

---

## Phase 5: User Story 3 - Withhold rollout tasks when the plan has no Delivery Strategy (Priority: P2)

**Goal**: Author doctrine that enforces Principle III (Strict Content Lineage) by withholding tasks when the plan lacks a Delivery Strategy, never falling back to spec.md

**Independent Test**: Validate Scenario 3 (Section Scenario 3 in quickstart.md): Run `/speckit.tasks` against a feature with marker but no Delivery Strategy, confirm briefing emits one-line status message (distinct from US2's no-op) and zero rollout tasks appear in `tasks.md`

### Implementation for User Story 3

- [X] T018 [US3] Author the doctrine section for the incomplete-plan case: if `hasFlags=true` but `## Delivery Strategy` section is absent, emit a distinct one-line status message reporting the gap in `commands/brief-tasks.md`
- [X] T019 [US3] Explicitly state in the doctrine that NO content is generated from `spec.md` as a substitute when Delivery Strategy is missing in `commands/brief-tasks.md`
- [X] T020 [US3] Author edge-case guidance: when Delivery Strategy is present but only partially populated, emit tasks only for elements actually present, do not fabricate missing values in `commands/brief-tasks.md`

**Checkpoint**: User Story 3 doctrine complete. Content-lineage enforcement fully implemented.

---

## Phase 6: Cross-Cutting Validation

**Purpose**: Ensure doctrine satisfies all functional requirements and constraints

- [X] T021 [P] Verify doctrine uses gate script's default mode (spec.md only), not analyze mode, in `commands/brief-tasks.md`
- [X] T022 [P] Verify doctrine contains NO instructions to invoke provider MCP tools or execute live provider actions in `commands/brief-tasks.md`
- [X] T023 [P] Verify doctrine consults spec.md only through gate script state, never mines spec.md directly for rollout task content in `commands/brief-tasks.md`
- [X] T024 [P] Verify fixed task order (flag → environments/targeting → SDK → telemetry → rollback) is encoded in doctrine, not derived from Delivery Strategy section field order in `commands/brief-tasks.md`
- [X] T025 [P] Verify doctrine properly references Feature 003's gate-script contract and Feature 006's Delivery Strategy section shape in `commands/brief-tasks.md` comments or preamble
- [X] T026 Confirm `commands/brief-tasks.md` follows the same YAML-frontmatter + Markdown-body format as `brief-specify.md`, `brief-clarify.md`, `brief-plan.md`, `brief-analyze.md`, `brief-checklist.md`, and `connect.md`

**Checkpoint**: Doctrine satisfies all functional and cross-cutting requirements.

---

## Phase 7: Fixture-Based Testing

**Purpose**: Validate the doctrine against the three user-story scenarios using fixture-based manual walkthrough

### Fixture Preparation

- [X] T027 Create fixture feature directory `specs/999-quickstart-fixture-us1/` with:
  - `spec.md` containing `## Delivery Considerations` marker
  - `plan.md` with complete `## Delivery Strategy` section (flag name, provider, phased rollout, targeting, telemetry gates, rollback)
  - Empty `tasks.md` (will be generated)
- [X] T028 Create fixture feature directory `specs/999-quickstart-fixture-us2/` with:
  - `spec.md` with NO marker
  - `plan.md` (any content)
  - Empty `tasks.md`
- [X] T029 Create fixture feature directory `specs/999-quickstart-fixture-us3/` with:
  - `spec.md` containing `## Delivery Considerations` marker
  - `plan.md` with NO `## Delivery Strategy` section
  - Empty `tasks.md`

### Scenario 1: Emit ordered rollout tasks (User Story 1, Fixtures)

- [X] T030 [P] Run `scripts/bash/rollout-gate.sh` against `specs/999-quickstart-fixture-us1/spec.md`, confirm `hasFlags=true`
- [X] T031 [P] Run `/speckit.tasks` against `specs/999-quickstart-fixture-us1/` (acting agent briefed by `commands/brief-tasks.md`)
- [X] T032 [P] Verify resulting `specs/999-quickstart-fixture-us1/tasks.md` contains all six rollout tasks in correct order
- [X] T033 [P] Verify each task's content (flag name, environment, targeting, etc.) is traceable to Delivery Strategy section values, not spec.md requirements
- [X] T034 [P] Repeat tests T030-T033 using a fixture whose Delivery Strategy section names TWO candidate flags, confirm six-task pattern repeats per flag
- [X] T035 Repeat tests T030-T033 using a fixture whose Delivery Strategy section is only partially populated (e.g., rollback conditions omitted), confirm tasks emitted only for elements present

### Scenario 2: Non-rollout feature no-op (User Story 2, Fixtures)

- [X] T036 [P] Run `scripts/bash/rollout-gate.sh` against `specs/999-quickstart-fixture-us2/spec.md`, confirm `hasFlags=false` (or exit code 2)
- [X] T037 [P] Run `/speckit.tasks` against `specs/999-quickstart-fixture-us2/`
- [X] T038 [P] Verify briefing output is a single one-line no-op message
- [X] T039 Verify resulting `specs/999-quickstart-fixture-us2/tasks.md` contains NO rollout tasks and NO rollout-related content

### Scenario 3: Missing Delivery Strategy gap detection (User Story 3, Fixtures)

- [X] T040 [P] Run `scripts/bash/rollout-gate.sh` against `specs/999-quickstart-fixture-us3/spec.md`, confirm `hasFlags=true`
- [X] T041 [P] Run `/speckit.tasks` against `specs/999-quickstart-fixture-us3/`
- [X] T042 [P] Verify briefing output is a one-line status message (distinct from US2's no-op) reporting missing Delivery Strategy
- [X] T043 Verify resulting `specs/999-quickstart-fixture-us3/tasks.md` contains NO rollout tasks and NO content derived from spec.md as substitute

### Cross-Cutting Fixture Validation

- [X] T044 [P] Confirm doctrine text contains NO provider MCP tool-invocation or live provider-execution instructions (plain read-through check)
- [X] T045 [P] Confirm doctrine text indicates spec.md is consulted only through gate script state, never mined directly (plain read-through check)
- [X] T046 Clean up fixture directories: delete `specs/999-quickstart-fixture-us1/`, `specs/999-quickstart-fixture-us2/`, `specs/999-quickstart-fixture-us3/` (do not commit to repository)

**Checkpoint**: All three user-story scenarios validated. Doctrine is production-ready.

---

## Phase 8: Polish & Documentation

**Purpose**: Finalize the doctrine, document assumptions, and prepare for rollout-chain handoff

- [X] T047 Add preamble to `commands/brief-tasks.md` documenting:
  - The doctrine's role in the rollout chain (vision.md §4)
  - References to Feature 003 (gate script contract), Feature 006 (Delivery Strategy shape)
  - Constitution Principle III enforcement (content lineage)
- [X] T048 Verify `extension.yml` already wires the `before_tasks` hook to `commands/brief-tasks.md` (no change needed)
- [X] T049 Confirm no changes are required to `scripts/bash/rollout-gate.sh`, `scripts/powershell/rollout-gate.ps1`, `rollout-config.template.yml`, or other `brief-*.md` files
- [X] T050 Update `specs/007-rollout-tasks-doctrine/checklists/requirements.md` with final checklist against spec.md's functional requirements and acceptance criteria

**Checkpoint**: Feature 007 is complete, documented, and ready for downstream use in Feature 008+ (rollout analyze & implement doctrines).

---

## Dependencies & Execution Order

**Sequential dependencies** (must complete before proceeding):
- **Phase 1 → Phase 2**: Setup context → foundational doctrine framework
- **Phase 2 → Phases 3-5**: Framework in place → scenario-specific doctrines (US1, US2, US3 can run in parallel)
- **Phases 3-5 → Phase 6**: Doctrine authored → cross-cutting validation
- **Phase 6 → Phase 7**: Validation complete → fixture-based testing
- **Phase 7 → Phase 8**: Testing validated → polish & documentation

**Parallel opportunities**:
- **Phase 3 (US1)**: Tasks T008-T013 can run in parallel (distinct task types, no dependencies)
- **Phase 4 (US2)**: Tasks T016-T017 (independent, minimal)
- **Phase 5 (US3)**: Tasks T018-T020 (independent, minimal)
- **Phase 6**: Tasks T021-T025 can run in parallel (distinct validation checks)
- **Phase 7 (Fixtures)**: Fixture preparation (T027-T029), Scenarios 1-3 validation tasks, and cross-cutting checks can run in parallel once fixtures are ready

---

## Suggested MVP Scope

**Phase 1 (Setup)**: ✅ Complete all understanding/context tasks
**Phase 2 (Foundational)**: ✅ Author core doctrine framework
**Phases 3-5 (US1, US2, US3)**: ✅ Author all three scenario doctrines
**Phase 6 (Cross-Cutting)**: ✅ Validate doctrine completeness
**Phase 7 (Fixtures)**: ✅ Validate through manual walkthrough (Scenarios 1, 2, 3)
**Phase 8 (Polish)**: ✅ Finalize documentation

**Total effort**: ~16-24 hours for an experienced prompt/doctrine engineer familiar with the rollout chain and vision.md principles. First-time implementer: ~32-40 hours (includes learning curve on Spec Kit patterns and the rollout-extension architecture).
