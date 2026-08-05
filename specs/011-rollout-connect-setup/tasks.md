---
description: "Task list for implementing the Rollout Connect Setup Command"
---

# Tasks: Rollout Connect Setup Command

**Input**: Design documents from `/specs/011-rollout-connect-setup/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/connect-adapter-mapping.md

**Deliverable**: Complete rewrite of `commands/connect.md` with YAML frontmatter and Markdown doctrine body that implements all three user stories and satisfies all 11 functional requirements (FR-001 through FR-011).

**Tests**: Manual/scripted verification per quickstart.md is REQUIRED for this feature — no automated test framework (consistent with Constitution Principle V). All 8 scenarios plus 4 cross-cutting checks must pass.

**Organization**: Tasks are grouped by user story to enable independent authoring and testing of each story's dialect/control flow.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Independently authorable content — different logical sections with
  no content dependencies. **Note**: because this feature's sole deliverable
  is a single file (`commands/connect.md`), `[P]` here does NOT mean
  "safe to edit concurrently in separate file-system operations" (the
  tasks-template.md sense). It means each marked task's *content* can be
  drafted/reasoned about independently of the others; the sections must
  still be merged into `commands/connect.md` one at a time (sequentially) by
  whichever agent performs the authoring, to avoid clobbering another
  section's edits.
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Implementation Strategy

This feature is content-only: the deliverable is Markdown doctrine text in `commands/connect.md`, not application code. Tasks progress through authoring distinct sections of that file, sequenced so foundational content (detection, adapter mapping, error handling, non-action guarantees) is authored first, followed by the three story-specific control flows, concluding with validation against quickstart.md's eight scenarios.

---

## Phase 1: Setup (Command File Skeleton)

**Purpose**: Initialize the command file structure and YAML frontmatter

- [X] T001 Create `commands/connect.md` with YAML frontmatter (title, description, visibility, mode) following the established format from `brief-specify.md` through `brief-implement.md`

---

## Phase 2: Foundational (Detection & Adapter Infrastructure)

**Purpose**: Core infrastructure that ALL three user stories depend on — must be complete before story-specific content authoring begins

**⚠️ CRITICAL**: User Story 1, 2, and 3 content cannot be written until Phase 2 is complete.

- [X] T002 Author the "Client Detection" section of `commands/connect.md` doctrine: (1) read `.specify/integration.json`'s `integration` field; (2) handle missing/malformed file by reporting detection failure and falling back to copy-paste path (FR-001, spec.md Edge Case — Detection failure)
- [X] T003 Author the "Client Integration Adapter Mapping" section of `commands/connect.md`: construct a lookup table (data structure/pseudocode in Markdown) that associates each known integration key (copilot, claude, cursor_agent, cline, codex, gemini, windsurf) with its `mcp_config_path`, `format`, `server_map_key`, `supports_project_scope`, `env_var_reference_syntax`, and `fallback_reason` per research.md Decision 3 and data-model.md — designed so a new client is one added row, no control-flow change (FR-002)
- [X] T004 Author the "Resolve Pinned MCP Server Reference" section of `commands/connect.md` doctrine: read the project's rollout configuration (Feature 002) and extract `mcp.command`, `mcp.args`, `mcp.version`, `mcp.repository`, `mcp.token_env_var` — with explicit empty-pin guard: if `command` is empty/missing, report "pin not yet configured" and stop (FR-011, spec.md Edge Case — Empty/unconfigured pin)
- [X] T005 Author the "Common Error Handling & Validation" section of `commands/connect.md`: (1) malformed JSON/TOML parse failures → stop, report problem, fall back to snippet (FR-010); (2) detection failure → report and fall back (already noted in T002); (3) empty pin → report and stop (already noted in T004); (4) general structure for consistent error reporting throughout all paths
- [X] T006 Author the "Non-Action Guarantees" section of `commands/connect.md` doctrine, applying to every control-flow path (detection, write, fallback): the command MUST NEVER launch, connect to, or otherwise start the MCP server process; MUST NEVER prompt the developer for a token value; MUST NEVER read a token value from the environment, a file, or any other source; and MUST NEVER store, echo, or forward a token value anywhere — only the token env-var's *name* is ever referenced (FR-009)

**Checkpoint**: Foundation ready — all three user story control flows can now be authored independently on top of these shared sections.

---

## Phase 3: User Story 1 — One-time MCP setup for a supported client (Priority: P1) 🎯 MVP

**Goal**: Detect a supported client integration and write its MCP configuration file with the pinned LaunchDarkly MCP server entry, referencing the token only by environment-variable name.

**Independent Test**: In a project using a mapped client integration (e.g. `cursor_agent`) with no prior LaunchDarkly MCP entry, run `/speckit.rollout.connect` and confirm:
1. The client's MCP configuration file is created/updated at the correct path (`.cursor/mcp.json`).
2. A `launchdarkly` entry exists under the correct `server_map_key` (`mcpServers`).
3. The entry contains `command`, `args`, and the token env-var name (e.g. `${env:VAR_NAME}`) — no token value.
4. All pre-existing unrelated server entries remain unchanged.
5. The command reports the file written and the detected client.

### Implementation for User Story 1

- [X] T007 [P] [US1] Author the "Supported Client Write Path" section of `commands/connect.md` doctrine: describe the algorithm to (1) detect the client via T002; (2) look up the client in the adapter mapping via T003; (3) check if `supports_project_scope` is true; (4) if no, branch to US2 (fallback path — T011); (5) if yes, proceed to write path (T008)
- [X] T008 [P] [US1] Author the "Write/Update MCP Configuration File" section of `commands/connect.md` doctrine: for each supported format (JSON for copilot/claude/cursor_agent/gemini, TOML for codex), instruct the agent to (1) read the existing file if present, parse it, handle errors via T005; (2) create the `server_map_key` and/or file if missing; (3) construct a `launchdarkly` server entry using the pinned spec (T004) and the adapter's `env_var_reference_syntax` (T003) — for JSON, place the token env-var name in an `env` object; for Codex TOML, use `env_vars` array; (4) write the entry under `server_map_key`, preserving all other keys byte-for-byte (FR-003, FR-005, FR-006)
- [X] T009 [P] [US1] Author the "Idempotent Update Logic" section of `commands/connect.md` doctrine: on re-run, locate the existing `launchdarkly` entry by name, compare its body to the freshly resolved pinned spec, update in place if drifted, never create a second entry (FR-005 — convergence to exactly one entry across multiple runs)
- [X] T010 [US1] Author the "Reporting for Write Path" section of `commands/connect.md` doctrine: after file write succeeds, report "Detected client: [integration_key]. Configuration file written: [mcp_config_path]" or "...updated" if an existing entry was refreshed (FR-008)

---

## Phase 4: User Story 2 — Copy-paste fallback for an unmapped or config-less client (Priority: P2)

**Goal**: For clients absent from the adapter mapping or lacking project-scoped MCP configuration, print a ready-to-paste MCP server snippet and an environment-variable reminder instead of writing any file.

**Independent Test**: In a project using an unmapped integration (e.g. `windsurf`) or a no-project-scope integration (e.g. `cline`), run `/speckit.rollout.connect` and confirm:
1. No file on disk is created or modified.
2. The output contains a complete, correctly formatted MCP server snippet (JSON shape for Cline even though no file exists to write it to; generic JSON for unmapped clients).
3. The exact `mcp.token_env_var` name is printed with a one-line reminder to set it as an OS environment variable.
4. No token value appears anywhere in the output.
5. The command reports the detected client and the fallback reason.

### Implementation for User Story 2

- [X] T011 [P] [US2] Author the "Unmapped / No-Project-Scope Fallback Path" section of `commands/connect.md` doctrine: if the adapter lookup finds no row, or finds a row with `supports_project_scope = false`, branch here instead of T008 (FR-007)
- [X] T012 [P] [US2] Author the "Generate Copy-Paste Snippet" section of `commands/connect.md` doctrine: for each format (JSON for Cline even though no file exists; generic JSON for entirely unmapped clients; TOML illustration for Codex if an unmapped Codex variant ever exists), construct a complete example server entry containing `command`, `args`, and an illustrative env-var-name reference (using the adapter's `env_var_reference_syntax` if available, or generic `${VAR_NAME}` otherwise) — never a token value (FR-004 applies to output as well as files)
- [X] T013 [P] [US2] Author the "Environment Variable Reminder" section of `commands/connect.md` doctrine: print the exact name of `mcp.token_env_var` and instruct the developer to set it as an OS environment variable (e.g. "export LAUNCHDARKLY_API_KEY=...")
- [X] T014 [US2] Author the "Reporting for Fallback Path" section of `commands/connect.md` doctrine: after snippet/reminder is printed, report "Detected client: [integration_key]. Configuration not supported in project scope (or: client not in adapter mapping). Snippet printed above — copy the server entry and set the environment variable manually." (FR-008, distinguishing the two fallback triggers per research.md Decision 3)

---

## Phase 5: User Story 3 — Idempotent re-run preserves existing configuration (Priority: P1)

**Goal**: Ensure that re-running `/speckit.rollout.connect` against the same client is safe and idempotent — existing entries are preserved or updated to match the current pin, never duplicated or corrupted.

**Independent Test**: Run `/speckit.rollout.connect` twice in succession against the same mapped client (e.g. Cursor) and confirm:
1. The client's MCP configuration file contains exactly one `launchdarkly` entry after both runs.
2. All pre-existing unrelated server entries are unchanged after the second run.
3. If the pinned spec has drifted between runs (e.g. simulated by hand-editing the command or args), the entry is updated to match the current pin on the second run.
4. No duplicate entries, no partially written files, no file corruption.

### Implementation for User Story 3

**NOTE**: The idempotency logic (detection of existing entry by name, in-place replacement, no duplicate creation) is already embedded in T009 (Idempotent Update Logic). This phase adds explicit guidance and validation:

- [X] T015 [US3] Author the "Idempotency Validation" section of `commands/connect.md` doctrine: before writing the file, verify that if a `launchdarkly` entry already exists, the new entry's body is different from the old one; if identical, report no change needed and skip the file write (optimization for repeated runs with no pin drift); if different, proceed with in-place update (FR-005)
- [X] T016 [US3] Author the "Drift Detection & Correction" section of `commands/connect.md` doctrine: on re-run, compare the existing `launchdarkly` entry's `command`, `args`, and `env`/`env_vars` fields to the freshly resolved `mcp.command`, `mcp.args`, and token env-var reference; if any field has drifted, report the drift and update in place; if all match, report no change; never create a second entry (FR-005 — convergence behavior)
- [X] T017 [US3] Author the "Reporting for Idempotent Re-run" section of `commands/connect.md` doctrine: after re-run completes, report one of: "Configuration already correct — no changes needed." or "Configuration updated to match current pinned spec." or (if fallback path) "No file changes — snippet printed." (FR-008)

**Checkpoint**: All three user story control flows are now complete and independently testable.

---

## Phase 6: Testing & Validation (Quickstart Scenarios)

**Purpose**: Verify the complete doctrine against all eight scenarios and four cross-cutting checks in quickstart.md — ensuring all requirements (FR-001 through FR-011) are met.

**NOTE**: This is manual/scripted verification, not automated testing, per Constitution Principle V. See quickstart.md for full setup and read-through procedures for each scenario.

- [X] T018 [P] Verify Scenario 1 (Supported client, no prior MCP config): In a scratch directory, create fixture files and read-through `commands/connect.md` to confirm the doctrine instructs creating `.cursor/mcp.json` with `launchdarkly` entry containing command, args, and token env-var reference — no value (User Story 1, P1, Acceptance Scenario 1)
- [X] T019 [P] Verify Scenario 2 (Existing unrelated entries preserved): Pre-populate `.cursor/mcp.json` with a `playwright` entry and read-through to confirm the doctrine instructs adding `launchdarkly` alongside it without removing or rewriting `playwright` (User Story 1, P1, Acceptance Scenario 2)
- [X] T020 [P] Verify Scenario 3 (Idempotent re-run): Reuse Scenario 2's resulting file and read-through to confirm the doctrine instructs: locate existing `launchdarkly` entry by name, check if body matches current pin, leave unchanged if identical, update in place if drifted — never create second entry (User Story 3, P1, Acceptance Scenarios 1-2)
- [X] T021 [P] Verify Scenario 4 (Unmapped / no-project-scope fallback): Change integration to `cline` and read-through to confirm the doctrine creates no file, prints a correctly formatted JSON snippet with command/args/env-var-reference, prints `mcp.token_env_var` name and reminder — no value (User Story 2, P2, Acceptance Scenarios 1-2)
- [X] T022 [P] Verify Scenario 4b (Windsurf unmapped client): Change integration to a value absent from Spec Kit's catalog (e.g. `windsurf`) and read-through to confirm same four checks as Scenario 4, with reporting text distinguishing "not a recognized adapter" from Cline's "no project-scoped MCP config" (User Story 2, P2, research.md Decision 3)
- [X] T023 [P] Verify Scenario 5 (Malformed existing config): Pre-populate `.cursor/mcp.json` with invalid JSON and read-through to confirm the doctrine instructs attempting parse, treating failure as error, reporting the problem, and falling back to snippet — never blindly overwriting (Edge Case, FR-010)
- [X] T024 [P] Verify Scenario 6 (Empty/unconfigured pin): Leave `mcp.command` empty in rollout-config.yml and read-through to confirm the doctrine instructs reporting "pin not yet configured" and taking neither write nor fallback-with-placeholders path (Edge Case, FR-011)
- [X] T025 [P] Verify Scenario 7 (Detection failure): Remove `.specify/integration.json` entirely and read-through to confirm the doctrine instructs reporting detection failure and falling back to snippet without guessing (Edge Case, spec.md)
- [X] T026 [P] Verify Scenario 8 (Multi-integration project): Populate `.specify/integration.json` with `installed_integrations` containing 2+ entries (e.g. `["copilot", "cursor_agent"]`) and an `integration` field naming only one of them, and read-through to confirm the doctrine instructs acting solely on the `integration` field's single value and never iterating or acting on any other entry in `installed_integrations` (spec.md Edge Case — multi-integration project, research.md Decision 1)
- [X] T027 Cross-cutting check: Grep `commands/connect.md` to confirm no example/placeholder token value ever appears outside of `token_env_var` / `token env` / `env-var` / `environment variable` context (FR-004)
- [X] T028 Cross-cutting check: Grep `commands/connect.md` to confirm adapter mapping table covers at least FR-001's minimum client set (copilot, claude, cline, cursor, windsurf, gemini, codex) (FR-001)
- [X] T029 Cross-cutting check: Grep `commands/connect.md` to confirm idempotency and no-overwrite language (preserve, untouched, exact one entry, never duplicate, etc.) is present throughout (FR-005, FR-006)
- [X] T030 Cross-cutting check: Grep `commands/connect.md` to confirm explicit non-action guarantee language (never launches, never connects to, never starts the MCP server; never prompts for/reads/stores a token value) is present and unambiguous (FR-009, T006)

---

## Phase 7: Polish & Documentation

**Purpose**: Finalize the feature and ensure all artifacts are consistent and complete.

- [X] T031 Ensure `commands/connect.md` YAML frontmatter is complete and matches the established command format (title, description, visibility, mode, etc.)
- [X] T032 Ensure the Markdown body is well-organized with clear section headings, code/pseudocode examples, and step-by-step instructions for each control flow path
- [X] T033 Add a final "Summary" section to `commands/connect.md` listing the three supported paths (write for mapped clients, fallback snippet for unmapped/no-scope, error handling) and key guarantees (FR-001 through FR-011)
- [X] T034 Update `specs/011-rollout-connect-setup/contracts/connect-adapter-mapping.md` to match the final adapter mapping table as authored in `commands/connect.md` (must stay in sync per this feature's own contract)
- [X] T035 Verify all cross-references and links in spec.md, plan.md, data-model.md, quickstart.md point to correct sections of the completed `commands/connect.md` doctrine
- [X] T036 Final sanity check: Confirm `commands/connect.md` reads like executable agent instructions (not just reference documentation) — every control-flow decision, every file operation, every output message should be directly actionable by the executing agent

---

## Dependencies & Execution Order

```
Phase 1 (T001)
     ↓
Phase 2 (T002-T006)  [BLOCKING — must complete before Phases 3-5]
     ├─ Phase 3 (US1: T007-T010)  [P] Parallelizable with Phase 4-5
     ├─ Phase 4 (US2: T011-T014)  [P] Parallelizable with Phase 3 & 5
     └─ Phase 5 (US3: T015-T017)  [P] Parallelizable with Phase 3 & 4
                ↓
          Phase 6 (T018-T030)  [Testing — must complete before Phase 7]
                ↓
          Phase 7 (T031-T036)  [Polish & finalization]
```

**Parallel Execution Opportunity**: After Phase 2 completes:
- Author US1 (write path), US2 (fallback path), and US3 (idempotency) **in parallel** — they are logically independent control flows that converge only in the shared foundation (Phase 2).
- Test all three user stories (Phase 6 tasks T018-T026) **in parallel** — each scenario is independent and can be verified simultaneously.

---

## MVP Scope

**Minimum Viable Product (Phase 1-5)**: Complete rewrite of `commands/connect.md` with:
- ✅ Client detection (T002)
- ✅ Adapter mapping (T003)
- ✅ Pinned spec resolution (T004)
- ✅ Error handling (T005, integrated throughout)
- ✅ Non-action guarantees (T006)
- ✅ Write path for supported clients (T007-T010)
- ✅ Fallback path for unmapped/no-scope clients (T011-T014)
- ✅ Idempotency & drift detection (T009, T015-T017)

**Post-MVP** (Phase 6-7): Testing, documentation, and final polish ensure the feature is production-ready and maintainable.

---

## Format Validation Checklist

✅ All tasks follow checklist format: `- [ ] [TaskID] [P?] [Story] Description`
✅ All tasks have sequential IDs (T001-T036) in execution order
✅ Story labels [US1], [US2], [US3] present for user story phase tasks
✅ File paths included in descriptions (`commands/connect.md`, `.cursor/mcp.json`, etc.)
✅ Setup and Foundational phases precede user story phases
✅ Independent tests for each user story clearly stated
✅ Phase dependencies and parallel execution opportunities documented
✅ MVP scope identified (Phase 1-5)

---

## Total Task Count: 36

- **Phase 1 (Setup)**: 1 task
- **Phase 2 (Foundational)**: 5 tasks
- **Phase 3 (US1)**: 4 tasks
- **Phase 4 (US2)**: 4 tasks
- **Phase 5 (US3)**: 3 tasks
- **Phase 6 (Testing)**: 13 tasks
- **Phase 7 (Polish)**: 6 tasks

**Parallel Opportunities**:
- T003-T006 can run in parallel after T002 (4-way parallelism)
- T007-T010 (US1), T011-T014 (US2), T015-T017 (US3) can run in parallel after Phase 2 (3-way parallelism)
- T018-T026 (testing scenarios) can run in parallel (9-way parallelism)
- T027-T030 (cross-cutting checks) can run in parallel (4-way parallelism)

**Independent Test Criteria**:
- **US1**: Write path produces correct file with single LaunchDarkly entry, preserving unrelated entries, no token value
- **US2**: Fallback path produces no file changes, prints correct snippet with env-var reminder, no token value
- **US3**: Re-run produces single LaunchDarkly entry (no duplicate), updates if drifted, preserves unrelated entries

All three stories should be fully functional and independently testable after their respective phases complete.
