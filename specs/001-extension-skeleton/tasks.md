---

description: "Task list for building the rollout extension skeleton"
---

# Tasks: Rollout Extension Skeleton

**Input**: Design documents from `/specs/001-extension-skeleton/`

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/extension-manifest.md](./contracts/extension-manifest.md), [quickstart.md](./quickstart.md)

**Tests**: No dedicated test framework is introduced (see plan.md Technical Context). Verification instead uses the real `specify` CLI flows and the naming/reference lint from quickstart.md, wired into the relevant user-story phases below.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All file paths are relative to the repository root, which **is** the `rollout` package root (per plan.md's Structure Decision).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

## Path Conventions

- **Single project (Spec Kit extension package)**: package files at repository root — `extension.yml`, `README.md`, `LICENSE`, `CHANGELOG.md`, `.extensionignore`, `commands/`, `rollout-config.template.yml` — per plan.md Project Structure.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Package scaffolding and root packaging files that don't depend on manifest content

- [x] T001 Create the `commands/` directory at the repository root per the layout in [plan.md](./plan.md)
- [x] T002 [P] Create README.md at the repository root with a package overview (name, purpose, install instructions) per FR-011
- [x] T003 [P] Create LICENSE at the repository root with the MIT license text per FR-012
- [x] T004 [P] Create CHANGELOG.md at the repository root recording the initial `1.0.0` release per FR-013
- [x] T005 [P] Create .extensionignore at the repository root excluding `.git/`, `.specify/`, `specs/`, `tests/`, `docs/`, and `.github/` (gitignore-pattern syntax) per FR-014 — `.specify/` exclusion is load-bearing: without it, installing from the repo root self-nests the destination (discovered in T020, see research.md)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core manifest skeleton and placeholder files that MUST exist before any of the three user-story acceptance flows can be exercised

**⚠️ CRITICAL**: No user story verification can begin until this phase is complete

- [x] T006 Create extension.yml at the repository root with `schema_version: "1.0"` and the `extension` metadata block (`id: rollout`, `name`, `version: 1.0.0`, `description`, `author`, `repository`, `license: MIT`, `homepage`, `category`, `effect`) per FR-001, FR-002
- [x] T007 Add the `requires.speckit_version` compatibility range (`">=0.12.0"`) to extension.yml per FR-003 (depends on T006)
- [x] T008 [P] Create rollout-config.template.yml at the repository root with placeholder non-secret pointer fields per FR-010
- [x] T009 Add the `provides.config` entry (`id: rollout-config`, `file: rollout-config.yml`, `template: rollout-config.template.yml`, `required: false`) and top-level `config.defaults` / `config.config_schema` placeholder blocks to extension.yml per FR-009, FR-010 (depends on T007, T008)
- [x] T010 [P] Create placeholder command file commands/brief-specify.md per FR-006
- [x] T011 [P] Create placeholder command file commands/brief-clarify.md per FR-006
- [x] T012 [P] Create placeholder command file commands/brief-plan.md per FR-006
- [x] T013 [P] Create placeholder command file commands/brief-tasks.md per FR-006
- [x] T014 [P] Create placeholder command file commands/brief-analyze.md per FR-006
- [x] T015 [P] Create placeholder command file commands/brief-checklist.md per FR-006
- [x] T016 [P] Create placeholder command file commands/brief-implement.md per FR-006
- [x] T017 [P] Create placeholder command file commands/connect.md per FR-006

**Checkpoint**: Manifest skeleton, config template, and all 8 placeholder command files exist — user story work can now begin

---

## Phase 3: User Story 1 - Install the extension into a Spec Kit project (Priority: P1) 🎯 MVP

**Goal**: `rollout` installs via `specify extension add --dev` with zero validation errors

**Independent Test**: Run the extension installation command against this package and confirm it completes with no validation errors

### Implementation for User Story 1

- [x] T018 [US1] Add the `provides.commands` block to extension.yml with all 8 entries (`name`, `file`, `description`) for `speckit.rollout.brief-specify`, `speckit.rollout.brief-clarify`, `speckit.rollout.brief-plan`, `speckit.rollout.brief-tasks`, `speckit.rollout.brief-analyze`, `speckit.rollout.brief-checklist`, `speckit.rollout.brief-implement`, and `speckit.rollout.connect`, each referencing its file under commands/ per FR-004, FR-005 (depends on T009, T010-T017)
- [x] T019 [US1] Add the top-level `hooks` block to extension.yml with all 7 `before_*` entries (`before_specify`, `before_clarify`, `before_plan`, `before_tasks`, `before_analyze`, `before_checklist`, `before_implement`), each `{command: speckit.rollout.brief-<phase>, optional: false}` per FR-007, FR-008 (depends on T018)
- [x] T020 [US1] Run `specify extension add . --dev` per [quickstart.md](./quickstart.md) step 1 and confirm the install completes with zero validation errors per FR-015, SC-001 (depends on T019)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently — the package installs cleanly

---

## Phase 4: User Story 2 - Confirm the extension is fully and correctly registered (Priority: P2)

**Goal**: `specify extension list` shows `rollout` as enabled with exactly 8 commands and 7 hooks, and every command name matches the required pattern

**Independent Test**: After installation, list installed extensions and inspect the entry for `rollout` independent of any other extension behavior

### Implementation for User Story 2

- [x] T021 [US2] Run `specify extension list` per [quickstart.md](./quickstart.md) step 2 and confirm the `rollout` entry shows `Commands: 8 | Hooks: 7 | Status: Enabled` per FR-016, SC-002 (depends on T020)
- [x] T022 [US2] Run the naming/reference lint script from [quickstart.md](./quickstart.md) step 2 confirming all 8 command names match `^speckit\.rollout\.[a-z0-9-]+$`, all 7 hooks have `optional: false`, and every referenced command/template file exists per FR-018, FR-019, SC-003, SC-004 (depends on T020)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently — registration is confirmed complete and correctly named

---

## Phase 5: User Story 3 - Cleanly remove the extension (Priority: P3)

**Goal**: `rollout` can be removed via `specify extension remove` leaving no orphaned commands, hooks, or config

**Independent Test**: With `rollout` installed, run the removal command and confirm no `rollout`-related commands, hooks, or config remain registered

### Implementation for User Story 3

- [x] T023 [US3] Run `specify extension remove rollout` per [quickstart.md](./quickstart.md) step 3 and confirm the removal completes without errors per FR-017 (depends on T020)
- [x] T024 [US3] Run `specify extension list` again and confirm `rollout` no longer appears and no `speckit.rollout.*` commands or `before_*` hooks remain registered per SC-005 (depends on T023)

**Checkpoint**: All three user stories should now be independently verified — install, registration, and removal all behave correctly

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency pass across the whole package

- [x] T025 [P] Reconcile README.md content with the final extension.yml (accurate command/hook list) in README.md
- [x] T026 Re-run the complete [quickstart.md](./quickstart.md) validation sequence end-to-end (install → list + lint → remove) as a final regression check (depends on T022, T024)
- [x] T027 [P] Verify CHANGELOG.md, LICENSE, and .extensionignore content fully satisfy FR-011–FR-014

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T001 creates the `commands/` directory used by T010-T017) - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (install) must complete before User Story 2 (registration) and User Story 3 (removal), since both verify state produced by the T020 install
  - User Story 2 and User Story 3 are independent of each other and can proceed in parallel once User Story 1's install (T020) has run
- **Polish (Phase 6)**: Depends on User Story 2 (T022) and User Story 3 (T024) both being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - no dependency on other stories
- **User Story 2 (P2)**: Depends on User Story 1's install (T020) having been run against the finished manifest - not independently buildable, but independently testable/verifiable
- **User Story 3 (P3)**: Depends on User Story 1's install (T020) having been run - not independently buildable, but independently testable/verifiable

### Within Each User Story

- Manifest content additions (commands, then hooks) before running the install
- Install (T020) before any registration or removal verification

### Parallel Opportunities

- Setup tasks T002-T005 can run in parallel (different files)
- Foundational tasks T008 and T010-T017 can run in parallel (different files); T006-T007, T009 are sequential edits to the same extension.yml
- Once User Story 1's install (T020) completes, User Story 2 (T021-T022) and User Story 3 (T023-T024) can proceed in parallel
- T025 and T027 in Polish can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch all placeholder command file creations together:
Task: "Create placeholder command file commands/brief-specify.md"
Task: "Create placeholder command file commands/brief-clarify.md"
Task: "Create placeholder command file commands/brief-plan.md"
Task: "Create placeholder command file commands/brief-tasks.md"
Task: "Create placeholder command file commands/brief-analyze.md"
Task: "Create placeholder command file commands/brief-checklist.md"
Task: "Create placeholder command file commands/brief-implement.md"
Task: "Create placeholder command file commands/connect.md"

# Launch the config template alongside them:
Task: "Create rollout-config.template.yml placeholder"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 - the package installs cleanly
4. **STOP and VALIDATE**: Confirm zero validation errors on install
5. This is the MVP: an installable, valid `rollout` package skeleton

### Incremental Delivery

1. Complete Setup + Foundational → manifest skeleton and placeholder files ready
2. Add User Story 1 → install cleanly → **MVP**
3. Add User Story 2 → confirm registration is complete and correctly named
4. Add User Story 3 → confirm clean removal
5. Polish → reconcile docs and re-run full validation

### Parallel Team Strategy

With multiple contributors:

1. One contributor completes Setup + Foundational
2. Once Foundational is done, User Story 1 (T018-T020) must go first (it produces the installed state)
3. Once T020 completes, a second contributor can take User Story 2 while a third takes User Story 3, in parallel

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All command/hook content in this feature is placeholder-only, per the input's explicit scope boundary — no doctrine, gate scripts, real config values, or MCP wiring belongs in any task above
- Commit after each task or logical group
