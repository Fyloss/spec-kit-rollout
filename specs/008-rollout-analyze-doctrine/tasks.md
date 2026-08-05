---
description: "Task list for Rollout Analyze Doctrine (Pre-Analyze Briefing) implementation"
---

# Tasks: Rollout Analyze Doctrine (Pre-Analyze Briefing)

**Input**: Design documents from `/specs/008-rollout-analyze-doctrine/`

**Prerequisites**: spec.md (required for user stories), plan.md (required), data-model.md, research.md, quickstart.md

**Tests**: Manual validation per quickstart.md — this is a content-only feature (no code framework needed for unit tests)

**Organization**: Tasks are organized by user story to enable independent review and validation of each doctrine branch

## Format: `- [ ] [ID] [P?] [Story] Description`

- **[ID]**: Sequential task number (T001, T002, etc.) in execution order
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize task generation and document the doctrine structure

- [X] T001 Review spec.md (4 user stories), plan.md (single-file deliverable), data-model.md (2 entities: Rollout Chain, Rollout-Chain Finding), research.md (decisions), and quickstart.md (validation guide)
- [X] T002 Confirm shared gate script (`scripts/bash/rollout-gate.sh` / `scripts/powershell/rollout-gate.ps1`) is available from Feature 003
- [X] T003 Confirm Feature 004's marker convention (`## Delivery Considerations` heading, `Candidate flag(s):` label) in spec.md is the source of truth for gate check
- [X] T004 Confirm Feature 006's Delivery Strategy heading convention (`## Delivery Strategy` in plan.md) is established and will be checked directly
- [X] T005 Confirm Feature 007's six rollout task categories (create flag, configure environments, configure targeting, integrate SDK, add telemetry validation, define rollback conditions) are established and will be checked for presence

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the doctrine's core branching logic and heading-detection patterns

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Design the doctrine's top-level branching structure in `commands/brief-analyze.md`: (1) Invoke shared gate script (default mode, spec.md-only) to check for marker, (2) If marker absent (hasFlags=false or exit code 2) → emit one-line no-op, stop, (3) If marker present (hasFlags=true) → proceed to suppression instructions, (4) Then perform independent chain-consistency checks for plan.md and tasks.md
- [X] T007 Document the exact YAML frontmatter for `commands/brief-analyze.md` to match the format of `commands/brief-specify.md`, `commands/brief-clarify.md`, `commands/brief-plan.md`, `commands/brief-tasks.md`, and other `commands/brief-*.md` files
- [X] T008 Define the exact heading-detection regex pattern for `## Delivery Strategy` heading in plan.md (reuse Feature 006/007 convention: case-insensitive, leading `##` with optional whitespace)
- [X] T009 Define the presence-checking pattern for rollout tasks in tasks.md: detect at least one of the six task categories (Feature 007 shape) by content keyword presence (e.g., "create flag", "configure environments", "configure targeting", "integrate SDK", "add telemetry", "rollback")
- [X] T010 Confirm the gate script invocation in doctrine uses ONLY the default mode (`--spec` or default invocation) and does NOT attempt a new `--analyze` mode or extended contract (FR-001 requirement)

**Checkpoint**: Foundation ready — User Stories 1-4 doctrine can now be authored

---

## Phase 3: User Stories 1 & 2 - Suppression of false orphans + no-marker no-op (Priority: P1)

**Goal**: Author the core suppression doctrine (when chain is consistent) and the no-op branch (when no marker)

**Independent Test**: Manually run scenarios 1 & 2 from quickstart.md, confirming zero false-positive rollout findings for consistent chain, and one-line no-op with zero rollout-chain checks for non-rollout features

### Implementation for User Stories 1 & 2

- [X] T011 [P] [US1] Author the "gate reports marker present" → suppression branch in `commands/brief-analyze.md`: instruct agent to treat `## Delivery Considerations` marker, `## Delivery Strategy` section (when present), and rollout tasks (when present) as intentional, already-cross-referenced content — NEVER report any of them as orphaned requirements, unmapped tasks, duplication, or ambiguity findings
- [X] T012 [P] [US1] Document in doctrine that suppression applies to the marker itself, the Delivery Strategy heading and its entire subsection, and any task flagged as rollout-related; all three are excluded from standard analyze's detection passes (FR-003 requirement)
- [X] T013 [P] [US1] Document in doctrine the exact wording that instructs the agent: suppress false-positive findings for the marker, suppress false-positive findings for the Delivery Strategy section, suppress false-positive findings for rollout tasks, treat all three as valid and cross-referenced when present
- [X] T014 [US1] Confirm doctrine makes clear that suppression is the FIRST instruction (logically prior to chain-consistency checking) so the agent does not conflate "link is broken" with "content is orphaned" (research.md Decision: Suppression as standalone step)
- [X] T015 [P] [US2] Author the "gate reports no marker" branch in `commands/brief-analyze.md`: instruct agent to emit one-line no-op message (e.g., "No rollout markers detected; standard analysis proceeding") and STOP — perform NO further rollout-chain checks, NO rollout content inspection, NO chain findings
- [X] T016 [P] [US2] Document in doctrine that when hasFlags=false (or exit code 2), the no-op path is identical regardless of whether gate script diagnostic failed or marker is genuinely absent; both are treated as no-marker case (FR-002 requirement)
- [X] T017 [US2] Confirm doctrine ensures non-rollout features (no marker) experience ZERO visible overhead: one-line message, no rollout-specific findings, rest of analyze report identical to what it would be without extension installed (Story 2 Acceptance Scenario 1)

**Checkpoint**: User Stories 1 & 2 doctrine complete — Consistent chains have zero false orphans, non-rollout features see zero overhead

---

## Phase 4: User Story 3 - Detect chain broken between spec and plan (Priority: P2)

**Goal**: Author the spec-to-plan break detection logic and finding wording

**Independent Test**: Manually run scenario 3 from quickstart.md, confirming exactly one HIGH-severity finding for missing Delivery Strategy section when marker is present

### Implementation for User Story 3

- [X] T018 [P] [US3] Author the spec-to-plan chain-check branch in `commands/brief-analyze.md`: after confirming marker present (gate script hasFlags=true), instruct agent to check plan.md for `## Delivery Strategy` heading using the exact regex from Phase 2 T008
- [X] T019 [P] [US3] Document in doctrine the exact finding structure for the spec-to-plan break (HIGH severity, category: Rollout Chain or Coverage Gap, locations: spec.md marker + plan.md, summary: "marker present in spec.md but no Delivery Strategy section found in plan.md")
- [X] T020 [US3] Document in doctrine that the spec-to-plan finding MUST be worded such that the gap is identified as missing plan content, NOT as the marker being orphaned (User Story 3 Acceptance Scenario 2 requirement; research.md Decision: Suppression as standalone step prevents conflation)
- [X] T021 [US3] Confirm finding wording does NOT suggest the marker itself is untraceable, unmapped, or duplicative; wording focuses on the missing Delivery Strategy section in plan.md (e.g., "Delivery Strategy section is missing from plan.md but required by the Delivery Considerations marker in spec.md")
- [X] T022 [P] [US3] Document in doctrine the edge case: if gate script diagnostic fails (exit code 2), treat as no marker and skip chain-checking entirely; proceed to one-line no-op (Feature 002 pattern)
- [X] T023 [US3] Confirm doctrine does NOT emit this finding if gate script reports no marker (hasFlags=false) — only when hasFlags=true and Delivery Strategy is absent

**Checkpoint**: User Story 3 doctrine complete — Spec-to-plan breaks detected and reported with clear wording distinguishing the gap from marker validity

---

## Phase 5: User Story 4 - Detect chain broken between plan and tasks (Priority: P2)

**Goal**: Author the plan-to-tasks break detection logic and finding wording

**Independent Test**: Manually run scenario 4 from quickstart.md, confirming exactly one HIGH-severity finding for missing rollout tasks when Delivery Strategy is present

### Implementation for User Story 4

- [X] T024 [P] [US4] Author the plan-to-tasks chain-check branch in `commands/brief-analyze.md`: after confirming Delivery Strategy section exists in plan.md (from T018 check), instruct agent to check tasks.md for at least one of the six rollout task categories (Feature 007 shape, from Phase 2 T009)
- [X] T025 [P] [US4] Document in doctrine the exact finding structure for the plan-to-tasks break (HIGH severity, category: Rollout Chain or Coverage Gap, locations: plan.md Delivery Strategy + tasks.md, summary: "Delivery Strategy section present in plan.md but no corresponding rollout tasks found in tasks.md")
- [X] T026 [US4] Document in doctrine that the plan-to-tasks finding MUST be worded distinguishably from the spec-to-plan finding (User Story 4 Acceptance Scenario 2), so a reader can immediately tell which link in the chain is broken without re-reading locations
- [X] T027 [US4] Confirm finding wording focuses on missing tasks in tasks.md (not on the Delivery Strategy being orphaned or uncovered), and is distinct from User Story 3's wording (e.g., "Delivery Strategy section exists in plan.md but no corresponding rollout tasks are present in tasks.md")
- [X] T028 [P] [US4] Document in doctrine the presence-checking rule: detect any of the six categories OR generic rollout-task markers (e.g., task descriptions containing keywords: "flag", "targeting", "environment", "telemetry", "rollback") — partial task sets are valid and consistent (Feature 007 pattern + Edge Cases in spec.md)
- [X] T029 [US4] Confirm doctrine does NOT emit this finding if Delivery Strategy section is absent from plan.md — only when Delivery Strategy exists and tasks are absent (plan-to-tasks break, not spec-to-plan break)

**Checkpoint**: User Story 4 doctrine complete — Plan-to-tasks breaks detected and reported with clear, distinct wording

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final review, validation, and cleanup

- [X] T030 [P] Verify all doctrine content in `commands/brief-analyze.md` follows the YAML frontmatter + Markdown body format of existing `commands/brief-*.md` files
- [X] T031 [P] Confirm doctrine text contains NO instructions to EDIT spec.md, plan.md, or tasks.md to fix any detected gap (FR-010 requirement: report-only, never modify)
- [X] T032 [P] Confirm doctrine text contains NO provider MCP tool invocation instructions; gate script invocation only (plain script call, no MCP wrapper)
- [X] T033 [P] Confirm doctrine does NOT require any new artifact or section beyond the three already established by prior features (spec marker, plan Delivery Strategy, tasks rollout tasks) — FR-011
- [X] T034 [P] Confirm doctrine does NOT modify `extension.yml`, gate scripts (`scripts/bash/rollout-gate.sh`, `scripts/powershell/rollout-gate.ps1`), `rollout-config.template.yml`, or any other `commands/brief-*.md` file — scope boundary per spec.md Assumptions (bullet 4) and plan.md Constraints
- [X] T035 Manually validate `commands/brief-analyze.md` against quickstart.md Scenario 1 (consistent chain, zero false-positive rollout findings)
- [X] T036 Manually validate `commands/brief-analyze.md` against quickstart.md Scenario 2 (no marker, one-line no-op, no rollout-chain checks)
- [X] T037 Manually validate `commands/brief-analyze.md` against quickstart.md Scenario 3 (marker present, no Delivery Strategy, exactly one HIGH finding with spec-to-plan gap wording)
- [X] T038 Manually validate `commands/brief-analyze.md` against quickstart.md Scenario 4 (Delivery Strategy present, no rollout tasks, exactly one HIGH finding with plan-to-tasks gap wording, distinct from Scenario 3)
- [X] T039 [P] Verify findings are distinguishable: Scenario 3 and Scenario 4 findings differ in location columns (spec.md/plan.md vs plan.md/tasks.md) and summary wording (spec-to-plan vs plan-to-tasks)
- [X] T040 [P] Manually run cross-cutting checks from quickstart.md: confirm doctrine contains no edit instructions (FR-010), confirm gate script invocation uses default mode (FR-001), confirm two findings have distinct wording (FR-005/FR-007)
- [X] T041 [P] Confirm the two chain-break findings carry HIGH severity per existing `/speckit.analyze` severity model (FR-009 requirement; `.github/agents/speckit.analyze.agent.md` reference)
- [X] T042 [P] Confirm doctrine does not introduce any new severity level or findings-table column format beyond existing analyze agent (review `.github/agents/speckit.analyze.agent.md` compatibility)
- [X] T043 [P] Delete any scratch fixture directories (e.g., `specs/999-quickstart-fixture/`) used during validation; do not commit
- [X] T044 Review `commands/brief-analyze.md` final content against all spec.md Functional Requirements (FR-001 through FR-011) and Acceptance Criteria (Stories 1-4, SC-001 through SC-005)
- [X] T045 [P] Confirm doctrine explicitly instructs reporting the rollout chain as fully consistent — zero gap/orphan findings for rollout content — when the marker, the Delivery Strategy section, and at least one traceable rollout task are all present (FR-008 requirement)
- [X] T046 [P] Confirm repeated `/speckit.analyze` runs on an unchanged fixture produce identical rollout-chain finding wording and count (SC-005 determinism check, per quickstart.md Cross-cutting checks)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories 1 & 2 (Phase 3)**: Depends on Foundational completion; delivers suppression + no-op
- **User Story 3 (Phase 4)**: Depends on Foundational AND User Stories 1 & 2 (builds on established suppression/no-op branches)
- **User Story 4 (Phase 5)**: Depends on Foundational AND User Story 3 (plan-to-tasks check requires marker-present path already established)
- **Polish (Phase 6)**: Depends on all user story doctrine being complete

### Within User Stories

- **Phase 3 (US1 & US2)**: T011-T013 (suppression wording) can run in parallel; T014 depends on suppression complete; T015-T016 (no-op) parallel safe; T017 depends on both branches complete
- **Phase 4 (US3)**: T018-T019 (finding structure) can run in parallel; T020-T023 (wording/edge cases) sequential on finding foundation
- **Phase 5 (US4)**: T024-T025 (finding structure) can run in parallel; T026-T029 (wording/presence check) sequential on finding foundation

### Parallel Opportunities

- **Phase 1 (Setup)**: All tasks sequential (dependency chain for context-gathering)
- **Phase 2 (Foundational)**: T006, T007 can run in parallel (design + format); T008-T010 sequential (logical flow for accuracy)
- **Phase 3 (US1 & US2)**: T011-T013 can run in parallel (suppression wording variants); T015-T016 can run in parallel (no-op wording variants); T014 and T017 depend on their respective parallel groups
- **Phase 4 (US3)**: T018-T019 can run in parallel (break structure); T020-T021 can run in parallel (wording); T022-T023 sequential on break structure
- **Phase 5 (US4)**: T024-T025 can run in parallel (break structure); T026-T027 can run in parallel (wording); T028-T029 sequential on break structure
- **Phase 6 (Polish)**: T030-T034 (format/scope checks) can run in parallel; T035-T038 (manual validation per scenario) can run in parallel; T039-T042, T045-T046 (cross-cutting checks) can run in parallel; T043-T044 (final cleanup) sequential

---

## Parallel Example: User Stories 1 & 2 Doctrine Authoring

```bash
# Launch all suppression-branch authoring together:
Task: "Author marker-present → suppression branch" [T011]
Task: "Document suppression applies to marker/strategy/tasks" [T012]
Task: "Document exact suppression wording" [T013]

# Launch all no-op-branch authoring together:
Task: "Author no-marker → one-line no-op branch" [T015]
Task: "Document no-marker edge cases (diagnostic exit code 2)" [T016]

# Then integrate:
Task: "Confirm suppression is logically prior to chain-checking" [T014]
Task: "Confirm non-rollout features see zero overhead" [T017]
```

---

## Parallel Example: Phase 6 Validation

```bash
# Launch all manual scenario validations together:
Task: "Validate Scenario 1 (consistent chain, zero false orphans)" [T035]
Task: "Validate Scenario 2 (no marker, no-op, no chain checks)" [T036]
Task: "Validate Scenario 3 (spec-to-plan break, HIGH finding)" [T037]
Task: "Validate Scenario 4 (plan-to-tasks break, HIGH finding)" [T038]

# Launch all cross-cutting checks together:
Task: "Verify findings are distinguishable (locations + wording)" [T039]
Task: "Verify no edit instructions, gate default mode, distinct findings" [T040]
Task: "Verify two findings carry HIGH severity" [T041]
Task: "Verify compatibility with existing analyze agent format" [T042]
Task: "Verify FR-008 consistent-chain reporting is explicit in doctrine" [T045]
Task: "Verify SC-005 determinism across repeated runs" [T046]
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Stories 1 & 2 (suppression + no-op)
4. **STOP and VALIDATE**: Test Scenarios 1 & 2 from quickstart.md
5. Deploy/demo: Core analyze doctrine (consistent chains safe, non-rollout unaffected)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Stories 1 & 2 → Test Scenarios 1 & 2 independently → Deploy/Demo (MVP!)
3. Add User Story 3 → Test Scenario 3 independently → Deploy/Demo (spec-to-plan breaks detected)
4. Add User Story 4 → Test Scenario 4 independently → Deploy/Demo (all chain breaks detected)
5. Polish → Final validation → Complete

### Notes

- [P] tasks = different files/concerns, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently validateable per quickstart.md scenarios
- Phase 2 (Foundational) is a hard blocker — gate script integration + heading patterns must be solid before user story authoring
- Suppression (US1) and no-op (US2) are both P1 and logically prior to break detection (US3/US4)
- All findings must follow existing analyze agent format (`ID | Category | Severity | Location(s) | Summary | Recommendation`)
- Verify no edit instructions are emitted (report-only requirement)
- Commit after each completed phase/user story, or at natural validation checkpoints
