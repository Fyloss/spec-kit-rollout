---
description: "Task list for Rollout Plan Doctrine (Pre-Plan Briefing) implementation"
---

# Tasks: Rollout Plan Doctrine (Pre-Plan Briefing)

**Input**: Design documents from `/specs/006-rollout-plan-doctrine/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Manual validation per quickstart.md — this is a content-only feature (no code framework needed for unit tests)

**Organization**: Tasks are organized by user story to enable independent review and validation of each doctrine branch

## Format: `- [ ] [ID] [P?] [Story] Description`

- **[ID]**: Sequential task number (T001, T002, etc.) in execution order
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize task generation and document the doctrine structure

- [X] T001 Review spec.md (3 user stories), plan.md (single-file deliverable), data-model.md (3 entities), research.md (decisions), and quickstart.md (validation guide)
- [X] T002 Confirm shared gate script (`scripts/bash/rollout-gate.sh` / `scripts/powershell/rollout-gate.ps1`) is available from Feature 003
- [X] T003 Confirm Feature 004's marker convention (`## Delivery Considerations` heading, `Candidate flag(s):` label) in spec.md is the source of truth
- [X] T004 Confirm Feature 005's clarified rollout parameters (phases, audience/segments, percentages, telemetry gates, rollback conditions) will feed the Delivery Strategy content
- [X] T005 Note that `templates/rollout-section.md` (Feature 12, out of scope) is optional; doctrine must work without it

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the doctrine's core branching logic and foundation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Design the doctrine's top-level branching structure in `commands/brief-plan.md`: (1) Invoke shared gate script to check for marker, (2) If marker present → Delivery Strategy path, (3) If no marker → /plan arguments sniff path, (4) If sniff finds signals → back-fill marker + Delivery Strategy, (5) If sniff finds nothing → one-line no-op
- [X] T007 Document the exact YAML frontmatter for `commands/brief-plan.md` to match the format of `commands/brief-specify.md`, `commands/brief-clarify.md`, and other `commands/brief-*.md` files
- [X] T008 Define the exact heading and label convention (`## Delivery Considerations`, `Candidate flag(s):`) that the back-fill path MUST use verbatim to match the gate script's `extract_flags_line` regex
- [X] T009 Confirm the Delivery Strategy section's six required elements (feature flag name, Provider: LaunchDarkly, phased rollout, targeting rules, telemetry gates, rollback conditions) will be present in all doctrine-generated content

**Checkpoint**: Foundation ready — User Story 1 & 2 doctrine can now be authored

---

## Phase 3: User Story 1 & 2 - Delivery Strategy for already-flagged features + non-rollout features left untouched (Priority: P1)

**Goal**: Author the core Delivery Strategy doctrine and the no-op branch

**Independent Test**: Manually run scenarios 1 & 2 from quickstart.md, confirming Delivery Strategy section appears when marker present, and no rollout content appears when marker absent

### Implementation for User Stories 1 & 2

- [X] T010 [P] [US1] Author the "marker present" branch of doctrine in `commands/brief-plan.md`: instruct agent to add `## Delivery Strategy` section to plan.md with feature flag name (from marker), `Provider: LaunchDarkly`, phased rollout sequence, targeting rules, telemetry gates, rollback conditions
- [X] T011 [P] [US1] Document in doctrine that Delivery Strategy content MUST derive from spec's stated requirements + any clarified rollout parameters in the marker (Feature 005); agent proposes draft values for missing elements grounded in spec, never invents independently
- [X] T012 [P] [US1] Document in doctrine that agent may consult optional `templates/rollout-section.md` for structural consistency but MUST NOT require its presence
- [X] T013 [US1] Author the "no marker, no sniff signals" branch of doctrine in `commands/brief-plan.md`: instruct agent to emit one-line no-op and add zero rollout content to plan.md
- [X] T014 [P] [US2] Verify doctrine branches are mutually exclusive and cover all cases (marker present → Delivery Strategy; marker absent + sniff finds nothing → no-op)
- [X] T015 [US2] Confirm doctrine makes clear that for Story 2, no Delivery Strategy section and no other rollout content appear, and spec.md remains unchanged

**Checkpoint**: User Stories 1 & 2 doctrine complete — Delivery Strategy for flagged features works, non-rollout features untouched

---

## Phase 4: User Story 3 - Catch rollout intent introduced late, at plan time (Priority: P2)

**Goal**: Author the `/plan` arguments sniff and marker back-fill branches

**Independent Test**: Manually run scenario 3 from quickstart.md, confirming marker back-fill into spec.md and Delivery Strategy generation happen in same run when /plan arguments contain rollout signals

### Implementation for User Story 3

- [X] T016 [P] [US3] Author the `/plan` arguments sniff branch in `commands/brief-plan.md`: instruct agent to perform minimal cheap sniff only when gate reports no marker (`hasFlags=false` or exit code 2)
- [X] T017 [P] [US3] Document in doctrine the exact rollout-signal heuristics for the sniff (reuse specify-time categories: high-risk/irreversible changes, major UX changes, progressive migrations, cohort/percentage language, performance/infra-sensitive changes)
- [X] T018 [US3] Document in doctrine that sniff checks current `/plan` invocation's own arguments ONLY in the no-marker branch; never runs when gate already reports marker; never overrides existing marker
- [X] T019 [US3] Author the "sniff finds signals" branch in `commands/brief-plan.md`: instruct agent to back-fill `## Delivery Considerations` marker into spec.md using exact Feature 004 convention (heading + label), then proceed to produce Delivery Strategy section as if marker had existed from start
- [X] T020 [US3] Document in doctrine that back-filled marker MUST match Feature 003's gate script recognition (heading: `^## Delivery Considerations`, case-insensitive label substring: `candidate flag(s):`) so downstream phases (clarify, analyze, checklist, later plan re-run) treat it identically to an original marker
- [X] T021 [US3] Document in doctrine that agent derives back-filled marker's rollout-intent statement from `/plan` arguments' rollout language (similar to Feature 004's original statement)
- [X] T022 [US3] Add edge case handling: if feature directory cannot be resolved by gate script (exit code 2), treat as no marker and proceed to sniff; if `/plan` arguments sniff finds no signals and no marker, proceed exactly as Story 2 (one-line no-op)
- [X] T023 [US3] Confirm doctrine covers edge case where marker exists + `/plan` arguments contain rollout signals: existing marker takes precedence as state signal; sniff never runs or overwrites in this branch

**Checkpoint**: User Story 3 doctrine complete — Late rollout intent detected, marker back-filled, Delivery Strategy generated in same run

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final review, validation, and cleanup

- [X] T024 [P] Verify all doctrine content in `commands/brief-plan.md` follows the YAML frontmatter + Markdown body format of existing `commands/brief-*.md` files
- [X] T025 [P] Confirm doctrine text contains NO task-breakdown instructions (that belongs to Feature 7's `before_tasks` briefing)
- [X] T026 [P] Confirm doctrine text contains NO feature-flag-provider MCP interaction instructions (that belongs to `before_implement` briefing); naming LaunchDarkly in Delivery Strategy section is in scope, but calling provider tools is not
- [X] T027 [P] Confirm doctrine does NOT require `templates/rollout-section.md` to exist
- [X] T028 [P] Confirm doctrine does NOT modify `extension.yml`, gate scripts, `rollout-config.template.yml`, or any other `commands/brief-*.md` file
- [X] T029 Manually validate `commands/brief-plan.md` against quickstart.md Scenario 1 (already-flagged feature, Delivery Strategy appears)
- [X] T030 Manually validate `commands/brief-plan.md` against quickstart.md Scenario 2 (no-marker, no-signals, no-op, no rollout content)
- [X] T031 Manually validate `commands/brief-plan.md` against quickstart.md Scenario 3 (no-marker, late intent sniffed, marker back-filled, Delivery Strategy generated)
- [X] T032 [P] Manually run cross-cutting checks from quickstart.md: confirm no task-breakdown/MCP instructions in doctrine, confirm LaunchDarkly named in Delivery Strategy instructions, confirm no `templates/rollout-section.md` requirement
- [X] T033 [P] Delete any scratch fixture directories (e.g., `specs/999-quickstart-fixture/`) used during validation; do not commit
- [X] T034 Review `commands/brief-plan.md` final content against all spec.md Requirements (FR-001 through FR-010, SC-001 through SC-004)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories 1 & 2 (Phase 3)**: Depends on Foundational completion
- **User Story 3 (Phase 4)**: Depends on Foundational AND User Stories 1 & 2 completion (builds on existing Delivery Strategy branch)
- **Polish (Phase 5)**: Depends on all user story doctrine being complete

### Within User Story 3

- T016-T018: /plan sniff design (parallel safe)
- T019-T023: Marker back-fill and edge case handling (depends on sniff foundation)
- T024-T034: Cross-cutting validation (depends on all content complete)

### Parallel Opportunities

- **Phase 1 (Setup)**: All tasks sequential (dependency chain)
- **Phase 2 (Foundational)**: All tasks sequential (logical flow, foundation must be solid)
- **Phase 3 (US1 & US2)**: T010-T012 and T014 can run in parallel (different aspects of same doctrine branch); T013 and T015 are sequential dependencies on earlier tasks
- **Phase 4 (US3)**: T016-T018 (sniff design) can run in parallel; T019-T023 (back-fill) depend on sniff completion
- **Phase 5 (Polish)**: T024-T028 (format/scope checks) can run in parallel; T029-T032 (validation) can run in parallel; T033-T034 (final checks) sequential

---

## Parallel Example: User Story 1 & 2 Doctrine Authoring

```bash
# Launch all doctrine authoring for Delivery Strategy branch together:
Task: "Author the marker present branch (Delivery Strategy section)" [T010]
Task: "Document Delivery Strategy content lineage from spec + marker" [T011]
Task: "Document optional templates/rollout-section.md consultation" [T012]

# After sniff is complete, launch core validation:
Task: "Verify doctrine branches are mutually exclusive" [T014]
```

---

## Parallel Example: Phase 5 Validation

```bash
# Launch all format/scope checks together:
Task: "Verify YAML frontmatter + Markdown body format" [T024]
Task: "Confirm NO task-breakdown instructions" [T025]
Task: "Confirm NO provider MCP instructions" [T026]
Task: "Confirm NO templates/rollout-section.md requirement" [T027]
Task: "Confirm NO modifications to other files" [T028]

# Launch all manual validation scenarios together:
Task: "Validate Scenario 1 (already-flagged feature)" [T029]
Task: "Validate Scenario 2 (non-rollout feature)" [T030]
Task: "Validate Scenario 3 (late rollout intent)" [T031]
Task: "Run cross-cutting checks" [T032]
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — establishes doctrine branching)
3. Complete Phase 3: User Stories 1 & 2 (core Delivery Strategy for flagged features + no-op for non-rollout)
4. **STOP and VALIDATE**: Manual test Scenarios 1 & 2 from quickstart.md
5. **DELIVER**: `commands/brief-plan.md` with Delivery Strategy + no-op branches working, covering ~80% of use cases

### Incremental Delivery

1. Deliver Phase 3 (US1 & US2): Core Delivery Strategy for already-flagged features; non-rollout features unaffected
2. Deliver Phase 4 (US3): Add late-intent detection and marker back-fill; now catches rollout language supplied at plan time
3. Deliver Phase 5: Full validation and polish

### Single-Developer Strategy

1. Work through Phases 1-2 (setup + foundation) → solid branching logic
2. Implement Phase 3 (US1 & US2) → test Scenarios 1-2 manually
3. Implement Phase 4 (US3) → test Scenario 3 manually
4. Implement Phase 5 (polish) → final validation, cleanup

---

## Notes

- This is a **content-only feature** — the only deliverable is rewriting `commands/brief-plan.md`
- No code to unit-test; validation is manual walkthrough of the doctrine against quickstart.md scenarios
- Each user story represents a distinct doctrine branch (marker present → Delivery Strategy; no marker + sniff signals → back-fill; no marker + no signals → no-op)
- Delivery Strategy content is grounded in spec + marker parameters, never invented independently
- Back-filled marker MUST match Feature 003's gate script recognition patterns exactly
- Doctrine must work whether or not `templates/rollout-section.md` exists (Feature 12, out of scope)
- Stop at Phase 3 checkpoint to validate MVP (Scenarios 1-2); Phase 4 adds the late-detection safety net
- All validation is manual per quickstart.md; no automated tests in this repository
