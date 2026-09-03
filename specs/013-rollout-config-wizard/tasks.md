---

description: "Task list for Rollout Config Wizard (013)"
---

# Tasks: Rollout Config Wizard (Pinned MCP Server Removal & Modular Provider Config)

**Input**: Design documents from `/specs/013-rollout-config-wizard/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [data-model.md](./data-model.md), [research.md](./research.md), [contracts/rollout-config-wizard.md](./contracts/rollout-config-wizard.md), [contracts/rollout-provider-command.md](./contracts/rollout-provider-command.md), [quickstart.md](./quickstart.md)

**Tests**: Not requested for this feature (no test tasks included). Verification is the manual/scripted `quickstart.md` read-through walk described in plan.md's Testing section.

**Nature of this feature**: Content-only (Markdown doctrine + YAML schema/config). There is no source code, so "implementation" below means writing/editing the specific doctrine sections, schema files, and doc prose that `plan.md`'s Scale/Scope names. Most User Story tasks edit the same file (`commands/config.md`), so within a phase they are **sequential, not parallel**, even though they carry a `[Story]` label each.

**Known design-doc inconsistency to resolve while implementing** (see T006): `data-model.md` and both `contracts/*.md` files use a singular example field `launchdarkly.environment_key`, while `spec.md` (FR-010, FR-011, FR-018, FR-026) and the pre-existing `rollout-config.template.yml` consistently use the plural, array-shaped `launchdarkly.environments` (one or more keys). `spec.md`'s FR wording is authoritative — treat `launchdarkly.environments` (array) as the real field name throughout.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US7)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create the two new command files and remove the superseded one, so subsequent phases have somewhere to write doctrine content.

- [X] T001 [P] Create `commands/config.md` with YAML frontmatter (`description`, `visibility: "public"`, `mode: "user-invoked"`) and a `# speckit.rollout.config` role/overview section summarizing the seven-step wizard, per [contracts/rollout-config-wizard.md](./contracts/rollout-config-wizard.md)'s Invocation section
- [X] T002 [P] Create `commands/provider.md` with YAML frontmatter and a `# speckit.rollout.provider` role/overview section summarizing the switch/preset behavior, per [contracts/rollout-provider-command.md](./contracts/rollout-provider-command.md)'s Invocation section
- [X] T003 [P] Delete `commands/connect.md` (permanently removed, not deprecated-alongside, per FR-001; superseded by `commands/config.md`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema, command registration, and field-naming groundwork that every user story phase writes against.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Rewrite `rollout-config.template.yml` to the modular per-provider shape: remove the entire `mcp:` block (`command`, `args`, `version`, `repository`, `token_env_var`) per FR-017; keep top-level `provider: launchdarkly`; keep the `launchdarkly:` block with `project_key: ""` and `environments: []`; add `server_type: ""` (`hosted`/`local`/unset, recorded for reporting only, never trusted as a cache, per data-model.md's Provider Config Block); update the file's header comments to explain the modular multi-provider shape (a second configured provider adds a sibling top-level block, FR-026) and to note that the MCP server selection (name/key only) is **not** stored here — it lives in `.specify/extensions/rollout/local-config.yml` (FR-018)
- [X] T005 Update `extension.yml`: remove the `speckit.rollout.connect` entry from `provides.commands`; add `speckit.rollout.config` (`file: commands/config.md`) and `speckit.rollout.provider` (`file: commands/provider.md`) entries with descriptions matching FR-022; update `config.config_schema` to drop the `mcp` object entirely and reflect the modular shape (`provider: string`, `launchdarkly: { project_key: string, environments: array, server_type: string }`) per FR-017/FR-026
- [X] T006 Reconcile the `environment_key` (singular) example field used in [data-model.md](./data-model.md)'s Provider Config Block table and in both [contracts/rollout-config-wizard.md](./contracts/rollout-config-wizard.md) and [contracts/rollout-provider-command.md](./contracts/rollout-provider-command.md)'s example YAML with `spec.md`'s authoritative plural `launchdarkly.environments` (array, one or more values) — update all three files' example field name from `environment_key`/`environment_key: production` to `environments`/`environments: [production]` so every design doc and the doctrine written in later phases agree on one field name and shape

**Checkpoint**: Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 - First-time guided configuration succeeds end to end (Priority: P1) 🎯 MVP

**Goal**: A developer with one registered hosted LaunchDarkly MCP server completes all wizard steps and ends with a saved, verified `rollout-config.yml` — no client MCP file touched.

**Independent Test**: Run quickstart.md Scenario 1 — one candidate server whose live probe succeeds with two projects/two environments each — and confirm the full step sequence, the written block (`provider: launchdarkly`, `project_key`, `environments`, `server_type: hosted`), and the final report.

### Implementation for User Story 1

- [X] T007 [US1] Write the MCP server discovery step in `commands/config.md`: introspect the developer's already-configured MCP servers read-only; MUST NOT write, launch, or register any MCP server (FR-002, FR-004)
- [X] T008 [US1] Write the candidate-resolution step in `commands/config.md` for the single-candidate case: exactly one candidate proceeds automatically with no extra confirmation prompt (FR-006)
- [X] T009 [US1] Write the server-type determination step in `commands/config.md` for the hosted (success-with-data) outcome: attempt a live, read-only call to whichever introspected tool lists the developer's LaunchDarkly projects; a clear success with results classifies `hosted` and is never asked of the developer (FR-008)
- [X] T010 [US1] Write the hosted branch's project/environment selection in `commands/config.md`: present the live-introspected project list, then the selected project's live environment list, and let the developer pick one project and one or more environments (FR-009, FR-010)
- [X] T011 [US1] Write the read-verification step in `commands/config.md`, shared by both the hosted branch and the local branch's manual-entry sub-case: perform a read-only flag-listing call against the resolved project/environments to confirm access before the final confirmation gate (FR-013)
- [X] T012 [US1] Write the final-summary-and-confirmation step in `commands/config.md`: show a complete summary of everything that will be written; MUST NOT write anything until the developer explicitly confirms (FR-015; contract "Final confirmation")
- [X] T013 [US1] Write the config-write step in `commands/config.md`: write exactly one modular `provider: launchdarkly` + `launchdarkly:` block (`project_key`, `environments`, `server_type: hosted`) to `rollout-config.yml`, with zero `mcp.*` fields anywhere, and save the selected MCP server's name/key only to `local-config.yml` (FR-017, FR-018, FR-026)
- [X] T014 [US1] Write the final-report step in `commands/config.md`: state provider, MCP server used, hosted/local determination, project, environments, and read-verification status (FR-015)
- [X] T015 [US1] Add a "Prohibited Actions" section to `commands/config.md` restating, across every step: never request/read/store/echo a credential/token value (FR-023); never write/create/modify any client's native MCP configuration file (FR-002)

**Checkpoint**: User Story 1's hosted happy path is fully doctrine-complete and independently testable via quickstart.md Scenario 1.

---

## Phase 4: User Story 2 - No LaunchDarkly-capable MCP server detected (Priority: P1)

**Goal**: Zero detected candidates stop the wizard safely with guidance and no partial save.

**Independent Test**: Run quickstart.md Scenario 2 — no introspected MCP servers — and confirm the doctrine stops immediately after discovery with clear guidance, no file written, and no further steps executed.

### Implementation for User Story 2

- [X] T016 [US2] Extend `commands/config.md`'s candidate-resolution step with the zero-candidates outcome: explain that none was detected, instruct the developer to add the official LaunchDarkly MCP server themselves in their client's MCP settings, and stop immediately with no configuration saved from that run (FR-005; spec US2 AC1)
- [X] T017 [US2] Add a "no-partial-save" invariant note to `commands/config.md`'s Prohibited Actions section, explicitly covering the zero-candidates stop, the read-verification-failure cancel, and voluntary mid-run cancellation as the three no-partial-save paths (SC-003; spec US2 AC2, Edge Cases)

**Checkpoint**: Both P1 user stories complete — MVP scope reached.

---

## Phase 5: User Story 3 - Multiple candidate MCP servers require disambiguation (Priority: P2)

**Goal**: Two or more candidate servers force an explicit developer pick before proceeding.

**Independent Test**: Run quickstart.md Scenario 3 — two introspected candidates — and confirm the doctrine lists both and proceeds only after the developer picks one, never probing the unselected candidate.

### Implementation for User Story 3

- [X] T018 [US3] Extend `commands/config.md`'s candidate-resolution step with the many-candidates outcome: list all candidates, require the developer to pick exactly one before server-type determination runs, and persist only the chosen server's name/key — never a command, arguments, version, repository, or credential value for the chosen or any other candidate (FR-007; spec US3 AC1-2)

---

## Phase 6: User Story 4 - Read verification fails after project/environment selection (Priority: P2)

**Goal**: A failed read-verification call presents an explicit cancel-or-continue choice rather than silently passing.

**Independent Test**: Run quickstart.md Scenario 7 — resolved project/environment whose read-verification check fails — and confirm the doctrine presents exactly the cancel-or-continue choice and never silently proceeds.

### Implementation for User Story 4

- [X] T019 [US4] Extend `commands/config.md`'s read-verification section (shared by both branches) with the failure path: explain the error clearly and offer exactly two choices — cancel the whole run (discarding any not-yet-saved selections) or continue anyway and save what was gathered so far with an explicit warning (FR-014; spec US4 AC1-2)
- [X] T020 [US4] Extend `commands/config.md`'s final-summary and final-report sections so that, when the developer chose to continue after a read-verification failure, the summary/report explicitly states read access could not be verified (FR-014, FR-015; spec US4 AC3)

---

## Phase 7: User Story 5 - Re-running the wizard to change a prior selection (Priority: P2)

**Goal**: The wizard is safely re-runnable, letting a developer change any previous selection without disturbing unrelated saved values.

**Independent Test**: Run quickstart.md Scenario 8 — re-run against an existing `rollout-config.yml`, changing only the environment selection — and confirm the existing `launchdarkly:` block is updated in place with `server_type` re-verified fresh, and no duplicate block or disturbed field results.

### Implementation for User Story 5

- [X] T021 [US5] Add a re-run-behavior section to `commands/config.md`: on invocation, read any existing `rollout-config.yml`/`local-config.yml` values and show them as current selections; allow changing any previous selection (provider, MCP server, project, or environments); always re-run server-type determination fresh rather than reusing a prior run's stored `server_type` value (FR-016; spec US5 AC1-2)
- [X] T022 [US5] Extend `commands/config.md`'s config-write step so that, on re-run, only the changed fields of the existing `launchdarkly:` block are updated in place — no duplicate block is created, and unrelated fields, other provider blocks, and the `local-config.yml` MCP-server-selection value (unless explicitly changed in that run) are left untouched (FR-016; quickstart Scenario 8)

---

## Phase 8: User Story 7 - Local MCP server: manual entry or explicit opt-out (Priority: P2)

**Goal**: A developer on a local (non-project-listing-capable) LaunchDarkly MCP server can still complete the wizard via manual entry, or explicitly defer configuration without any fabricated value.

**Independent Test**: Run quickstart.md Scenarios 4-6 — local classification via clean not-found and via ambiguous/timeout outcomes, manual entry, and explicit opt-out — and confirm no placeholder values are ever written and read verification is skipped only in the opt-out sub-case, with a clear recorded note.

### Implementation for User Story 7

- [X] T023 [US7] Extend `commands/config.md`'s server-type determination step with the local-classification outcomes: a clean "capability not found" result classifies `local`; any ambiguous, timeout, or unclassifiable transport error is also treated as `local` rather than blocking the wizard (FR-008; Edge Cases; research.md Finding 4)
- [X] T024 [US7] Write the local branch's project/environment step in `commands/config.md`: prompt the developer to either type the project ID and one or more environment keys directly (saved exactly as typed to `launchdarkly.project_key` / `launchdarkly.environments`, never fabricated or defaulted), or explicitly opt out of entering them now (FR-011); when the developer types values (the non-opt-out sub-case), proceed into the shared read-verification step (T011) against those typed values, exactly as the hosted branch does (FR-013; quickstart.md Scenario 4)
- [X] T025 [US7] Write the local branch's opt-out sub-case in `commands/config.md`: proceed without setting `launchdarkly.project_key` or `launchdarkly.environments` (no placeholder values), skip the read-verification step entirely, and adjust the final summary/report to explicitly state that project, environment, and read verification are not yet configured and must be completed manually or via a future wizard re-run (FR-012, FR-015; spec US7 AC3)
- [X] T026 [US7] Extend `commands/config.md`'s config-write step to record `launchdarkly.server_type: local` (manual-entry sub-case) alongside `project_key`/`environments`, or leave `server_type` alongside the empty project/environment fields in the opt-out sub-case, per data-model.md's Provider Config Block

---

## Phase 9: User Story 6 - Provider selection and switching signals future multi-provider intent (Priority: P3)

**Goal**: Step 1's provider list visibly signals future multi-provider support, and `speckit.rollout.provider` lets a developer switch/preset a provider without re-running the whole wizard.

**Independent Test**: Run quickstart.md Scenarios 9-10 — provider-switch reusing an existing block, and provider-switch triggering a new preset — plus a read-through of the wizard's provider-selection step confirming LaunchDarkly is selectable and any other listed provider is visibly disabled with a "coming soon" label.

### Implementation for User Story 6

- [X] T027 [US6] Write the provider-selection step in `commands/config.md`, run before MCP server discovery: present "LaunchDarkly" as the only selectable provider; display any other provider name as visibly disabled with a "coming soon" label and not selectable; selecting LaunchDarkly saves `provider: launchdarkly` (FR-003; spec US6 AC1-2)
- [X] T028 [US6] Write the full `commands/provider.md` doctrine: parse the required `<provider_name>` argument; if a saved config block already exists for it, set `provider: <provider_name>` and reuse the block as-is with zero re-prompting; if no saved block exists yet, trigger that provider's own config preset (in V1, only `launchdarkly` has a real preset — reusing `commands/config.md`'s provider-selection-through-write steps scoped to that one provider) and only set `provider:` once the preset run completes (leaving the prior provider active if cancelled); if `<provider_name>` is not a recognized provider name, report clearly and create no malformed or empty block; never modify any other provider's existing block; require the same explicit-confirmation gate as the underlying preset flow before any write (FR-025; contracts/rollout-provider-command.md)

**Checkpoint**: All seven user stories are doctrine-complete.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Propagate the new wizard/provider model into every remaining place FR-021 names, and validate the whole feature end to end.

- [X] T029 [P] Update `commands/brief-implement.md`'s MCP-server-resolution section (Step 3.1, "Locate and Load the Pinned MCP Server Configuration") to resolve the MCP server from the developer's own configured selection (`local-config.yml`'s MCP server name/key plus `rollout-config.yml`'s `launchdarkly.*` values) instead of a "pinned" `mcp.*` reference; if `launchdarkly.project_key`/`environments` are entirely absent (local-branch opt-out case), degrade to the existing "no MCP available" plan-only-mode path rather than fabricating or guessing values; rename its `speckit.rollout.connect` remediation reference to `speckit.rollout.config` (FR-020)
- [X] T030 [P] Update `specs/002-config-system/contracts/rollout-config-schema.md`'s Shape, Guarantees, and "Consumers of this contract" sections to the modular schema: remove `mcp.*` entirely, add `server_type`, document the `local-config.yml` placement of the MCP server selection field (FR-018), and rename the `speckit.rollout.connect`/pinned-registration consumer bullet to `speckit.rollout.config`/`speckit.rollout.provider` (FR-017, FR-021, FR-026)
- [X] T031 [P] Add superseded-acceptance-criteria annotations to `specs/002-config-system/spec.md`, marking every acceptance scenario and FR that assumed the flat `mcp.*` pinned-reference schema or a single always-`launchdarkly:`-block schema as superseded by Feature 013, without rewriting the historical scenario text itself (FR-021; SC-006)
- [X] T032 [P] Add superseded-acceptance-criteria annotations to `specs/010-rollout-implement-doctrine/spec.md`, marking every acceptance scenario and FR that referenced "the pin" or `speckit.rollout.connect` as the plan-only-mode remediation command as superseded by Feature 013's `speckit.rollout.config`/`speckit.rollout.provider` (FR-020, FR-021; SC-006)
- [X] T033 [P] Add superseded-acceptance-criteria annotations to `specs/011-rollout-connect-setup/spec.md`, marking its acceptance scenarios (US1-US3, all reliant on writing a client's MCP configuration file with the pinned server spec) as fully superseded/removed by Feature 013 (FR-001, FR-002, FR-021; SC-006)
- [X] T034 [P] Update `docs/foundation/vision.md`: rewrite §6.2 ("Pinned server reference") to describe the config-or-live-discovery model (Constitution Principle IV v2.0.0); replace §7 ("Setup Command (`speckit.rollout.connect`)") with a description of the seven-step `speckit.rollout.config` wizard and the `speckit.rollout.provider` switch command; update §8 to note the MCP server selection now lives in `local-config.yml` and that `mcp.command`/`args`/`version`/`repository` no longer exist; update §11's extension-point bullet 5 and §12's extension-layout diagram (`connect.md` → `config.md`/`provider.md`) (FR-021)
- [X] T035 [P] Update `docs/providers.md`: replace `/speckit.rollout.connect` references and the "generalize the hardcoded `launchdarkly` entry key in `connect`" TODO with `/speckit.rollout.config`/`/speckit.rollout.provider` and the modular per-provider block model (FR-021)
- [X] T036 [P] Update `docs/usage.md`: replace the "Install and connect" section, its sequence diagram, and the troubleshooting table rows referencing `connect`/`mcp.*` with the new wizard steps, hosted/local branching, and the `/speckit.rollout.provider` switch command (FR-021)
- [X] T037 [P] Update `README.md`: replace the `speckit.rollout.connect` Quick Start references and the "Only `connect` is meant to be invoked directly" note with `/speckit.rollout.config` (and mention `/speckit.rollout.provider`) (FR-021)
- [X] T038 Run all ten scenarios in `quickstart.md` against the completed `commands/config.md`/`commands/provider.md` doctrine and record pass/fail results for each, using fixture/simulated MCP responses only (never a real token or a real write beyond scratch fixtures)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories (schema/command registration/field-naming must exist before any step doctrine is written against them).
- **User Stories (Phase 3-9)**: All depend on Foundational completion. Because Phases 3-8 all edit `commands/config.md`, they must be done **sequentially in the order listed** (US1 → US2 → US3 → US4 → US5 → US7 → US6) to avoid the same-file conflicts a real team would hit editing one doctrine file; a solo implementer should follow this order top-to-bottom. Phase 9's `commands/provider.md` task (T028) is the one task in the user-story phases that touches a different file and could start as soon as Foundational is done, in parallel with Phases 3-8.
- **Polish (Final Phase)**: Depends on all user story phases being complete (T029-T037 reference the finished doctrine content; T038 requires all of it).

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — no dependency on other stories; establishes the base step sequence in `commands/config.md` that US2-US7 extend.
- **US2 (P1)**: Extends US1's candidate-resolution step — depends on T008 existing first (same section of the same file).
- **US3 (P2)**: Extends the same candidate-resolution step as US2 — depends on T016 for section ordering (zero-candidates before many-candidates in the same doctrine section).
- **US4 (P2)**: Extends US1's read-verification step (T011) and final-summary/report steps (T012, T014).
- **US5 (P2)**: Extends US1's overall step sequence (T007-T014) and config-write step (T013) with re-run semantics.
- **US7 (P2)**: Extends US1's server-type-determination (T009) and adds the sibling local branch to US1's hosted branch (T010-T011); depends on US1's hosted branch existing first so the two branches read as parallel alternatives in the doctrine text.
- **US6 (P3)**: Adds the provider-selection step ahead of US1's MCP-discovery step (T007) and is otherwise independent; `commands/provider.md` (T028) has no dependency on US2-US5/US7's extensions, only on Foundational and US1's final-confirmation-and-write step pattern (the preset-trigger reuses config.md's confirmation-and-write shape).

### Within Each User Story

- Steps are written in wizard order (discovery → resolution → type → branch → confirm → write → report) since later steps' doctrine text refers back to earlier ones.
- Core step content before edge-case/failure-path additions.
- Story complete before moving to the next priority story in the same file.

### Parallel Opportunities

- All Setup tasks (T001-T003) can run in parallel — three different files.
- T004, T005, T006 in Foundational touch three different files and can run in parallel, but T006 should land before any Phase 3+ task references `launchdarkly.environments`, since it fixes the field name those tasks use.
- Within Phases 3-8, tasks are sequential (same file, `commands/config.md`) — no `[P]` markers.
- T028 (`commands/provider.md`) can run in parallel with any of Phases 3-8's `commands/config.md` tasks, since it is a different file, though it is easiest to write last since it deliberately reuses config.md's finished confirmation/write shape.
- Final Phase tasks T029-T037 are all different files and can run fully in parallel once Phases 3-9 are complete; T038 must run last (it verifies the combined result).

---

## Parallel Example: Setup + Foundational

```bash
# Launch Setup together (three different files):
Task: "Create commands/config.md with YAML frontmatter and role/overview section"
Task: "Create commands/provider.md with YAML frontmatter and role/overview section"
Task: "Delete commands/connect.md"

# Launch Foundational together (three different files):
Task: "Rewrite rollout-config.template.yml to the modular per-provider shape"
Task: "Update extension.yml commands + config_schema"
Task: "Reconcile environment_key vs environments field naming across data-model.md and both contracts"
```

## Parallel Example: Final Phase

```bash
# Launch documentation/spec updates together (different files, after all doctrine is written):
Task: "Update commands/brief-implement.md MCP-resolution step"
Task: "Update specs/002-config-system/contracts/rollout-config-schema.md"
Task: "Add superseded annotations to specs/002-config-system/spec.md"
Task: "Add superseded annotations to specs/010-rollout-implement-doctrine/spec.md"
Task: "Add superseded annotations to specs/011-rollout-connect-setup/spec.md"
Task: "Update docs/foundation/vision.md"
Task: "Update docs/providers.md"
Task: "Update docs/usage.md"
Task: "Update README.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories; also resolves the `environments` field-naming inconsistency once, up front).
3. Complete Phase 3: User Story 1 (hosted happy path).
4. Complete Phase 4: User Story 2 (zero-candidates safe stop) — both are P1 and together form the smallest usable wizard.
5. **STOP and VALIDATE**: Run quickstart.md Scenarios 1 and 2 against the doctrine text.

### Incremental Delivery

1. Setup + Foundational → base files exist.
2. US1 + US2 (P1) → MVP: a developer with a hosted server can configure; a developer with none is stopped safely.
3. US3, US4, US5, US7 (P2) → disambiguation, read-verification failure handling, safe re-runs, and local-server support.
4. US6 (P3) → provider-selection UI polish and the `speckit.rollout.provider` switch/preset command.
5. Final Phase → propagate the new model into `brief-implement.md`, the schema contract, the three superseded specs, and all public docs/README; run the full quickstart.md verification pass.

### Solo/Single-File Strategy

Because Phases 3-8 all edit `commands/config.md`, there is no meaningful "parallel team" split within those phases the way the template's generic guidance describes — treat T007 through T026 as one continuous, ordered edit session against a single file, and only parallelize across Setup, Foundational, T028, and the Final Phase as noted above.

## Phase 10: Convergence

**Purpose**: Close a gap found during PR review after implementation: FR-018 pins the literal, flat key `mcp_server` for the `local-config.yml` MCP-server-selection field, but neither doctrine file that actually writes or reads it ever names that literal key — both only use vague "name/key" prose. Without the exact key name stated explicitly in the doctrine text itself, a future run/reader has no guarantee of agreeing with the writer on the field name.

- [X] T039 [US1] Update `commands/config.md`'s Step 7 "Write" section so the bullet documenting the `local-config.yml` save states the literal, flat key `mcp_server` explicitly (e.g. `mcp_server: <selected server name/key>`), replacing the vague "name/key **only**" prose, with no alternate spelling or nesting (FR-018) (partial)
- [X] T040 [US1] Update `commands/brief-implement.md`'s Step 3.1 read step so it looks up the saved MCP server selection under the literal key `mcp_server` in `local-config.yml` explicitly, replacing the vague "saved name/key from `local-config.yml`" prose, with no alternate spelling or nesting (FR-018) (partial)
- [X] T041 [US1] Update `docs/foundation/vision.md` §6.2 and §8, both of which describe the `local-config.yml` MCP-server-selection save with vague "name/key" prose, to name the literal, flat key `mcp_server` explicitly (FR-018, FR-021) (partial)
- [X] T042 [US1] Update `docs/providers.md`'s "Adding a new provider" guide, which describes the same save with vague "name/key" prose, to name the literal, flat key `mcp_server` explicitly (FR-018, FR-021) (partial)
- [X] T043 [US1] Update `rollout-config.template.yml`'s header comment, which describes the same save with vague "name/key" prose, to name the literal, flat key `mcp_server` explicitly (FR-018) (partial)

**Dependencies**: T039-T043 all depend on Phase 2 (Foundational) and the already-completed Phase 3 (US1) content in `commands/config.md`; none has a code dependency on the others (five different files) but all five should land together so every doctrine and prose reference agrees on the same literal key in the same change.
