---
description: "Task list for implementing Rollout Checklist Doctrine (Pre-Checklist Briefing)"
---

# Tasks: Rollout Checklist Doctrine (Pre-Checklist Briefing)

**Input**: Design documents from `/specs/009-rollout-checklist-doctrine/`

**Prerequisites**: plan.md (required), spec.md (required), data-model.md, research.md

**Tests**: Manual quickstart validation per quickstart.md - no automated test framework added (consistent with Features 004-008 precedent)

**Organization**: Tasks are grouped by user story to enable independent authoring and validation of each story's doctrine

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Documentation & Gate Script Integration Review)

**Purpose**: Understand the gate script contract and existing checklist format requirements

- [X] T001 Review `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` to document gate script stdout contract (hasFlags, flags fields)
- [X] T002 Review `.github/agents/speckit.checklist.agent.md` to document existing checklist item format (`- [ ] CHKxxx <item text>`) and category structure
- [X] T003 Review `commands/brief-specify.md` and `commands/brief-clarify.md` to understand marker writing/refinement patterns already in place

---

## Phase 2: Foundational (Shared Infrastructure & Content Structure)

**Purpose**: Establish the doctrine structure that applies across all user stories

**⚠️ CRITICAL**: No user story doctrine authoring can begin until this phase is complete

- [X] T004 Create YAML frontmatter template in `commands/brief-checklist.md` matching existing command file format (see `commands/brief-plan.md` pattern)
- [X] T005 Document the shared gate script invocation pattern in doctrine (default mode, spec.md-only check)
- [X] T006 Document the no-op message output requirement (single-line, zero rollout content added when hasFlags=false)
- [X] T007 Define the rollout-quality category structure: distinct `##` heading, incremented CHK IDs, five baseline items
- [X] T008 [P] Document the five baseline rollout-quality items: flag naming, environments/targeting, telemetry gates, rollback conditions, rollout phases (FR-004 mapping)
- [X] T009 [P] Document the item-phrasing convention (requirements-quality questions, not implementation-verification statements, consistent with FR-005)

**Checkpoint**: Doctrine structure established - user story-specific content authoring can now proceed

---

## Phase 3: User Story 1 - Add rollout-quality checklist items (Priority: P1) 🎯 MVP

**Goal**: When a feature's spec.md carries the `## Delivery Considerations` marker, the pre-checklist briefing instructs the agent to add a dedicated rollout-quality category with five items

**Independent Test**: Run gate script against fixture spec.md with marker, run `/speckit.checklist` with doctrine, verify rollout-quality category appears with all five items phrased as requirements-quality checks

### Implementation for User Story 1

- [X] T010 [US1] Author gate-script invocation section in `commands/brief-checklist.md`: invoke shared gate script in default mode against spec.md before deciding whether to add rollout content
- [X] T011 [US1] Author rollout-marker-present branch in `commands/brief-checklist.md`: when hasFlags=true, instruct agent to add rollout-quality category to checklist generation
- [X] T012 [US1] Author requirement that when the marker names more than one candidate flag, a single shared rollout-quality category is added whose items apply across all named flags, rather than duplicating the category per flag (FR-008)
- [X] T013 [US1] Author the five baseline items with FR-004/FR-006 wording in `commands/brief-checklist.md`:
  - Item 1: Flag naming is defined (check `Candidate flag(s):` in marker and plan's Delivery Strategy)
  - Item 2: Target environments/targeting rules are specified (check plan's Delivery Strategy)
  - Item 3: Telemetry gates are defined (check plan's Delivery Strategy)
  - Item 4: Rollback conditions are present (check plan's Delivery Strategy)
  - Item 5: Rollout phases are ordered and complete (check plan's Delivery Strategy)
- [X] T014 [US1] Author requirement that each item uses `- [ ] CHKxxx <item text>` format (FR-005) and that items are phrased as verifiable checklist items consistent with existing `/speckit.checklist` conventions
- [X] T015 [US1] Author requirement that items are checked against the feature's actual rollout content (spec marker + plan Delivery Strategy once it exists), not generic boilerplate (FR-006)
- [X] T016 [US1] Author requirement that rollout-quality category is additive to whatever category/categories the user's checklist request already produces (FR-003, FR-009)

**Checkpoint**: User Story 1 doctrine complete - rollout-quality category structure and five items now defined

---

## Phase 4: User Story 2 - Non-rollout features get no rollout items (Priority: P1)

**Goal**: When a feature's spec.md contains no `## Delivery Considerations` marker, the briefing emits a single-line no-op and adds zero rollout-quality content

**Independent Test**: Run gate script against fixture spec.md without marker, run `/speckit.checklist`, verify briefing emits one-line no-op message and generated checklist contains no rollout-quality category

### Implementation for User Story 2

- [X] T017 [US2] Author rollout-marker-absent branch in `commands/brief-checklist.md`: when gate script reports hasFlags=false (including diagnostic exit code 2), emit one-line no-op message
- [X] T018 [US2] Author requirement that no-op path adds no rollout-quality category, item, or other rollout-related content to the generated checklist (FR-002)
- [X] T019 [US2] Author requirement that no-op message is a single line and produces no visible overhead for non-rollout features (SC-003)
- [X] T020 [US2] Document the gate script diagnostic exit code behavior: treat exit code 2 (gate script error) identically to hasFlags=false (FR-002)

**Checkpoint**: User Story 2 doctrine complete - non-rollout path (no-op) now fully specified

---

## Phase 5: User Story 3 - Items appear before plan.md exists (Priority: P2)

**Goal**: Rollout-quality items appear in the checklist even when plan.md lacks a `## Delivery Strategy` section, phrased as checks to perform rather than status findings

**Independent Test**: Create fixture with spec.md marker but no plan.md (or plan.md without Delivery Strategy), run `/speckit.checklist` with doctrine, verify all five items still appear and none assert a gap

### Implementation for User Story 3

- [X] T021 [US3] Author requirement in `commands/brief-checklist.md` that rollout-quality category is added regardless of whether plan.md contains a `## Delivery Strategy` section (FR-007)
- [X] T022 [US3] Ensure each of the five baseline items from T013 is phrased as a check to perform rather than a status assertion or finding (consistent with FR-005 and research.md Decision 1)
- [X] T023 [US3] Verify item phrasing patterns in `commands/brief-checklist.md`:
  - ✅ Example: "Is the feature flag name specific and unambiguous?" (question format)
  - ❌ Example: "Flag naming is missing" (finding format)
  - ❌ Example: "Verify the flag was created in the provider" (implementation-verification format)
- [X] T024 [US3] Author requirement that items remain consistent checklist items ready to be worked through during `/speckit.checklist` regardless of which phase it is run (FR-007 enforcement)

**Checkpoint**: User Story 3 doctrine complete - items now appear earlier in workflow, correctly phrased

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate completeness, ensure contract adherence, and clean up artifacts

- [X] T025 [P] Verify all functional requirements (FR-001 through FR-011) are covered in `commands/brief-checklist.md` doctrine text
- [X] T026 [P] Verify Constitution Check gates (Principles I-VI from `.specify/memory/constitution.md`) are satisfied:
  - Principle I: Additive-only (rewrite only brief-checklist.md, no core template edits)
  - Principle II: Self-gating via shared gate script
  - Principle III: Marker matches contract exactly, no new marker mutations
  - Principle IV: No provider MCP instructions or provider-specific tool invocations
  - Principle V: No credential handling introduced
  - Principle VI: N/A (before_implement gate, not this feature)
- [X] T027 [P] Validate existing file format: `commands/brief-checklist.md` currently contains YAML frontmatter + placeholder body; ensure rewritten body follows Markdown conventions matching `commands/brief-plan.md` style
- [X] T028 Run quickstart.md Scenario 1 validation manually: fixture with marker + complete Delivery Strategy → checklist includes rollout-quality category with five items
- [X] T029 Run quickstart.md Scenario 2 validation manually: fixture without marker → one-line no-op, no rollout items in checklist
- [X] T030 Run quickstart.md Scenario 3 validation manually: fixture with marker but no plan.md (or no Delivery Strategy section) → rollout-quality items still appear, phrased as checks
- [X] T031 [P] Run cross-cutting checks from quickstart.md:
  - Gate script default mode invoked (FR-001)
  - Doctrine contains no Delivery Strategy authoring instruction (out of scope)
  - Doctrine contains no provider MCP tool instructions (FR-010)
  - Doctrine contains no other checklist category instructions (FR-010)
  - Single shared category when marker names multiple flags (FR-008), per T012's authored instruction
  - No removal/replacement/reordering of other checklist categories (FR-009)
- [X] T032 [P] Verify mutation safety: run `scripts/bash/rollout-gate.sh` against each fixture's spec.md before and after `/speckit.checklist` runs, confirm `hasFlags`/`flags` values unchanged (SC-004)
- [X] T033 Clean up quickstart fixture directories (e.g., `specs/999-quickstart-fixture/` if created) — do not commit fixtures
- [X] T034 Run `scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` to confirm all prerequisites met and tasks.md is complete

**Checkpoint**: All scenarios validated, cross-cutting checks pass, fixtures cleaned up

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (Phase 3, P1): Can start after Foundational - MVP story, core rollout-quality category logic
  - US2 (Phase 4, P1): Can start after Foundational - Equal priority to US1, no-op path
  - US3 (Phase 5, P2): Can start after Foundational - Lower priority, temporal behavior
  - US1 and US2 should both complete before US3 validation
- **Polish (Phase 6)**: Depends on all user stories (US1, US2, US3) being complete

### Within User Stories

- US1 doctrine sections should be authored in order (gate invocation → marker-present branch → multi-flag handling → five items → format/phrasing requirements)
- US2 can be worked in parallel with US1 once US1 sections T010-T011 are drafted
- US3 depends on US1's five items being finalized (T013) before validating temporal behavior (T021-T024)
- All validation tasks (T025-T034) depend on all three user story doctrines being complete

### Parallel Opportunities

- **Within Setup (Phase 1)**: T001, T002, T003 can run in parallel (independent file reviews)
- **Within Foundational (Phase 2)**: T008, T009 marked [P] can run in parallel (shared documentation)
- **Within Polish (Phase 6)**: T025, T026, T027, T031, T032 marked [P] can run in parallel (validation checks)
- **Across User Stories**: Once Foundational completes, US1 (Phase 3) and US2 (Phase 4) can be drafted in parallel, with both feeding into US3 validation (Phase 5)

### Parallel Example: All Validation Tasks

Once US1, US2, US3 doctri are complete:

```
T025 (Validate FRs)  ──┐
T026 (Constitution)  ──┤
T027 (Format check)   ──┼─► All parallel (independent checks)
T031 (Cross-check)   ──┤
T032 (Mutation safety)─┘

Then sequentially:
T028 ► T029 ► T030 (Scenarios must be run in order: fixture setup)

Finally:
T033 (Cleanup) ► T034 (Prerequisite check)
```

---

## Summary

**Total tasks**: 34
**Setup tasks**: 3
**Foundational tasks**: 6
**User Story 1 (P1) tasks**: 7
**User Story 2 (P1) tasks**: 4
**User Story 3 (P2) tasks**: 4
**Polish tasks**: 10

**Deliverable**: Single file rewritten
- `commands/brief-checklist.md` — placeholder body replaced with full pre-checklist doctrine per FR-001 through FR-011

**Independent Test Criteria**:

- **US1**: Fixture with marker + complete plan → checklist contains rollout-quality category with all five items ✓
- **US2**: Fixture without marker → one-line no-op, no rollout items ✓
- **US3**: Fixture with marker but no plan → all five items appear, phrased as checks ✓

**Suggested MVP scope**: Complete US1 (Phase 3) and US2 (Phase 4) — both P1 priorities together establish the core gate-conditional behavior. US3 (Phase 5) can follow as P2 follow-up for temporal behavior correctness.
