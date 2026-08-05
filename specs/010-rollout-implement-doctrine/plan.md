# Implementation Plan: Rollout Implement Doctrine (Pre-Implement Briefing)

**Branch**: `010-rollout-implement-doctrine` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-rollout-implement-doctrine/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/brief-implement.md` (the content the
`before_implement` hook injects) with pre-implement doctrine per
vision.md §4/§6/§8. Mirrors 007/008's two-stage gate pattern: invoke the
shared gate script (Feature 003) in default mode against `spec.md`; on no
marker (`hasFlags=false`, including the diagnostic exit code), emit a
one-line no-op with no MCP introspection or provider action. On marker
present, separately check `tasks.md` for the presence of rollout tasks
(Feature 007's six categories); if absent, emit a distinct status message
recommending `/speckit.tasks` and stop, never fabricating actions from
`spec.md` or `plan.md`'s Delivery Strategy alone. When rollout tasks are
present, the doctrine instructs the agent to: use exactly the pinned
LaunchDarkly MCP server reference from `rollout-config.template.yml`'s
`mcp.*` block (no substitution); introspect it at runtime
(`tools/list`, `resources/list`, `prompts/list`); bind seven
provider-neutral intents (discover environments, discover segments, create
flag, set targeting, set percentage rollout, read flag status, archive
flag) to the tools actually advertised; execute the rollout tasks with
parameters sourced from `plan.md`'s Delivery Strategy (Feature 006) and
`tasks.md`'s rollout tasks (Feature 007); and obey two NON-NEGOTIABLE
guardrails (Constitution Principle VI) — never auto-advance live production
exposure beyond what plan/tasks/explicit current user instruction specifies,
and never read/echo/log/inline the provider token. When no MCP is
reachable, the doctrine requires graceful degradation to plan-only mode:
continue implementation without failing, and record exactly one task
pointing at `speckit.rollout.connect` (Feature 011, out of scope here) in
place of provider actions. This is the first doctrine feature that performs
actual provider tool execution rather than authoring artifact content only.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/brief-implement.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-specify.md`, `brief-clarify.md`, `brief-plan.md`,
`brief-tasks.md`, `brief-analyze.md`, `brief-checklist.md`, and
`connect.md`.

**Primary Dependencies**: None new. Consumes (but does not modify) the
existing `## Delivery Considerations` / `Candidate flag(s):` marker contract
(`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md`,
implemented by `scripts/bash/rollout-gate.sh` /
`scripts/powershell/rollout-gate.ps1`), the `## Delivery Strategy` section
doctrine in `commands/brief-plan.md` (Feature 006), the six rollout-task-
category doctrine in `commands/brief-tasks.md` (Feature 007), the pinned
`mcp.*` block shape in `rollout-config.template.yml` (Feature 002's schema,
still placeholder values per Feature 011's scope), the MCP discovery
operations (`tools/list`, `resources/list`, `prompts/list`) as a standard
MCP client capability (no new library — assumed available to the executing
agent), and the `speckit.rollout.connect` command name (`commands/connect.md`,
Feature 011, currently a placeholder body but a valid registered command to
reference).

**Storage**: N/A — no data is persisted by this feature's own deliverable.
Downstream effects (a flag created in LaunchDarkly, a plan-only-mode task
written into the implementation flow) happen when the *executing* agent
follows the doctrine, not as part of this feature's own artifacts.

**Testing**: Manual/scripted verification per quickstart.md: walk through the
four user stories (full chain + reachable MCP → introspection + bound
intents + executed actions with plan/tasks-sourced parameters; guardrails →
no production-exposure advance beyond spec, no token in any output; no
marker → single-line no-op; marker + tasks present but MCP unreachable →
plan-only mode + exactly one `speckit.rollout.connect` task) using the
doctrine text as the acting agent's instructions, confirming outcomes match
each story's acceptance scenarios. Run `scripts/bash/rollout-gate.sh` against
fixture feature directories before/after to confirm `hasFlags`/`flags`
parity, mirroring 004-008's verification pattern. No live LaunchDarkly MCP
server or real token is used in verification (per Constitution Principle V);
MCP reachability/unreachability is verified by doctrine-text read-through and
by reasoning about the instructed branches, consistent with 004-008's
"proxy-check" pattern for content-only features. No automated test framework
is introduced (consistent with 001-009 precedent).

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs Spec Kit's `/speckit.implement` command and by that agent's MCP
client; no platform-specific behavior is introduced by this feature.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text injected into agent
context per `/speckit.implement` invocation; not performance-sensitive.

**Constraints**: MUST invoke the gate script's default mode (spec.md-only
check) before any rollout behavior (FR-001). MUST treat `hasFlags=false`
(including the diagnostic exit code) as one-line no-op with zero MCP
introspection or provider action (FR-002). MUST check `tasks.md` for rollout
task presence (Feature 007 categories) before any MCP introspection when the
marker is present (FR-003), and MUST emit a distinct status message + zero
fabrication when rollout tasks are absent (FR-004). MUST instruct using
exactly the pinned, configured LaunchDarkly MCP server reference, never an
alternative (FR-005, Constitution Principle IV). MUST instruct runtime
introspection (`tools/list`, `resources/list`, `prompts/list`) before binding
or invoking any tool (FR-006). MUST define and bind exactly the seven named
provider-neutral intents (FR-007). MUST source execution parameters (flag
name, environments, targeting, percentages) from `plan.md`'s Delivery
Strategy and `tasks.md`'s rollout tasks only, never invented or re-derived
from `spec.md` alone (FR-008, Constitution Principle III). MUST instruct
never advancing live production exposure beyond current task/plan scope
absent explicit current user instruction (FR-009, Constitution Principle
VI — NON-NEGOTIABLE). MUST instruct never reading/echoing/logging/inlining
the provider token, and the doctrine text itself MUST NOT reference a token
value (FR-010, Constitution Principle V). MUST NOT include MCP
registration/setup instructions beyond naming `speckit.rollout.connect` as
the plan-only-mode remediation (FR-012, out of scope reserved for Feature
011). MUST instruct skipping only the affected intent(s) when the MCP
doesn't advertise a tool for one, continuing with the rest (FR-013). MUST
NOT modify `extension.yml`, the gate scripts, `rollout-config.template.yml`,
or any other `brief-*.md` command (spec.md Assumptions).

**Scale/Scope**: One file rewritten (`commands/brief-implement.md`,
replacing its placeholder body with the full doctrine), larger than
Features 004-009's single-file rewrites (~250-350 lines) since it is the
first doctrine covering MCP introspection, tool binding for seven intents,
guardrail enforcement, and graceful degradation in one file. No other files
are touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles. This plan is checked against each:

- **I. Additive-Only Extension**: PASS — this feature only rewrites
  `commands/brief-implement.md`'s body (a `brief-*` command file already
  wired to the `before_implement` hook in `extension.yml`), touches no core
  Spec Kit template.
- **II. Self-Gating, Near-Zero Noise**: PASS — FR-001/FR-002 require
  invoking the shared gate script first and emitting a one-line no-op with
  zero MCP introspection or provider action when no marker is found (Story
  3), matching the pattern established in 003-009.
- **III. Strict Content Lineage**: PASS — FR-008 requires sourcing all
  execution parameters from `plan.md`'s Delivery Strategy and `tasks.md`'s
  rollout tasks only, never re-derived from `spec.md`'s marker alone;
  FR-003/FR-004 add the second-stage tasks.md gate (mirroring 007/008) so
  no provider action is attempted before rollout tasks actually exist. No
  marker back-fill occurs in this feature (that's Feature 006's job), so the
  v1.1.0 carve-out does not apply here.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — this is the
  first feature to author actual provider-execution doctrine, and it is
  the direct implementation of this principle: FR-006/FR-007 require
  runtime introspection (`tools/list`/`resources/list`/`prompts/list`) and
  binding seven provider-neutral intents to whatever tools are actually
  advertised, never a hardcoded per-provider wrapper; FR-005 requires using
  only the pinned, configured MCP server reference, never a substitute.
- **V. Credential Security Is Non-Negotiable**: PASS — FR-010 requires the
  doctrine to instruct never reading/echoing/logging/inlining the token,
  and the doctrine's own text must never reference a token value; this
  feature introduces no new credential-handling code (the token is consumed
  solely by the MCP server process, per vision.md §8, unchanged by this
  feature).
- **VI. Guardrailed Provider Execution (NON-NEGOTIABLE)**: PASS — FR-009
  directly implements this principle's production-exposure guardrail
  (auto-advance forbidden absent explicit current instruction); FR-011
  implements the graceful-degradation requirement (plan-only mode + single
  setup task, never a hard failure) when no MCP is reachable.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/010-rollout-implement-doctrine/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

No `contracts/` directory is produced by this feature, for the same reason
as Features 004-009: this feature authors prompt content rather than a new
machine-readable interface. It targets existing contracts/shapes —
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the
gate script's stdout shape, Feature 006's `## Delivery Strategy` section
shape, Feature 007's six rollout-task categories, and the standard MCP
discovery operations (`tools/list`/`resources/list`/`prompts/list`, part of
the MCP spec itself, not something this repo defines) — plus the pinned
`mcp.*` config block already defined by Feature 002's schema in
`rollout-config.template.yml`. data-model.md documents the provider-neutral
intent, pinned MCP server reference, rollout task, and plan-only-mode task
entities this feature's doctrine operates on, and links to all of these.

### Source Code (repository root)

This feature makes a single content change to the existing `rollout`
extension package (repository root, established in 001-extension-skeleton).
No `src/`, `tests/`, or app-style directories are introduced or needed —
there is no code to place in them.

```text
# Single project (Spec Kit extension package layout, extended from 001-008)
commands/
└── brief-implement.md     # MODIFIED: placeholder body replaced with full pre-implement doctrine
```

No changes to `extension.yml`, `scripts/`, `rollout-config.template.yml`,
`commands/brief-specify.md`, `commands/brief-clarify.md`,
`commands/brief-plan.md`, `commands/brief-tasks.md`,
`commands/brief-analyze.md`, `commands/brief-checklist.md`, or
`commands/connect.md` are made by this feature (spec.md Assumptions). The
`before_implement` hook wiring in `extension.yml` already targets
`commands/brief-implement.md`; only that file's body changes.

**Structure Decision**: Same single-project, package-at-repo-root layout as
001-009. This feature adds no new directories or files beyond rewriting the
one existing placeholder command file.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — this section is not applicable.
