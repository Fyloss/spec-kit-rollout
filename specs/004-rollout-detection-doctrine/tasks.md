---

description: "Task list for the rollout detection doctrine (pre-specify briefing)"
---

# Tasks: Rollout Detection Doctrine (Pre-Specify Briefing)

**Input**: Design documents from `/specs/004-rollout-detection-doctrine/`

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md)

**Tests**: No dedicated test framework is introduced (see plan.md Technical Context — this feature is a content-only prompt rewrite, not code). Verification uses the fixture-based scenarios from quickstart.md, wired into the relevant user-story phases below as explicit checkpoint tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All tasks edit a **single file** (`commands/brief-specify.md`), so most tasks are sequential (not parallelizable) even though the story grouping mirrors spec.md's independent-test structure.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies) — largely inapplicable here since every content task touches the same file
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)

## Path Conventions

- **Single project (Spec Kit extension package)**: one existing file is rewritten in place — `commands/brief-specify.md` at the repository root, per plan.md Project Structure. No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`, or any other `commands/brief-*.md` file (explicitly out of scope — see plan.md).

---

## Phase 1: Setup

**Purpose**: Gather the doctrine sources before rewriting the placeholder file

- [X] T001 Re-read the current placeholder body of `commands/brief-specify.md`, `docs/foundation/vision.md` §4/§5.1/§5.2, and `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`'s exact marker-matching rules (heading + `Candidate flag(s):` label), alongside this feature's `research.md` decisions, to confirm the exact text this rewrite must produce

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared frontmatter, role framing, scope boundary, and advisory-framing instructions every user story's content depends on

**⚠️ CRITICAL**: No user-story-specific doctrine content can be added until this phase is complete

- [X] T002 In `commands/brief-specify.md`: update the YAML frontmatter `description` and replace the "Placeholder. This command is registered..." Status line with real doctrine framing — state the command's role (inject detection doctrine before `/speckit.specify`), and add an explicit scope-boundary statement that this file covers specify-phase detection only, MUST NOT include `Delivery Strategy`/plan-tasks content or provider/MCP interaction instructions (FR-009), and MUST NOT name any feature-flag provider (FR-004) (depends on T001)
- [X] T003 In `commands/brief-specify.md`: add the shared "detection is advisory" framing paragraph that Stories 1, 3, and 4 all build on — on a clear match, propose the rollout framing and briefly explain why (FR-006); on ambiguity, ask exactly one clarifying question (FR-007, elaborated in Phase 5); the user may always decline, and on decline (or no answer) the agent MUST NOT write the marker (FR-008, elaborated in Phase 6) (depends on T002)

**Checkpoint**: The file's frontmatter, role, scope boundary, and shared advisory framing are in place — ready for heuristic-specific and marker-writing content

---

## Phase 3: User Story 1 - Detect a rollout candidate and record intent (Priority: P1) 🎯 MVP

**Goal**: On a clear detection match, the agent proposes and writes a `## Delivery Considerations` marker (candidate flag + rollout intent) that the Feature 003 gate script recognizes

**Independent Test**: Run `/speckit.specify` with a feature description containing unambiguous high-risk or cohort language and confirm the resulting `spec.md` contains a `## Delivery Considerations` section naming a candidate flag and rollout intent, with no provider name anywhere, and that `scripts/bash/rollout-gate.sh` reports `hasFlags=true`

### Implementation for User Story 1

- [X] T004 [US1] In `commands/brief-specify.md`: write the Detection Heuristic Set section — the five named categories (high-risk/irreversible change; major UX change; progressive/staged migration; explicit cohort/audience language — beta, internal, canary, percentage, country/region; performance-/infrastructure-sensitive change) with example signals for each, per data-model.md's Detection Heuristic Set entity (FR-001; depends on T003)
- [X] T005 [US1] In `commands/brief-specify.md`: write the "on clear match" instructions — propose adding the `## Delivery Considerations` section and explain why; require the exact heading `## Delivery Considerations` and a line containing the literal `Candidate flag(s):` label followed by one or more comma-separated flag names, plus a rollout-intent statement; require exactly one such section even when multiple heuristic categories match at once; explicitly forbid naming a feature-flag provider in this section (FR-002, FR-003, FR-004; spec.md edge case "matches multiple heuristic categories at once"; depends on T004)
- [X] T006 [US1] Run [quickstart.md](./quickstart.md) Scenario 1 (clear rollout candidate fixture) using the updated doctrine and confirm the fixture `spec.md` contains the marker with a candidate flag + rollout-intent statement, no provider name appears, and `scripts/bash/rollout-gate.sh` reports `hasFlags=true` with the correct flag name(s) and `source=spec.md` (SC-001, SC-003, SC-004; depends on T005)

**Checkpoint**: User Story 1 is fully functional and independently testable — the entry point of the rollout chain works

---

## Phase 4: User Story 2 - Leave a trivial feature spec untouched (Priority: P1)

**Goal**: When no detection heuristic matches, the specify flow adds no rollout content and no visible overhead

**Independent Test**: Run `/speckit.specify` with a feature description containing none of the documented heuristics and confirm the resulting `spec.md` contains no `## Delivery Considerations` section, and that `scripts/bash/rollout-gate.sh` reports `hasFlags=false`

### Implementation for User Story 2

- [X] T007 [US2] In `commands/brief-specify.md`: write the "no heuristic match" instruction — when none of the five categories are matched, add no rollout-related content of any kind, and add no visible overhead to the specify flow beyond what the hook mechanism itself already contributes (FR-005; depends on T004, since it is the explicit complement to the match case — must be placed immediately after the heuristic set and match instructions to avoid ambiguity about when it applies)
- [X] T008 [US2] Run [quickstart.md](./quickstart.md) Scenario 2 (trivial feature fixture) using the updated doctrine and confirm the fixture `spec.md` contains no `## Delivery Considerations` section and no other rollout-related content, and that `scripts/bash/rollout-gate.sh` reports `hasFlags=false` (SC-002; depends on T007)

**Checkpoint**: User Stories 1 AND 2 both work independently — the doctrine neither under- nor over-triggers on the two clear-cut cases

---

## Phase 5: User Story 3 - Ask one clarifying question on ambiguous signals (Priority: P2)

**Goal**: On ambiguous signals, the agent asks exactly one targeted clarifying question about rollout intent, then proceeds according to the answer

**Independent Test**: Run `/speckit.specify` with a deliberately ambiguous feature description and confirm the agent asks exactly one rollout-related clarifying question, and that the final `spec.md` reflects the answer (marker present only if the answer indicates rollout intent)

### Implementation for User Story 3

- [X] T009 [US3] In `commands/brief-specify.md`: elaborate the ambiguity-handling instruction introduced in T003 — when signals are ambiguous (neither a clear match per T004/T005 nor clearly absent per T007), ask exactly one clarifying question about rollout intent using the normal interactive `/speckit.specify` flow (no new mechanism, per research.md); write the marker (per T005's convention) only if the answer confirms rollout intent; if the user does not answer, default to not writing the marker (FR-007; spec.md edge case "user does not answer the single clarifying question"; depends on T005, T007)
- [X] T010 [US3] Run [quickstart.md](./quickstart.md) Scenario 3 (ambiguous fixture, both the confirming-answer and declining-answer branches) using the updated doctrine and confirm exactly one clarifying question is asked in each run, the marker is written only when the answer confirms rollout intent, and no rollout content appears when the answer denies it (SC-005; depends on T009)

**Checkpoint**: User Stories 1, 2, AND 3 all work independently — the residual ambiguous middle ground is handled without over- or under-asking

---

## Phase 6: User Story 4 - User declines a proposed rollout framing (Priority: P3)

**Goal**: When a feature clearly matches detection heuristics but the developer explicitly declines the proposed rollout framing, the agent does not write the marker

**Independent Test**: Run `/speckit.specify` with a feature description matching detection heuristics, explicitly decline the agent's proposed rollout framing, and confirm the resulting `spec.md` contains no `## Delivery Considerations` section

### Implementation for User Story 4

- [X] T011 [US4] In `commands/brief-specify.md`: write the explicit decline-handling instruction — when the user declines a proposed rollout framing (whether proposed directly on a clear match per T005, or after the single clarifying question per T009), the agent MUST NOT write the marker and MUST add no other rollout-related content (FR-008; depends on T005, T009)
- [X] T012 [US4] Run [quickstart.md](./quickstart.md) Scenario 4 (clear-match fixture with an explicit decline) using the updated doctrine and confirm the resulting fixture `spec.md` contains no `## Delivery Considerations` section and no other rollout-related content (depends on T011)

**Checkpoint**: All four user stories are independently functional — detection is fully advisory, never a mandate

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verify scope boundaries, full placeholder replacement, and cross-cutting checks that span all user stories

- [X] T013 Read through the complete `commands/brief-specify.md` and confirm the FR-009 scope boundary holds: no `Delivery Strategy` structure, no rollout task lists, and no feature-flag-provider/MCP interaction instructions appear anywhere in the file (depends on T002, T005, T007, T009, T011)
- [X] T014 Confirm no feature-flag provider name (e.g., "LaunchDarkly") appears anywhere in `commands/brief-specify.md`, and confirm the original placeholder "Status: Placeholder" language (FR-010) has been fully replaced with no leftover placeholder text (SC-004; depends on T013)
- [X] T015 Run the [quickstart.md](./quickstart.md) cross-cutting checks section against the finalized `commands/brief-specify.md`, and delete any scratch fixture feature directories (e.g. `specs/999-quickstart-fixture/`) created during Scenarios 1-4 (depends on T006, T008, T010, T012, T014)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (establishes the frontmatter, scope boundary, and shared advisory framing every story's content is appended to)
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion, and — because every task edits the same single file in place — must be applied **sequentially in priority order** (US1 → US2 → US3 → US4) rather than in parallel, even though each story remains independently testable via its own quickstart scenario once its content is in place
- **Polish (Phase 7)**: Depends on all four user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — no dependencies on other stories
- **User Story 2 (P1)**: Textually depends on User Story 1's content being present in the file first (T007 is placed immediately after the match instructions to avoid ambiguity about scope), but is independently testable via its own quickstart scenario
- **User Story 3 (P2)**: Builds on both US1's marker convention (T005) and US2's no-match instruction (T007) to define the ambiguous middle ground
- **User Story 4 (P3)**: Builds on both US1's proposal step (T005) and US3's clarifying-question step (T009) to define the decline path for each

### Within Each User Story

- Doctrine content is written before its quickstart verification task
- Verification tasks depend on all content tasks in the same phase being complete
- Story complete before moving to the next priority (single-file sequencing, no parallel story work)

### Parallel Opportunities

- None across content-writing tasks — every task in Phases 2-6 edits the same file (`commands/brief-specify.md`) and must be applied in sequence
- T001 (Setup, read-only research) has no file conflicts with any other task, but there is nothing else in Phase 1 to run it alongside

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md Scenario 1 independently
5. This alone makes the doctrine functional for the entry-point case (vision.md §4-5.1)

### Incremental Delivery

1. Complete Setup + Foundational → shared framing ready
2. Add User Story 1 → validate with Scenario 1 → detection + marker-writing works (MVP!)
3. Add User Story 2 → validate with Scenario 2 → confirms no over-triggering
4. Add User Story 3 → validate with Scenario 3 → ambiguous cases handled
5. Add User Story 4 → validate with Scenario 4 → decline path respected
6. Complete Phase 7 Polish → confirm scope boundaries and full placeholder replacement

---

## Notes

- All tasks operate on the single file `commands/brief-specify.md` — sequencing (not parallelism) is the operative constraint for this feature
- `[Story]` label maps task to specific user story for traceability, per spec.md priorities
- Each user story's quickstart scenario is the "test" for this content-only feature — there is no automated test suite to write or run
- Commit after each phase (or logical group of tasks within a phase)
