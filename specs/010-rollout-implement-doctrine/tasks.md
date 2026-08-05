---
description: "Task list for implementing the Rollout Implement Doctrine (pre-implement briefing)"
---

# Tasks: Rollout Implement Doctrine (Pre-Implement Briefing)

**Input**: Design documents from `specs/010-rollout-implement-doctrine/`

**Target File**: `commands/brief-implement.md` — Replace placeholder body with full pre-implement doctrine

**Prerequisite Context**:
- Understand existing `brief-*.md` command format (YAML frontmatter + Markdown body)
- Review `specs/004-rollout-detection-doctrine/`, `specs/006-rollout-plan-doctrine/`, and `specs/007-rollout-tasks-doctrine/` for established gate/lineage patterns
- Understand the seven provider-neutral intents and how they map to MCP tool discovery

**Tests**: No automated tests are required. Verification is via quickstart.md scenarios (text-based, no live MCP server).

**Organization**: Tasks are grouped by user story to enable independent authoring and verification of each doctrine branch.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different file sections, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Understanding & Context)

**Purpose**: Establish the baseline for authoring the doctrine

- [X] T001 Review existing `brief-*.md` command format in `commands/brief-specify.md`, `commands/brief-clarify.md`, `commands/brief-plan.md`, `commands/brief-tasks.md` to understand YAML frontmatter + Markdown body structure
- [X] T002 Review gate script contract in `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` to confirm gate script output shape
- [X] T003 Review Delivery Strategy pattern in `specs/006-rollout-plan-doctrine/plan.md` and existing examples to understand section structure
- [X] T004 Review rollout task categories established by `specs/007-rollout-tasks-doctrine/spec.md` (create flag, configure environments, configure targeting, integrate SDK, add telemetry validation, define rollback conditions)
- [X] T005 [P] Skim `quickstart.md` in this feature to understand the five verification scenarios
- [X] T006 [P] Review `constitution.md` Principle VI (Guardrailed Provider Execution) and Principle IV (Provider-Neutral Doctrine) to internalize guardrail + MCP binding requirements

**Checkpoint**: Context established — ready to author the doctrine

---

## Phase 2: Foundational (YAML & Structure)

**Purpose**: Establish the document shell and header

- [X] T007 Create YAML frontmatter for `commands/brief-implement.md` matching the format used in other `brief-*.md` commands (title, description, parameters for flag name and delivery strategy)
- [X] T008 Write introductory paragraph explaining that this is a pre-implement briefing injected by the `before_implement` hook and briefly summarizing what the doctrine will do

**Checkpoint**: Document structure in place — ready to author doctrine body

---

## Phase 3: User Story 1 - Gate Logic & MCP Introspection (Priority: P1) 🎯

**Goal**: Implement the two-stage gate check and MCP server introspection per FR-001 through FR-008

**Independent Test**: Verify gate script invocation, rollout task detection, MCP introspection instructions, and runtime binding logic are all documented

### Implementation for US1

- [X] T009 [US1] Write the two-stage gate section in `commands/brief-implement.md`:
  - FR-001: Invoke rollout gate script against `spec.md` in default mode
  - FR-002: If `hasFlags=false`, emit one-line no-op with zero MCP introspection or provider action
  - FR-003: If `hasFlags=true`, scan `tasks.md` for rollout task presence (Feature 007 categories)
  - FR-004: If rollout tasks absent, emit distinct status message recommending `/speckit.tasks`, stop without MCP introspection

- [X] T010 [US1] Write the MCP introspection & binding section in `commands/brief-implement.md`:
  - FR-005: Instruct using exactly the pinned LaunchDarkly MCP server reference from `rollout-config.template.yml`'s `mcp.*` block, never a substitute
  - FR-006: Instruct runtime introspection via `tools/list`, `resources/list`, `prompts/list` before binding or invoking any tool
  - FR-007: Define all seven provider-neutral intents (discover environments, discover segments, create flag, set targeting, set percentage rollout, read flag status, archive flag)

- [X] T011 [US1] Write the task execution section in `commands/brief-implement.md`:
  - FR-008: Instruct the agent to execute the three provider-facing rollout task categories (create flag, configure environments, configure targeting) using bound MCP tools
  - Parameters sourced ONLY from `plan.md`'s Delivery Strategy section and `tasks.md`'s rollout tasks, never invented or re-derived from `spec.md` alone
  - Include clear instructions on how to extract flag name, environments, targeting rules, and percentages from the plan and tasks

**Checkpoint**: US1 doctrine section complete — MCP introspection, binding, and execution logic documented

---

## Phase 4: User Story 2 - Guardrails (Priority: P1)

**Goal**: Implement the two non-negotiable guardrails per FR-009 and FR-010

**Independent Test**: Verify production-exposure guardrail and token-handling guardrail are clearly documented as separate, independent rules

### Implementation for US2

- [X] T012 [US2] Write the production-exposure guardrail section in `commands/brief-implement.md`:
  - FR-009: Instruct NEVER invoking any MCP tool that would advance live production exposure beyond what the current task or plan explicitly specifies, unless the user has explicitly instructed that specific advance in the current session
  - Use language closely mirroring Constitution Principle VI wording
  - Include examples of forbidden actions (raising percentage already serving production, enabling flag in production environment without explicit user instruction)

- [X] T013 [US2] Write the token-handling guardrail section in `commands/brief-implement.md`:
  - FR-010: Instruct NEVER reading, echoing, logging, or inlining the provider API token under any circumstance
  - Clarify that credential handling belongs solely to the MCP server process via environment variable
  - Verify that `commands/brief-implement.md` itself contains no token value, placeholder token, or token example

**Checkpoint**: US2 doctrine complete — Both guardrails documented as separate, independent rules with no token value present in the file

---

## Phase 5: User Story 3 - Non-Rollout Features (Priority: P1)

**Goal**: Ensure non-rollout features see zero MCP introspection and zero rollout behavior per FR-002

**Independent Test**: Verify the no-marker branch is a single-line no-op with no MCP introspection or provider action reachable from it

### Implementation for US3

- [X] T014 [US3] Refine the no-marker branch in `commands/brief-implement.md` (from T009):
  - Confirm gate script `hasFlags=false` is the trigger (including diagnostic exit code)
  - Verify the one-line no-op message is concise and contains zero MCP introspection instructions
  - Verify no plan-only-mode task is recorded for non-rollout features
  - Verify implementation proceeds exactly as it would without the `rollout` extension installed

**Checkpoint**: US3 doctrine complete — Non-rollout features guaranteed zero rollout context pollution

---

## Phase 6: User Story 4 - Graceful Degradation (Priority: P2)

**Goal**: Implement graceful degradation when no MCP is available per FR-011, FR-012, FR-013

**Independent Test**: Verify plan-only-mode branch records exactly one setup task, references `speckit.rollout.connect`, contains no MCP registration steps, and performs no fabrication

### Implementation for US4

- [X] T015 [US4] Write the MCP reachability check section in `commands/brief-implement.md`:
  - FR-011: When MCP is not configured, not reachable, or introspection fails, do NOT fail the overall `/speckit.implement` run
  - Continue implementation in plan-only mode

- [X] T016 [US4] Write the plan-only-mode task recording section in `commands/brief-implement.md`:
  - FR-011: Record exactly one task instructing the user to configure the MCP connection
  - FR-012: Reference `speckit.rollout.connect` as the remediation step; do NOT include MCP registration/setup instructions (out of scope for Feature 010, reserved for Feature 011)
  - Confirm no plan-only-mode task is recorded for non-rollout features (already handled in T014)

- [X] T017 [US4] Write the partial-capability fallback section in `commands/brief-implement.md`:
  - FR-013: If MCP is reachable but does not advertise a tool for one of the seven provider-neutral intents, skip only the affected action(s), note that they could not be performed, and continue with the intents it could bind
  - Provide clear guidance on how to note skipped actions without failing the run

**Checkpoint**: US4 doctrine complete — Graceful degradation branch fully documented

---

## Phase 7: Verification & Quality

**Purpose**: Ensure the doctrine is complete, correct, and ready for use

- [X] T018 [P] Verify gate script & marker contract:
  - Run `scripts/bash/rollout-gate.sh` against `specs/999-quickstart-fixture/` (setup via Scenario 1 in quickstart.md) and confirm `hasFlags=true`, `flags=checkout_v2`, `source=spec.md`
  - Confirm `commands/brief-implement.md` correctly invokes the gate script and handles the output

- [X] T019 [P] Verify all seven provider-neutral intents are named:
  - Run: `grep -in "discover environments\|discover segments\|create flag\|set targeting\|set percentage rollout\|read flag status\|archive flag" commands/brief-implement.md`
  - Expected: At least one match for each intent

- [X] T020 [P] Verify pinned-server instruction is present:
  - Run: `grep -in "pinned\|substitut" commands/brief-implement.md`
  - Expected: At least one match confirming no-substitution rule

- [X] T021 [P] Verify token guardrail:
  - Run: `grep -in "token" commands/brief-implement.md`
  - Expected: Every match is an instruction *about* not handling tokens, never a literal token value or example

- [X] T022 [P] Verify graceful-degradation reference:
  - Run: `grep -n "speckit.rollout.connect" commands/brief-implement.md`
  - Expected: At least one match in the plan-only-mode branch

- [X] T023 Walkthrough Quickstart Scenario 1 (User Story 1, full chain):
  - Set up fixture `specs/999-quickstart-fixture/` with marker, Delivery Strategy, and rollout tasks
  - Read through `commands/brief-implement.md` and confirm it instructs: gate check → tasks check → MCP introspection → tool binding → task execution using plan/tasks-sourced parameters

- [X] T024 Walkthrough Quickstart Scenario 2 (User Story 2, guardrails):
  - Confirm two distinct guardrail paragraphs exist (production exposure + token handling)
  - Confirm no guardrail-restricted action is reachable for production exposure beyond plan scope without explicit user instruction
  - Confirm no token value appears anywhere in the file

- [X] T025 Walkthrough Quickstart Scenario 3 (User Story 3, non-rollout):
  - Set up fixture `specs/998-quickstart-fixture-no-marker/` with no marker
  - Confirm gate script returns `hasFlags=false`
  - Confirm `commands/brief-implement.md` emits a one-line no-op, no MCP introspection, no rollout task

- [X] T026 Walkthrough Quickstart Scenario 4 (User Story 4, graceful degradation):
  - Read through `commands/brief-implement.md` and confirm it instructs: continue on MCP unreachability, record exactly one task referencing `speckit.rollout.connect`, no inline setup steps, no fabricated provider actions

- [X] T027 Walkthrough Quickstart Scenario 5 (Edge case, marker + no tasks):
  - Set up fixture with marker present but no rollout tasks in `tasks.md`
  - Confirm `commands/brief-implement.md` emits a distinct status message (different from no-marker and graceful-degradation messages), recommends `/speckit.tasks`, performs no MCP introspection

- [X] T028 [P] Format validation:
  - Confirm `commands/brief-implement.md` has valid YAML frontmatter (can be parsed)
  - Confirm the Markdown body uses proper heading hierarchy (##, ###, ####)
  - Confirm all code blocks are properly fenced (```...```)
  - Confirm no broken links or references to undefined sections

- [X] T029 Cleanup fixtures:
  - Delete scratch fixture directories created during verification (`specs/999-quickstart-fixture/`, `specs/998-quickstart-fixture-no-marker/`, etc.)
  - Confirm no uncommitted fixture data remains in `specs/`

**Checkpoint**: All verification scenarios passed, quality checks complete — doctrine ready for use

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final review and documentation

- [X] T030 [P] Consistency check across related doctrine files:
  - Confirm gate script invocation in `commands/brief-implement.md` matches actual `scripts/bash/rollout-gate.sh` usage
  - Confirm marker/heading text in `commands/brief-implement.md` matches `contracts/rollout-gate-cli.md` exactly
  - Confirm Delivery Strategy field names referenced match `commands/brief-plan.md`'s section
  - Confirm rollout task categories referenced match `commands/brief-tasks.md`'s categories

- [X] T031 [P] Principle alignment check:
  - Confirm doctrine complies with Constitution Principle I (additive-only, no core template edits)
  - Confirm Principle II (self-gating, near-zero noise)
  - Confirm Principle III (strict content lineage — parameters sourced from plan/tasks, never spec alone)
  - Confirm Principle IV (provider-neutral, runtime introspection, pinned MCP only)
  - Confirm Principle V (token handling — never read/echo/log)
  - Confirm Principle VI (guardrailed provider execution — no auto-advance, graceful degradation)

- [X] T032 Add implementation notes to `plan.md`:
  - Document any deviations from the template structure or unexpected decisions made during implementation
  - Confirm all FR requirements (FR-001 through FR-014) are addressed in the final `commands/brief-implement.md`

- [X] T033 Final review of `commands/brief-implement.md`:
  - Confirm all four user stories (US1, US2, US3, US4) are fully implemented
  - Confirm all edge cases from spec.md are addressed
  - Confirm the doctrine is ready to be injected by the `before_implement` hook

**Checkpoint**: Final polish complete — feature ready for integration

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Stories (Phase 3-6)**: Depend on Foundational completion; can proceed in parallel or sequentially
- **Verification (Phase 7, T018-T029)**: Depends on all user story phases being complete
- **Polish (Phase 8, T030-T033)**: Depends on Verification passing

### Within Each User Story

- Read/research tasks (Ts 001-006) should be completed first
- YAML/structure tasks (Ts 007-008) should be completed before doctrine body authoring
- Each doctrine section (Ts 009-017) can be authored independently but reference one file (`commands/brief-implement.md`)
- Verification tasks (T018-T029) depend on all doctrine sections being written
- Polish tasks (T030-T033) depend on Verification passing

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T005, T006)
- All Verification/Quality tasks marked [P] can run in parallel (T018-T022, T028, T030-T031)
- User story doctrine sections (Ts 009-017) can be authored in parallel since they address different concerns within the same file

---

## Parallel Example: Quality Verification

```bash
# Launch all verification commands together:
grep -in "discover environments|discover segments|create flag|set targeting|set percentage rollout|read flag status|archive flag" commands/brief-implement.md
grep -in "pinned|substitut" commands/brief-implement.md
grep -in "token" commands/brief-implement.md
grep -n "speckit.rollout.connect" commands/brief-implement.md
```

All four commands can run in parallel to verify the doctrine covers all intents, the no-substitution rule, token guardrail, and graceful degradation.

---

## Implementation Strategy

### Content-First Approach

1. **Complete Setup + Foundational** (Phases 1-2) — context and document shell established
2. **Author User Story sections** (Phases 3-6) — write each doctrine branch covering a user story or guardrail
3. **Verify Against Scenarios** (Phase 7) — walkthrough each scenario in quickstart.md to ensure correctness
4. **Polish & Finalize** (Phase 8) — cross-check principles, consistency, and readiness

### Single-File Focus

This feature produces ONE file: `commands/brief-implement.md` (approximately 350-450 lines including whitespace and headings). All tasks contribute to content for this one file.

---

## Success Criteria *(Per Spec)*

- **SC-001**: When a rollout feature's marker, Delivery Strategy, and rollout tasks are all present and a pinned LaunchDarkly MCP server is reachable, running `/speckit.implement` results in the flag/targeting/environment actions being performed
- **SC-002**: When no MCP server is reachable, `/speckit.implement` completes without failing and records exactly one setup task referencing `speckit.rollout.connect`
- **SC-003**: No provider API token value appears in any output or tool-call arguments
- **SC-004**: Non-rollout features see zero MPC introspection and zero rollout-related tasks added

---

## Format Checklist

Before marking each task complete, verify:
- All code examples in `commands/brief-implement.md` are properly fenced (``` ... ```)
- All section headings use proper Markdown hierarchy (##, ###)
- All emphasis and formatting follows Markdown standards
- No broken links or cross-references
- YAML frontmatter is valid and parseable
- No trailing whitespace or inconsistent indentation
- All FR requirements from spec.md are addressed in the final file

---

## Notes

- This is a documentation/content-only feature — no code, no data model implementation
- The sole deliverable is the rewritten body of `commands/brief-implement.md`
- No new dependencies or tools are introduced; doctrine uses standard MCP operations
- Verification uses the quickstart.md scenarios and manual text-based checks (no live MCP server needed)
- Upon completion, the doctrine is immediately ready to be injected by the `before_implement` hook in the next `/speckit.implement` run
