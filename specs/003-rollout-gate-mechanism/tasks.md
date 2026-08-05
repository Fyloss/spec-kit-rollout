---

description: "Task list for the rollout gate mechanism"
---

# Tasks: Rollout Gate Mechanism

**Input**: Design documents from `/specs/003-rollout-gate-mechanism/`

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md), [quickstart.md](./quickstart.md)

**Tests**: No dedicated test framework is introduced (see plan.md Technical Context, consistent with 001/002 precedent). Verification instead uses the fixture-based manual/scripted checks from quickstart.md, wired into the relevant user-story phases below as explicit checkpoint tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All file paths are relative to the repository root, which **is** the `rollout` package root (per plan.md's Structure Decision, unchanged from 001-extension-skeleton and 002-config-system).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)

## Path Conventions

- **Single project (Spec Kit extension package)**: new `scripts/bash/rollout-gate.sh` and `scripts/powershell/rollout-gate.ps1` at the repository root, per plan.md Project Structure. No changes to `commands/*.md`, `extension.yml`, or `rollout-config.template.yml` (explicitly out of scope — see plan.md).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the two script files both implementations will be built up in

- [X] T001 Create `scripts/bash/` and `scripts/powershell/` directories at the repository root with stub files: `scripts/bash/rollout-gate.sh` (POSIX-shell shebang, executable bit set via `chmod +x`) and `scripts/powershell/rollout-gate.ps1` (header comment only), per plan.md Project Structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the shared skeleton every user story depends on — CLI argument parsing, feature-directory resolution, the fixed four-field output shape, and the exit-code scheme — before any marker or config logic exists

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] In `scripts/bash/rollout-gate.sh`: implement `--mode default|analyze` argument parsing (default `default`), feature-directory resolution (`SPECIFY_FEATURE_DIRECTORY` env var, else `.specify/feature.json`'s `feature_directory` key via `jq` → `python3` → `grep`/`sed` fallback, walking upward for `.specify/`), and the fixed four-line `hasFlags=`/`flags=`/`source=`/`hooksEnabled=` stdout skeleton with the exit-code scheme (`0`=rollout, `1`=no rollout, `2`=unresolved feature directory); when the feature directory cannot be resolved, print a diagnostic to stderr and emit `hasFlags=false`/exit `2` (fail-safe). Per [contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md) and research.md's "Feature-directory resolution" decision (FR-004, FR-010, spec.md edge case "feature directory cannot be resolved")
- [X] T003 [P] In `scripts/powershell/rollout-gate.ps1`: implement the equivalent `-Mode default|analyze` argument parsing, feature-directory resolution, four-line output skeleton, and exit-code scheme as T002, per [contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md) (mirrors T002 in PowerShell)

**Checkpoint**: Both scripts run standalone, resolve (or fail-safe on) a feature directory, and emit the skeleton four-field output with the correct exit code for the unresolved case — ready for marker and config logic

---

## Phase 3: User Story 1 - Skip rollout doctrine when no rollout intent exists (Priority: P1) 🎯 MVP

**Goal**: When a feature's `spec.md` has no `## Delivery Considerations` marker (or `spec.md` doesn't exist yet), the gate reports `hasFlags=false` and a "no rollout" exit code

**Independent Test**: Run the gate script directly against a feature directory whose `spec.md` has no marker and confirm `hasFlags=false` plus the "no rollout" exit code, with no other extension component present

### Implementation for User Story 1

- [X] T004 [P] [US1] In `scripts/bash/rollout-gate.sh`: implement default-mode marker search of the resolved feature's `spec.md` — search for the literal `## Delivery Considerations` heading line; when absent, or when `spec.md` does not exist, report `hasFlags=false`, `flags=`, `source=`, and exit `1` (FR-005, FR-009, FR-010; spec.md edge case "`spec.md` does not exist yet"; depends on T002)
- [X] T005 [P] [US1] In `scripts/powershell/rollout-gate.ps1`: implement the equivalent default-mode marker-absent detection as T004 (depends on T003)
- [X] T006 [US1] Run [quickstart.md](./quickstart.md) Step 1 (marker-absent fixture) against both scripts and confirm `hasFlags=false`/`flags=`/`source=`/exit `1` parity (SC-002; depends on T004, T005)

**Checkpoint**: User Story 1 is fully functional and independently testable — the common "no rollout intent" case produces the correct no-op signal

---

## Phase 4: User Story 2 - Surface rollout intent to later workflow phases (Priority: P1)

**Goal**: When a feature's `spec.md` has the `## Delivery Considerations` marker, the gate reports `hasFlags=true`, the candidate flag name(s), `source=spec.md`, and a "rollout" exit code — regardless of surrounding prose

**Independent Test**: Run the gate script directly against a feature directory whose `spec.md` contains the marker naming one or more candidate flags, and confirm `hasFlags=true` plus the exact candidate flag name(s)

### Implementation for User Story 2

- [X] T007 [P] [US2] In `scripts/bash/rollout-gate.sh`: implement detection of the literal `## Delivery Considerations` heading line (prose-agnostic — matches regardless of wording/punctuation beneath it) returning `hasFlags=true`, `source=spec.md`, exit `0` (FR-001, FR-002, FR-009, FR-010; depends on T004)
- [X] T008 [P] [US2] In `scripts/powershell/rollout-gate.ps1`: implement the equivalent heading detection as T007 (depends on T005)
- [X] T009 [P] [US2] In `scripts/bash/rollout-gate.sh`: implement extraction of the optional `Candidate flag(s): <name>[, <name>...]` line within the marker section into the `flags` field (comma-separated names; empty when the line is absent), per research.md's candidate-flag sub-convention decision (FR-009; depends on T007)
- [X] T010 [P] [US2] In `scripts/powershell/rollout-gate.ps1`: implement the equivalent candidate-flag extraction as T009 (depends on T008)
- [X] T011 [US2] Run [quickstart.md](./quickstart.md) Step 2 (marker-present fixture, including a prose/punctuation variation) against both scripts and confirm `hasFlags=true`, correct `flags`, `source=spec.md`, exit `0` parity (SC-001; depends on T009, T010)

**Checkpoint**: User Stories 1 AND 2 both work independently — the gate correctly distinguishes marker-absent from marker-present and carries candidate flag names forward

---

## Phase 5: User Story 3 - Team-level opt-out overrides any marker (Priority: P2)

**Goal**: When the resolved `hooks.enabled` configuration is `false`, the gate reports `hasFlags=false` even when a marker is present, identical to the no-marker case

**Independent Test**: With `hooks.enabled` set to `false`, run the gate script against a feature whose `spec.md` contains the marker and confirm the result matches the "no marker" case

### Implementation for User Story 3

- [X] T012 [P] [US3] In `scripts/bash/rollout-gate.sh`: implement the four-layer `hooks.enabled` resolution — extension defaults (`.specify/extensions/rollout/extension.yml`) → project config (`.specify/extensions/rollout/rollout-config.yml`) → local override (`.specify/extensions/rollout/local-config.yml`) → `SPECKIT_ROLLOUT_HOOKS_ENABLED` env var — where a missing/unreadable layer or an unrecognized env var value falls through to the next layer, defaulting to `true`, per research.md's "`hooks.enabled` resolution" decision and data-model.md's Hooks-Enabled Toggle entity (FR-007, FR-008; depends on T002)
- [X] T013 [P] [US3] In `scripts/powershell/rollout-gate.ps1`: implement the equivalent four-layer `hooks.enabled` resolution as T012 (depends on T003)
- [X] T014 [P] [US3] In `scripts/bash/rollout-gate.sh`: wire the resolved `hooks.enabled` value into the final output/exit-code decision so `hasFlags` is forced `false` (with `hooksEnabled=false` reported) whenever hooks are disabled, regardless of marker match (FR-007; depends on T007, T012)
- [X] T015 [P] [US3] In `scripts/powershell/rollout-gate.ps1`: wire the resolved `hooks.enabled` value into the final output/exit-code decision, equivalent to T014 (depends on T008, T013)
- [X] T016 [US3] Run [quickstart.md](./quickstart.md) Step 3 (hooks-disabled override fixture) against both scripts and confirm `hasFlags=false`/`hooksEnabled=false`/exit `1` parity even though the marker is present (SC-003; depends on T014, T015)

**Checkpoint**: User Stories 1, 2, AND 3 all work independently — the team-level toggle deterministically overrides marker content

---

## Phase 6: User Story 4 - Consistent behavior across chained artifacts for analyze (Priority: P3)

**Goal**: In `--mode analyze` / `-Mode analyze`, the gate additionally searches `plan.md` and `tasks.md` (after `spec.md`) for the marker; default mode remains `spec.md`-only

**Independent Test**: Run the gate script in analyze mode against a feature directory where `spec.md` has no marker but `plan.md` does, and confirm `hasFlags=true` with `source=plan.md`, separate from a default-mode invocation on the same fixture

### Implementation for User Story 4

- [X] T017 [P] [US4] In `scripts/bash/rollout-gate.sh`: implement the `--mode analyze` search order — `spec.md`, then `plan.md`, then `tasks.md`, first match wins and sets `source` accordingly — leaving default mode unaffected (FR-006; depends on T007, T009)
- [X] T018 [P] [US4] In `scripts/powershell/rollout-gate.ps1`: implement the equivalent `-Mode analyze` search order as T017 (depends on T008, T010)
- [X] T019 [US4] Run [quickstart.md](./quickstart.md) Step 4 (`plan.md`-only fixture) against both scripts in analyze mode and confirm `hasFlags=true`/`source=plan.md`/exit `0`, and confirm default mode on the same fixture still reports `hasFlags=false` (depends on T017, T018)

**Checkpoint**: All four user stories are independently functional — the full self-gating contract is implemented in both scripts

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verify the remaining edge case and cross-implementation guarantees that span all user stories, and finalize script hygiene

- [X] T020 Run [quickstart.md](./quickstart.md) Step 5 (unresolved feature-directory fixture) against both scripts and confirm `hasFlags=false`/exit `2` parity (depends on T002, T003)
- [X] T021 Run [quickstart.md](./quickstart.md) Step 6 (full cross-platform parity pass across all Step 1-4 fixtures) against both scripts and confirm every output field and exit code matches, per [contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md)'s cross-implementation equivalence requirement (FR-013, SC-004; depends on T006, T011, T016, T019)
- [X] T022 Run [quickstart.md](./quickstart.md) Step 7 (two concurrently existing fixture feature directories with different marker states) against both scripts and confirm each gate result reflects only its own `SPECIFY_FEATURE_DIRECTORY` target, with no cross-feature leakage (SC-006; depends on T006, T011)
- [X] T023 [P] Finalize header/usage comments in `scripts/bash/rollout-gate.sh` and `scripts/powershell/rollout-gate.ps1` (invocation syntax, output fields, exit codes) cross-checked against [contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md), and confirm the bash script's executable bit and shebang are correct
- [X] T024 Clean up quickstart fixture artifacts (`specs/999-gate-fixture-*` directories, `.specify/extensions/rollout/rollout-config.yml`) created during T006-T022 verification, per quickstart.md's Cleanup section (depends on T021, T022)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (T004-T006) has no dependency on Stories 2-4
  - User Story 2 (T007-T011) builds on User Story 1's marker-search groundwork (T004/T005) within the same two files, but is independently testable once its own tasks are done
  - User Story 3 (T012-T016) depends on Foundational directly for the config-resolution tasks (T012/T013), and on User Story 2's true-path tasks (T007/T008) for the override-wiring tasks (T014/T015)
  - User Story 4 (T017-T019) depends on User Story 2's heading-detection and flag-extraction tasks (T007/T009, T008/T010) to extend the search order
- **Polish (Phase 7)**: Depends on all four user stories being complete

### Within Each User Story

- The bash task and the PowerShell task for the same logical behavior are marked `[P]` (different files) but each depends on its own script's prior task in an earlier phase
- Each story's quickstart-verification task depends on that story's implementation tasks in both scripts
- Story complete before moving to the next priority, per the checkpoints above

### Parallel Opportunities

- T002 and T003 (Foundational) can run in parallel — different files
- Within each user story, the bash-script task and PowerShell-script task for the same behavior (e.g., T004/T005, T007/T008, T009/T010, T012/T013, T014/T015, T017/T018) can run in parallel — different files
- T023 (script hygiene) can run in parallel with T020/T021/T022 (verification) since it touches comments only, not the logic under test

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md Step 1 independently — confirm both scripts correctly report `hasFlags=false` for a marker-absent feature
5. This alone delivers the extension's core promise (near-zero overhead when no rollout intent exists) even before marker-present detection exists

### Incremental Delivery

1. Setup + Foundational → both scripts run and fail-safe correctly
2. Add User Story 1 → validate independently → "no rollout" case works (deployable as-is: every hook would see `hasFlags=false` until markers exist)
3. Add User Story 2 → validate independently → marker detection + flag extraction complete (the two P1 stories together form the full base contract)
4. Add User Story 3 → validate independently → team opt-out override works
5. Add User Story 4 → validate independently → `analyze` mode extends the search
6. Run Phase 7 polish to confirm full cross-platform parity and clean up fixtures
