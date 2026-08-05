# Implementation Plan: Rollout Connect Setup Command

**Branch**: `011-rollout-connect-setup` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-rollout-connect-setup/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace the placeholder body of `commands/connect.md` (the
`speckit.rollout.connect` **user-invoked, one-time** setup command — not a
`before_*` hook briefing, unlike Features 004-010) with doctrine that: (1)
detects the active Spec Kit client integration by reading
`.specify/integration.json`'s `integration` field — Spec Kit's own
integration-state record, ground-truthed against the installed
`specify-cli` 0.12.2 source, whose integration modules carry no MCP
information at all; (2) looks up that client in a per-integration adapter
mapping this feature defines and maintains (client → MCP config path,
format, project-scope support, env-var reference syntax), grounded in each
client's own current MCP documentation (VS Code/Copilot `.vscode/mcp.json`,
Claude Code `.mcp.json`, Cursor `.cursor/mcp.json`, Codex
`.codex/config.toml`, Gemini CLI `.gemini/settings.json`; Cline and
unmapped/unintegrated clients such as Windsurf fall to the copy-paste
path); (3) for a mapped, project-scoped client, writes or idempotently
updates a single `launchdarkly`-named MCP server entry built from
`rollout-config.yml`'s `mcp.*` pin (Feature 002), referencing the token only
by its environment-variable name, while preserving every other entry and
file structure untouched; (4) for an unmapped or no-project-scope client,
prints a ready-to-paste snippet plus the env-var name reminder without
touching any file; (5) reports the detected client and the action taken
every run; (6) never overwrites a malformed existing config file, and never
fabricates a server entry when the resolved pin is empty. This is the first
feature to author a real per-client adapter mapping (not pure spec/plan/
tasks-lineage doctrine) and the first non-hook, user-invoked command
doctrine in this repository.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in `commands/connect.md`, following the same
YAML-frontmatter + Markdown-body command format already used by
`commands/brief-specify.md` through `brief-implement.md`.

**Primary Dependencies**: None new. Consumes (but does not modify) the
`mcp.*` block shape in `rollout-config.template.yml` (Feature 002's schema);
Spec Kit's own `.specify/integration.json` state file (ground-truthed
against the installed `specify-cli` 0.12.2 `specify_cli/integrations/`
package — confirmed to carry zero MCP-related fields in any of its 30+
integration modules); and each target client's own MCP configuration format
(VS Code `.vscode/mcp.json`, Claude Code `.mcp.json`, Cursor
`.cursor/mcp.json`, Codex `.codex/config.toml`, Gemini CLI
`.gemini/settings.json`), documented as external, versioned facts in
research.md rather than as a library this repo imports.

**Storage**: N/A — no data is persisted by this feature's own deliverable.
The downstream effect (a client's MCP configuration file being written or
updated) happens when the *executing* agent follows the doctrine in a
target project, not as part of this feature's own artifacts.

**Testing**: Manual/scripted verification per quickstart.md: walk through
the three user stories (supported-client write path incl. preserving
unrelated entries; unmapped/no-project-scope fallback snippet; idempotent
re-run and drift-correction) plus four edge cases (malformed existing
config, empty/unconfigured pin, detection failure, multi-integration
project) using the doctrine text as the acting agent's instructions and
scratch fixture directories/files (not committed), confirming outcomes match
each story's acceptance scenarios. No live client application, no real MCP
server, and no real LaunchDarkly token is used in verification (Constitution
Principle V), consistent with Features 004-010's proxy-check pattern for
content-only features.

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs `/speckit.rollout.connect` inside a project already using one of
Spec Kit's client integrations; no platform-specific behavior (Windows vs.
POSIX paths) is introduced beyond instructing the agent to use
project-relative paths as documented per client.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — one-time doctrine text followed once per
project setup (or occasional re-run), not performance-sensitive.

**Constraints**: MUST derive the active client from Spec Kit's own
integration-catalog state, never a rollout-specific hardcoded detection
(FR-001). MUST maintain the adapter mapping so a new client is one added row,
no control-flow change (FR-002). MUST write only `command`/`args`/env-var-
*name* into a supported client's entry, per that client's own format
(FR-003) — never `mcp.version`/`mcp.repository` (research.md Decision 4).
MUST NEVER write a token value anywhere, file or output (FR-004). MUST
converge to exactly one `launchdarkly`-named entry across any number of
re-runs (FR-005). MUST leave every other entry and file key untouched
(FR-006). MUST take the print-only fallback path, with zero file writes, for
an unmapped or no-project-scope client (FR-007). MUST report the detected
client and action taken every run (FR-008). MUST NOT launch, connect to, or
start the MCP server, and MUST NOT prompt for/read/store a token value
(FR-009). MUST NOT overwrite a malformed existing config file — stop, report,
fall back to snippet (FR-010). MUST NOT fabricate a server entry from an
empty/unusable pin (FR-011). MUST act only on the single active integration
in a multi-integration project, never iterating every installed integration
(spec.md Edge Case). MUST NOT modify `extension.yml`, `rollout-config.
template.yml`, any `brief-*.md` command, or the gate scripts (implied scope
boundary, consistent with Features 004-010's "single file" pattern).

**Scale/Scope**: One file rewritten (`commands/connect.md`, replacing its
5-line placeholder body with full detection + adapter-mapping + write/
fallback doctrine), plus this feature's own `contracts/` addition (new for
this feature — Features 004-010 had none, since this is the first feature
whose external interface is a real mapping/write contract rather than pure
artifact-lineage doctrine). No other files are touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v1.1.0 is ratified (2026-07-08) with six
Core Principles plus Scope Constraints. This plan is checked against each:

- **I. Additive-Only Extension**: PASS — this feature only rewrites
  `commands/connect.md` (a command file already declared in `extension.yml`
  under `provides.commands`), touches no core Spec Kit template. It reads
  Spec Kit's `.specify/integration.json` state but never writes to it.
- **II. Self-Gating, Near-Zero Noise**: N/A by design — `connect` is a
  user-invoked, one-time setup command, not a `before_*` hook briefing, so
  the marker-based self-gating pattern (Features 004-010) does not apply;
  vision.md §7 and the Scope Constraints section explicitly treat `connect`
  as distinct from the seven self-gating hooks. Running it is itself the
  user's explicit signal, so no additional gate is required or appropriate.
- **III. Strict Content Lineage**: PASS — this feature does not read or
  derive anything from `spec.md`/`plan.md`/`tasks.md`'s rollout-lineage
  chain at all; its only "content sources" are `rollout-config.yml`'s
  `mcp.*` pin (Feature 002) and Spec Kit's own integration state, neither of
  which is part of the spec→plan→tasks→implement lineage this principle
  governs. Not applicable/no conflict.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — this feature
  registers the connection to *exactly* the pinned official LaunchDarkly MCP
  server resolved from config (`mcp.command`/`mcp.args`), never a
  substitute, and performs no capability-wrapper or per-provider API logic;
  it is pure client-side MCP *registration*, not tool binding (that's
  Feature 010's job).
- **V. Credential Security Is Non-Negotiable**: PASS — this is the principle
  most directly exercised by this feature: FR-004/FR-009 require the token
  value is never read, prompted for, stored, or written anywhere (file or
  printed output); only `mcp.token_env_var`'s *name* is ever referenced, and
  research.md Decision 4 explicitly confirms no pinned field beyond
  command/args/env-var-name is ever written into any client config.
- **VI. Guardrailed Provider Execution (NON-NEGOTIABLE)**: N/A — this
  principle governs live provider-execution guardrails during
  `/speckit.implement` (Feature 010); `connect` never launches, connects to,
  or executes any provider/MCP action (FR-009), so this principle's
  guardrails do not apply to this feature's behavior, though FR-009 is
  fully consistent with its spirit.
- **Scope Constraints** (explicitly names `speckit.rollout.connect`): PASS —
  "MUST remain idempotent" is FR-005; "MUST NEVER write a secret value to
  any file it generates or updates" is FR-004; both are first-class,
  independently testable requirements in spec.md, not bundled or diluted.

No unresolved violations remain; no entries are required in Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/011-rollout-connect-setup/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md         # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── connect-adapter-mapping.md  # Phase 1 output — new for this feature
├── checklists/
│   └── requirements.md  # Already produced by /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

Unlike Features 004-010 (which deliberately had **no** `contracts/`
directory, reusing Feature 003's gate contract since they authored pure
artifact-lineage doctrine), this feature **does** add a `contracts/`
directory: its external interface — a client-adapter mapping plus a
write/fallback contract for MCP configuration files — is new, real, and not
already documented by any prior feature's contract (research.md Decision 5
explains why this doesn't duplicate the MCP spec itself or each client's
full config schema, only the narrow slice this feature writes).

### Source Code (repository root)

No new source tree. This feature's only deliverable is a content rewrite of
the existing `commands/connect.md` file, following the established
YAML-frontmatter + Markdown-body command format:

```text
commands/
└── connect.md            # Rewritten by this feature (was a placeholder)
```

**Structure Decision**: Single project, content-only. This matches
Features 004-010's precedent (each rewrote exactly one `commands/*.md` file)
with one structural addition — a `contracts/` directory — justified above
because this feature's interface commitment (the adapter mapping) is new
rather than a reuse of an existing contract.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations — table intentionally omitted.
