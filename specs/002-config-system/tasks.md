---

description: "Task list for building the rollout configuration system"
---

# Tasks: Rollout Configuration System

**Input**: Design documents from `/specs/002-config-system/`

**Prerequisites**: [plan.md](./plan.md) (required), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/rollout-config-schema.md](./contracts/rollout-config-schema.md), [quickstart.md](./quickstart.md)

**Tests**: No dedicated test framework is introduced (see plan.md Technical Context). Verification instead uses the real installed `ConfigManager` class and the checks from quickstart.md, wired into the relevant user-story phases below.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. All file paths are relative to the repository root, which **is** the `rollout` package root (per plan.md's Structure Decision, unchanged from 001-extension-skeleton).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

## Path Conventions

- **Single project (Spec Kit extension package)**: package files at repository root — `rollout-config.template.yml`, `extension.yml`, `README.md` — per plan.md Project Structure. Resolved runtime config lives under `.specify/extensions/rollout/` (not part of this repository's tracked source; used here only as a local verification scratch area).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure a clean local verification environment before editing the schema

- [X] T001 Ensure no stale `.specify/extensions/rollout/` directory exists from a previous manual install/test run, so Foundational and User Story verification below start from a known-clean state (repository root)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migrate the config schema in both files every user story depends on — the shipped template (what a human copies) and the manifest defaults (what `ConfigManager` actually reads as layer 1)

**⚠️ CRITICAL**: No user story verification can begin until this phase is complete

- [X] T002 Migrate rollout-config.template.yml at the repository root from the flat 001 placeholder shape (`project_key`, `environments`, `hooks_enabled`) to the nested schema: top-level `provider: launchdarkly`, `launchdarkly.project_key`, `launchdarkly.environments`, `mcp.{command,args,version,repository,token_env_var}`, `hooks.enabled` (default `true`) per FR-001, FR-002, FR-003, FR-004, FR-005 and data-model.md's Configuration Template / contracts/rollout-config-schema.md
- [X] T003 Add the three required inline warning comments to rollout-config.template.yml per FR-006: (a) secret values must never be committed to this file; (b) the token is consumed only by the MCP server process; (c) the agent must never read or echo the token value (depends on T002)
- [X] T004 Update extension.yml's top-level `config.defaults` block at the repository root to the nested shape (`provider: launchdarkly`, `hooks: {enabled: true}`) matching the migrated template, since `ConfigManager._get_extension_defaults()` reads this file as the installed layer-1 defaults per research.md (depends on T002)
- [X] T005 Update extension.yml's `config.config_schema` placeholder block at the repository root to describe the nested schema shape (`provider`, `launchdarkly`, `mcp`, `hooks.enabled`) for documentation parity with the template (depends on T004)

**Checkpoint**: Full nested schema exists in both the shipped template and the manifest defaults — user story verification can now begin

---

## Phase 3: User Story 1 - Adopt the extension with a working, secret-free config (Priority: P1) 🎯 MVP

**Goal**: Copying the shipped template to the resolved project configuration location, with no edits, produces a valid, secret-free config

**Independent Test**: Copy the shipped template to the resolved project configuration location, without editing any values, and confirm the result is complete, valid, and contains no secret material or unresolved placeholders

### Implementation for User Story 1

- [X] T006 [US1] In the scratch `.specify/extensions/rollout/` directory, copy only extension.yml (no project or local config file present) and confirm `ConfigManager(Path("."), "rollout").get_config()` resolves the defaults layer with no error, verifying the FR-012 edge case (resolved project configuration file absent → fall back to extension defaults, not a failure) *before* any project config exists (depends on T004)
- [X] T007 [US1] Run quickstart.md step 1 (YAML-parse + secret-free sanity check) against the migrated rollout-config.template.yml and confirm it passes per FR-010, SC-002; additionally set `provider` to a non-`launchdarkly` value (e.g. `unleash`) in a throwaway copy and confirm `yaml.safe_load` + `ConfigManager.get_config()` still succeed with no parse/validation error, verifying the spec.md edge case that an unrecognized provider value is not fatal (depends on T003)
- [X] T008 [US1] Run quickstart.md step 2: copy rollout-config.template.yml (as rollout-config.yml) alongside extension.yml into the scratch `.specify/extensions/rollout/` directory from T006 (simulating install), then confirm `ConfigManager(Path("."), "rollout").get_config()` resolves successfully with defaults + project layers merged and no error, per FR-008, FR-012, SC-001 (depends on T006, T007)
- [X] T009 [US1] Inspect the resolved config from T008 field-by-field and confirm every value is a non-secret placeholder (no credential/token value anywhere) and that the three FR-006 comments are present and correctly worded in the copied file, satisfying User Story 1's acceptance scenarios 2 and 3 (depends on T008)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently — the template copies to a valid, secret-free, resolvable config

---

## Phase 4: User Story 2 - Disable rollout behavior for a team that opts out (Priority: P2)

**Goal**: Setting the `hooks.enabled` toggle to `false` in the project config resolves as disabled, and a local override that doesn't touch the toggle does not silently revert it

**Independent Test**: With a resolved configuration present, set the hooks toggle to disabled and confirm the resolved value read by any consumer is "disabled," with no other configuration values affected

### Implementation for User Story 2

- [X] T010 [US2] Run quickstart.md step 3: edit the scratch `.specify/extensions/rollout/rollout-config.yml`'s `hooks.enabled` to `false` and confirm `ConfigManager(Path("."), "rollout").get_config()` resolves `hooks.enabled` as `False` per FR-005, FR-011, SC-003 (depends on T008)
- [X] T011 [US2] Create a scratch `.specify/extensions/rollout/local-config.yml` that sets an unrelated field (not `hooks.enabled`) and confirm the resolved `hooks.enabled` value remains `False` — not silently reverted — per User Story 2's acceptance scenario 2 (depends on T010)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently — the toggle disables cleanly and survives an unrelated local override

---

## Phase 5: User Story 3 - Override configuration locally without risking a commit (Priority: P3)

**Goal**: A local override file changes exactly one field in the resolved config, leaves every other field matching the project config, and is excluded from version control by default

**Independent Test**: Create a local override file with a different value for one field, confirm the resolved configuration reflects the override for that field while all other fields still come from the committed project configuration, and confirm the override file is excluded from version control by default

### Implementation for User Story 3

- [X] T012 [US3] Extend quickstart.md step 4: set `launchdarkly.project_key` in the scratch `.specify/extensions/rollout/local-config.yml` (from T011) to a value different from the project config, and confirm `ConfigManager(Path("."), "rollout").get_config()` reflects the override for `launchdarkly.project_key` only while `hooks.enabled` (from T010) and every other field still match the project config, per FR-007, SC-004 (depends on T011)
- [X] T013 [US3] Run `git check-ignore .specify/extensions/rollout/local-config.yml` and confirm it reports the file as ignored in this repository (via the existing blanket `.specify/extensions/` rule); add the adoption guidance comment to rollout-config.template.yml documenting that other projects must add their own equivalent `.gitignore` rule for `local-config.yml`, since Spec Kit does not manage this automatically, per FR-009, SC-005 (depends on T012)

**Checkpoint**: All three user stories should now be independently verified — adoption, team-level disable, and personal override all behave correctly

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation consistency and a final end-to-end regression pass

- [X] T014 [P] Add a "Configuration" section to README.md documenting the four-layer resolution order (extension defaults → project config → local override → `SPECKIT_ROLLOUT_*` env vars), the resolved project (`.specify/extensions/rollout/rollout-config.yml`) and local override (`.specify/extensions/rollout/local-config.yml`) paths, and the adopting project's own `.gitignore` responsibility for the local override file; visually confirm this new section contains no secret/credential values, per FR-013
- [X] T015 [P] Update README.md's "Status" section to note the configuration system (this feature) is delivered alongside the extension skeleton from 001, and that real doctrine/gate scripts consuming this config remain a later feature
- [X] T016 Re-run quickstart.md steps 1-5 end-to-end (including the `SPECKIT_ROLLOUT_HOOKS_ENABLED` env-var precedence check in step 5, confirming it resolves as the raw string `"true"` and wins over the project config) as a final regression check per FR-007; additionally, as an isolated local-override-vs-env-var check for SC-005, temporarily set `hooks.enabled: false` in the scratch `local-config.yml` and re-run with `SPECKIT_ROLLOUT_HOOKS_ENABLED=true`, confirming the env var still wins over the local override (not just over the project config), then revert `local-config.yml`'s `hooks.enabled` back to only setting `launchdarkly.project_key` (depends on T013, T014)
- [X] T017 Clean up the scratch `.specify/extensions/rollout/` directory created for local verification in T006-T016 (depends on T016)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories (all three stories need the migrated schema in both files)
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1's scratch install (T006, T008) is reused as the shared verification fixture for User Story 2 (T010) and, transitively, User Story 3 (T012) — so US1 must run first, but US2 and US3 are otherwise independent of each other
- **Polish (Phase 6)**: Depends on all three user stories being complete (T013, plus T014/T015 which can run anytime after Foundational)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - no dependency on other stories
- **User Story 2 (P2)**: Depends on User Story 1's scratch install (T008) as its verification fixture - not independently buildable, but independently testable/verifiable
- **User Story 3 (P3)**: Depends on User Story 2's local-config.yml (T011) as its verification fixture - not independently buildable, but independently testable/verifiable

### Within Each User Story

- Schema/comment edits (Foundational) before any resolution check
- The missing-project-file check (T006) before the project config is copied (T008) — order matters, since T008 introduces the very file T006 confirms is safely absent
- Install/copy into the scratch directory before any `get_config()` assertion
- Project-config edits before local-override edits before env-var checks (layering order, low → high precedence)

### Parallel Opportunities

- T014 and T015 in Polish can run in parallel (different sections of the same file only if edited independently — otherwise treat as sequential edits to README.md)
- No Setup or Foundational tasks are marked [P]: T002/T003 are sequential edits to rollout-config.template.yml, and T004/T005 are sequential edits to extension.yml
- Within each user story, tasks are sequential (each verification step depends on the previous layer being in place)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 - template copies to a valid, secret-free, resolvable config
4. **STOP and VALIDATE**: Confirm T006-T009 all pass
5. This is the MVP: a fully-specified, adoptable configuration schema

### Incremental Delivery

1. Complete Setup + Foundational → nested schema migrated in both files
2. Add User Story 1 → adoption produces a valid, secret-free config → **MVP**
3. Add User Story 2 → confirm the team-level kill switch works and survives unrelated local overrides
4. Add User Story 3 → confirm per-developer overrides are scoped and gitignored
5. Polish → document layering in README.md and re-run full regression

### Parallel Team Strategy

With multiple contributors:

1. One contributor completes Setup + Foundational (schema migration)
2. Once Foundational is done, User Story 1 (T006-T009) must go first (it produces the shared scratch-install fixture)
3. User Story 2 (T010-T011) and User Story 3 (T012-T013) build on that fixture sequentially, since US3's fixture (T011's local-config.yml) is created by US2

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- No new test framework or `tests/` directory is introduced per plan.md's Technical Context — verification uses the real installed `ConfigManager` class directly, per research.md's decision to avoid re-implementing (and risking drift from) the actual loader
- The scratch `.specify/extensions/rollout/` directory used throughout Phases 3-6 is local verification state only, not a deliverable of this feature (cleaned up in T017)
- T006, T007's provider-pluggability check, T014's secret-free README check, and T016's isolated local-vs-env check were added during `/speckit.analyze` remediation to close coverage gaps against FR-012, the unimplemented-provider edge case, FR-013, and SC-005's "any two layers" wording respectively

