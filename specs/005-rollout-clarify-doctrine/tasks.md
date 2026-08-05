---

description: "Task list for the rollout clarify doctrine (pre-clarify briefing)"
---

# Tasks: Rollout Clarify Doctrine (Pre-Clarify Briefing)

**Input**: Design documents from `/specs/005-rollout-clarify-doctrine/`

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md)

**Tests**: No dedicated test framework is introduced (see plan.md Technical Context — this feature is a content-only prompt rewrite, not code). Verification uses the fixture-based scenarios from quickstart.md, wired into the relevant user-story phases below as explicit checkpoint tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All tasks edit a **single file** (`commands/brief-clarify.md`), so most tasks are sequential (not parallelizable) even though the story grouping mirrors spec.md's independent-test structure.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies) — largely inapplicable here since every content task touches the same file
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

## Path Conventions

- **Single project (Spec Kit extension package)**: one existing file is rewritten in place — `commands/brief-clarify.md` at the repository root, per plan.md Project Structure. No changes to `extension.yml`, the gate scripts, `rollout-config.template.yml`, `commands/brief-specify.md`, or any other `commands/brief-*.md` file (explicitly out of scope — see plan.md).

---

## Phase 1: Setup

**Purpose**: Gather the doctrine sources before rewriting the placeholder file

- [X] T001 Re-read the current placeholder body of `commands/brief-clarify.md`, `docs/foundation/vision.md` §4/§5.1/§6/Decision D6, `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`'s exact marker-matching rules (heading + `Candidate flag(s):` label), the marker-writing doctrine already delivered in `commands/brief-specify.md` by Feature 004, and this feature's `research.md`/`data-model.md` decisions, to confirm the exact text this rewrite must produce

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared frontmatter, role framing, gate-invocation branching, and explicit marker-preservation guardrail every user story's content depends on

**⚠️ CRITICAL**: No user-story-specific doctrine content can be added until this phase is complete

- [X] T002 In `commands/brief-clarify.md`: update the YAML frontmatter `description` and replace the "Placeholder. This command is registered..." Status line with real doctrine framing — state the command's role (inject pre-clarify doctrine before `/speckit.clarify`), and add an explicit scope-boundary statement that this file covers clarify-phase elicitation and marker preservation only, MUST NOT include `Delivery Strategy`/plan-phase/tasks-phase content or provider/MCP interaction instructions (FR-010), and MUST NOT name any feature-flag provider (FR-009) (depends on T001)
- [X] T003 In `commands/brief-clarify.md`: write the gate-invocation and branching instruction — MUST invoke the shared gate script (`scripts/bash/rollout-gate.sh` / `scripts/powershell/rollout-gate.ps1`) to determine whether the current feature's `spec.md` carries a `## Delivery Considerations` marker before deciding what doctrine to apply; treat an unresolved feature directory (gate script exit code 2) identically to "no marker" (FR-001; spec.md edge case) (depends on T002)
- [X] T004 In `commands/brief-clarify.md`: write the explicit marker-preservation instruction, stated as a standalone rule before any elicitation instructions per research.md's decision — when a marker is present, preserve the existing `## Delivery Considerations` section and its rollout requirement, explicitly forbidding treating it as underspecified noise to be removed, shortened, or reworded away (FR-003) (depends on T003)

**Checkpoint**: The file's frontmatter, role, scope boundary, gate-invocation branching, and preservation guardrail are in place — ready for elicitation-specific and no-marker content

---

## Phase 3: User Story 1 - Elicit missing rollout parameters on a flagged feature (Priority: P1) 🎯 MVP

**Goal**: When a marker is present, the agent asks about whichever rollout parameters (phases, audience/segments, percentages, telemetry gates, rollback conditions) are not already specified, then refines the marker in place with the answers

**Independent Test**: Run `/speckit.specify` on a feature description with clear rollout signals so the marker is written, then run `/speckit.clarify` and confirm it asks about missing rollout phases/audience/percentage/telemetry/rollback, and that the resulting `spec.md` still contains a recognizable `## Delivery Considerations` marker enriched with the answers

### Implementation for User Story 1

- [X] T005 [US1] In `commands/brief-clarify.md`: write the Rollout Parameter Set section — the five named categories (rollout phases, target audience/segments, percentages, telemetry gates, rollback conditions) with the elicited detail each covers, per data-model.md's Rollout Parameter Set entity (Key Entities; depends on T004)
- [X] T006 [US1] In `commands/brief-clarify.md`: write the elicitation instruction — use clarify's normal interactive question-and-answer flow to ask about whichever Rollout Parameter Set categories are not already present in the marker, and do not re-ask about categories already present (FR-004, FR-005; depends on T005)
- [X] T007 [US1] In `commands/brief-clarify.md`: write the decline-handling instruction — when the developer declines to answer a specific rollout elicitation question, leave that parameter unspecified in the marker (or note it as still open) rather than inventing a value or blocking the rest of the clarify flow (FR-008; depends on T006)
- [X] T008 [US1] In `commands/brief-clarify.md`: write the refine-in-place instruction — after answers are given, update the `## Delivery Considerations` section in place with the clarified details, keeping the exact heading and `Candidate flag(s):` label recognizable to the gate script, never creating a new section, duplicating content, or relocating the marker elsewhere in `spec.md` (FR-006, FR-007; depends on T007)
- [X] T009 [US1] Run [quickstart.md](./quickstart.md) Scenario 1 (elicit missing rollout parameters) using the updated doctrine and confirm the agent asks only about the categories not already present, the `## Delivery Considerations` section is updated in place with no duplication or relocation, and `scripts/bash/rollout-gate.sh` reports `hasFlags=true` with the identical candidate flag name(s) before and after (SC-001, SC-003; depends on T008)

**Checkpoint**: User Story 1 is fully functional and independently testable — the entry point of the clarify-phase rollout chain works

---

## Phase 4: User Story 2 - Leave a non-rollout feature's clarify flow untouched (Priority: P1)

**Goal**: When no marker is present, the clarify flow proceeds exactly as it would without the `rollout` extension installed — no rollout questions, no rollout content

**Independent Test**: Run `/speckit.clarify` on a feature whose `spec.md` has no `## Delivery Considerations` marker, and confirm no rollout-related questions are asked and no rollout content appears anywhere in the spec afterward

### Implementation for User Story 2

- [X] T010 [US2] In `commands/brief-clarify.md`: write the no-marker instruction — when the gate reports no marker (`hasFlags=false`, including the unresolved-directory case from T003), emit a one-line no-op and add no rollout-related content or questions to the clarify flow (FR-002; depends on T004, since this is the explicit complement to the marker-present branch established in Foundational — placed immediately after the branching condition to avoid ambiguity about when it applies)
- [X] T011 [US2] Run [quickstart.md](./quickstart.md) Scenario 2 (non-rollout feature untouched) using the updated doctrine and confirm the briefing emits a one-line no-op, no rollout-related questions are asked, and the resulting fixture `spec.md` contains no `## Delivery Considerations` section or other rollout-related content (SC-002; depends on T010)

**Checkpoint**: User Stories 1 AND 2 both work independently — the doctrine neither under- nor over-triggers on the two clear-cut cases

---

## Phase 5: User Story 3 - Preserve the marker even when clarify's usual instincts would remove it (Priority: P2)

**Goal**: A sparse marker (only a candidate flag name and brief rollout-intent statement) survives clarify's pass intact, enriched rather than removed, shortened, or reworded into a generic ambiguity note

**Independent Test**: Run `/speckit.clarify` on a feature whose marker contains only a candidate flag name and a brief rollout-intent statement (no phases/audience/percentage/telemetry/rollback yet), and confirm the marker is still present after clarify finishes, with elicited detail added rather than the section being shortened, reworded, or removed

### Implementation for User Story 3

- [X] T012 [US3] In `commands/brief-clarify.md`: elaborate the sparse-marker guardrail — explicitly state that a marker containing only a candidate flag name and rollout-intent statement (no other detail) must be treated as elicitation targets (categories to ask about per T006), never as unresolved ambiguity requiring removal, shortening, or generic rewording, building on T004's preservation instruction and T006's elicitation flow (FR-003, Story 3; depends on T004, T006)
- [X] T013 [US3] Run [quickstart.md](./quickstart.md) Scenario 3 (sparse marker survives clarify's normal instincts) using the updated doctrine and confirm the section is not deleted, shortened, or reworded into a generic ambiguity note; the original candidate flag name(s) and rollout-intent statement remain present verbatim or near-verbatim; and a partial elicitation (e.g., phases and audience answered, telemetry gates left unspecified) leaves the marker with the original content plus the newly clarified detail (SC-005; depends on T012)

**Checkpoint**: All three user stories are independently functional — the elicitation flow, the no-op path, and the preservation guardrail all hold

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify scope boundaries, full placeholder replacement, and cross-cutting checks that span all user stories

- [X] T014 Read through the complete `commands/brief-clarify.md` and confirm the FR-010 scope boundary holds (no `Delivery Strategy` structure, no plan-phase or tasks-phase content, no feature-flag-provider/MCP interaction instructions appear anywhere in the file) and the FR-011 guardrail holds (no instruction to suppress or skip clarify's normal, non-rollout clarification questions) (depends on T002, T008, T010, T012)
- [X] T015 Confirm no feature-flag provider name appears anywhere in `commands/brief-clarify.md`, and confirm the original placeholder "Status: Placeholder" language (FR-012) has been fully replaced with no leftover placeholder text (FR-009; SC-004; depends on T014)
- [X] T016 Run the [quickstart.md](./quickstart.md) cross-cutting checks section and Scenario 4 (declining a specific question) against the finalized `commands/brief-clarify.md`, and delete any scratch fixture feature directories (e.g. `specs/999-quickstart-fixture/`) created during Scenarios 1-3 (depends on T009, T011, T013, T015)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (establishes the frontmatter, scope boundary, gate-invocation branching, and preservation guardrail every story's content is appended to)
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion, and — because every task edits the same single file in place — must be applied **sequentially in priority order** (US1 → US2 → US3) rather than in parallel, even though each story remains independently testable via its own quickstart scenario once its content is in place
- **Polish (Phase 6)**: Depends on all three user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — no dependencies on other stories
- **User Story 2 (P1)**: Textually depends on the Foundational branching being present first (T010 is placed immediately after the branch condition to avoid ambiguity about scope), but is independently testable via its own quickstart scenario
- **User Story 3 (P2)**: Builds on both US1's elicitation flow (T006) and Foundational's preservation instruction (T004) to define the sparse-marker guardrail

### Within Each User Story

- Doctrine content is written before its quickstart verification task
- Verification tasks depend on all content tasks in the same phase being complete
- Story complete before moving to the next priority (single-file sequencing, no parallel story work)

### Parallel Opportunities

- None across content-writing tasks — every task in Phases 2-5 edits the same file (`commands/brief-clarify.md`) and must be applied in sequence
- T001 (Setup, read-only research) has no file conflicts with any other task, but there is nothing else in Phase 1 to run it alongside

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md Scenario 1 independently
5. This alone makes the doctrine functional for the primary rollout-elicitation case (vision.md §4-5.1)

### Incremental Delivery

1. Complete Setup + Foundational → shared framing and branching ready
2. Add User Story 1 → validate with Scenario 1 → elicitation + refine-in-place works (MVP!)
3. Add User Story 2 → validate with Scenario 2 → confirms no over-triggering
4. Add User Story 3 → validate with Scenario 3 → sparse-marker preservation guardrail holds
5. Complete Phase 6 Polish → confirm scope boundaries, full placeholder replacement, and Scenario 4 decline path

---

## Notes

- All tasks operate on the single file `commands/brief-clarify.md` — sequencing (not parallelism) is the operative constraint for this feature
- `[Story]` label maps task to specific user story for traceability, per spec.md priorities
- Each user story's quickstart scenario is the "test" for this content-only feature — there is no automated test suite to write or run
- Commit after each phase (or logical group of tasks within a phase)
