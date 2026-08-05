# Phase 0 Research: Rollout Connect Setup Command

This feature's deliverable is doctrine content (a full rewrite of the
placeholder `commands/connect.md`), not application code — but unlike
Features 004-010, that doctrine must instruct the acting agent through a real,
per-client file-format decision tree, so the research below grounds the
adapter mapping in verified facts about (a) Spec Kit's own integration
mechanism and (b) each target client's actual MCP configuration format,
rather than vision.md's illustrative client list. All findings are copied
into `/memories/repo/spec-kit-extension-schema.md` for reuse by the
implementation phase.

## Decision 1: How the command detects the "active" Spec Kit client integration

**Decision**: Read the `integration` field of the installed project's
`.specify/integration.json` (schema: `integration_state_schema: 1`). This
repo's own file currently reads:

```json
{
  "version": "0.12.2",
  "integration_state_schema": 1,
  "installed_integrations": ["copilot"],
  "integration_settings": {"copilot": {"script": "sh", "invoke_separator": "."}},
  "integration": "copilot",
  "default_integration": "copilot"
}
```

**Rationale**: This is the exact record Spec Kit's own CLI writes and reads
to know which integration is active for the current project — it is Spec
Kit's own integration catalog state, not a rollout-specific invention, so it
directly satisfies FR-001 ("derive from Spec Kit's own integration catalog").
`installed_integrations` additionally supports the multi-integration edge
case (spec.md Edge Cases): if more than one integration is installed, the
command still acts only on the single `integration` (active) value, never
iterating `installed_integrations`.

**Alternatives considered**:
- Re-detecting the client from environment/process heuristics (e.g., which
  CLI invoked the command) — rejected: fragile, and Spec Kit already
  persists this exact state; duplicating detection would drift from Spec
  Kit's own source of truth.
- Reading `specify_cli.integrations.catalog` (the remote/community catalog
  fetcher) — rejected: that module resolves *installable* integrations from
  a remote catalog URL, not the *active* one for the current project; wrong
  layer entirely (confirmed by reading
  `specify_cli/integrations/catalog.py` in the installed 0.12.2 package).

## Decision 2: Spec Kit's integration modules carry no MCP information — rollout must own its own adapter mapping

**Decision**: The `rollout` extension maintains and ships its own
client-adapter mapping (client key → MCP config file path, format, and
whether project-scoped MCP config is supported at all). This mapping is
wholly separate from, and not derivable from, Spec Kit's integration
modules.

**Rationale**: Ground-truthed by reading every module under
`specify_cli/integrations/` in the installed `specify-cli` 0.12.2 package
(30+ modules: `copilot`, `claude`, `cline`, `cursor_agent`, `codex`,
`gemini`, `zed`, `goose`, `devin`, etc., plus `base.py`, `catalog.py`,
`manifest.py`). Every module's `IntegrationBase` subclass concerns itself
exclusively with **slash-command / agent registration** (command directory
layout, invoke separator, whether commands render as Markdown or TOML
*command* files, skills-mode) — none references an MCP configuration file
path, key, or format anywhere. This confirms FR-002's requirement is
necessary, not redundant with Spec Kit: Spec Kit's "integration catalog"
answers "which client, and how do I register commands for it," never "where
does this client's MCP config live."

**Alternatives considered**: Waiting for/depending on a future Spec Kit
core feature to expose MCP paths per integration — rejected: no such
mechanism exists in the installed CLI today (spec.md must not assume
unreleased core behavior); the extension's own mapping can be extended
independently of Spec Kit core release cadence, satisfying FR-002's
"extend without changing core logic" requirement today.

## Decision 3: Per-client MCP configuration formats (adapter mapping content)

Grounded against each client's own current official documentation (not
vision.md's illustrative list, which is aspirational per FR-001's wording).

| Client (Spec Kit integration key) | Project-scoped MCP config path | Format | Server map key | Per-server shape | Env-var-by-name syntax |
|---|---|---|---|---|---|
| `copilot` (GitHub Copilot / VS Code) | `.vscode/mcp.json` | JSON | `servers` | `{"type": "stdio", "command", "args", "env"}` | `"${env:VAR_NAME}"` inside `env` values, or via the `inputs` prompt mechanism (extension uses the plain `env` form since the value is a var name reference, not a secret prompt) |
| `claude` (Claude Code) | `.mcp.json` (project root) | JSON | `mcpServers` | `{"command", "args", "env"}` | `"${VAR_NAME}"` or `"${VAR_NAME:-default}"` inside `env`/`command`/`args`/`url`/`headers` values |
| `cursor_agent` (Cursor) | `.cursor/mcp.json` | JSON | `mcpServers` | `{"command", "args", "env"}` | `"${env:VAR_NAME}"` inside `env`/`args`/`url`/`headers` values (Cursor's own config-interpolation syntax) |
| `codex` (OpenAI Codex CLI/IDE) | `.codex/config.toml` (trusted projects only) | TOML | `mcp_servers` table (`[mcp_servers.<name>]`) | `command`, `args`, `env` (literal values), plus `env_vars` (array of variable *names* to forward from the local environment, or `{name, source}` objects) | `env_vars = ["VAR_NAME"]` — the name-only forwarding form is the exact fit for "reference the token via its env-var NAME only" |
| `gemini` (Gemini CLI) | `.gemini/settings.json` (project scope; `-s project` is `gemini mcp`'s default) | JSON | `mcpServers` (one object among other keys already in `settings.json`) | `{"command", "args", "env", "cwd", ...}` | `"$VAR_NAME"` or `"${VAR_NAME}"` inside `env` values |
| `cline` (Cline) | No documented project-scoped location — Cline's own docs (`docs.cline.bot/mcp/configuring-mcp-servers`) describe only a CLI-global `~/.cline/mcp.json` and an IDE-global "MCP settings JSON" reachable via the extension's own panel; neither is project-scoped | N/A | N/A | N/A | N/A → **mapped as lacking project-scoped MCP configuration** (FR-007 fallback path), not merely "unmapped" |
| Windsurf | No `specify_cli/integrations/` module exists for "windsurf" in the installed 0.12.2 package at all (confirmed by directory listing — only an unrelated string hit elsewhere, no `windsurf/__init__.py`) | N/A | N/A | N/A | N/A → **absent from Spec Kit's own integration catalog** (the other FR-007 fallback trigger) — vision.md's client list is illustrative/aspirational, not a confirmed-integration guarantee |

**Rationale for including both Cline and Windsurf as distinct fallback
reasons**: spec.md's FR-007 and Edge Cases distinguish two different
fallback triggers — "absent from the adapter mapping" vs. "present but
marked as lacking project-scoped MCP configuration support." Cline
demonstrates the second (Spec Kit does integrate it for commands, but no
project-scoped MCP location exists to target); Windsurf demonstrates the
first (no Spec Kit integration module at all in the installed CLI, so
detection itself would never resolve to it via Decision 1's mechanism).
Both still produce the same user-visible behavior (copy-paste snippet
path), so the mapping only needs to record *which* reason applies for
accurate FR-008 reporting, not different remediation logic.

**Alternatives considered**: Treating every unlisted/no-project-scope
client identically with a single generic reason string — rejected: FR-008
requires reporting "which client integration it detected," and a future
maintainer extending the table benefits from the mapping itself recording
*why* a client is a fallback case (never integrated vs. integrated but no
MCP surface), even though the runtime behavior converges.

## Decision 4: Which pinned-spec fields are actually written into a client's MCP entry

**Decision**: Only `mcp.command`, `mcp.args`, and a reference to
`mcp.token_env_var`'s *name* (rendered in that client's own interpolation
syntax from Decision 3) are written into a client's MCP server entry.
`mcp.version` and `mcp.repository` (Feature 002's schema) are **not** written
into any client config file — no client's MCP entry format (VS Code,
Claude Code, Cursor, Codex, Gemini CLI) has a field for an upstream version
constraint or source repository URL.

**Rationale**: Every format researched in Decision 3 supports only
transport/launch fields (`command`/`args`/`env`/`url`/`headers`) — none
supports arbitrary provenance metadata. `version`/`repository` remain
supply-chain-safety metadata consumed by the *other* pinned-reference
consumer (`before_implement` doctrine, Feature 010, which instructs the
agent never to substitute a different server) rather than by `connect`'s
file-write path. The copy-paste snippet path (FR-007) MAY still mention
`version`/`repository` as informational text alongside the snippet (not
inside the snippet's own JSON/TOML), since the fallback path has no file
format constraint to honor.

**Alternatives considered**: Writing `version`/`repository` as a comment
adjacent to the JSON/TOML entry — rejected for the JSON targets (Copilot,
Claude Code, Cursor, Gemini CLI): standard JSON has no comment syntax, and
inventing a `"_comment"` sibling key inside the server object risks being
interpreted as a real (unknown) config field by the client. TOML (Codex)
does support `#` comments, but keeping the rule uniform across all mapped
clients (no provenance text inside any written file) is simpler and avoids
a per-format special case in the doctrine.

## Decision 5: No `contracts/` duplication of MCP config formats already owned upstream

**Decision**: `contracts/connect-adapter-mapping.md` documents the shape of
the *rollout extension's own* adapter-mapping table (Decision 3's columns)
and the write/detect/fallback contract `commands/connect.md` commits to. It
does not attempt to restate the full MCP specification or each client's
complete config schema (timeouts, OAuth, sandboxing, etc.) — only the
subset (`command`, `args`, env-var-name reference) this feature's FR-003/
FR-004 actually touch.

**Rationale**: Consistent with Features 001-002's contract style (documents
this feature's own commitment, not a third-party spec) and keeps the
contract from silently going stale as clients add unrelated features (e.g.
Claude Code's OAuth scopes, Cursor's sandboxing) that this feature never
writes.

## Decision 6: Detecting a malformed existing MCP config file without a full parser-per-format contract

**Decision**: The doctrine instructs the agent to attempt to parse the
existing file in its expected format (JSON for Copilot/Claude
Code/Cursor/Gemini CLI, TOML for Codex) using whatever parsing capability is
already available to it, and to treat any parse failure as the FR-010
"malformed" case (stop, report, fall back to snippet) — never a bespoke
malformed-detection algorithm specified by this feature. This mirrors
Features 004-010's pattern of instructing an outcome without inventing a new
parsing contract this repo would need to maintain.

**Rationale**: A hand-specified malformed-JSON/TOML detector would be a
second, drifting source of truth against standard JSON/TOML grammars;
"attempt standard parse, treat failure as malformed" is unambiguous and
needs no contract of its own.

## Summary of resolved unknowns

No `NEEDS CLARIFICATION` markers existed in spec.md (confirmed at
`/speckit.specify` time). This research phase's job was to replace
vision.md's illustrative client examples and unresolved "how do I know the
active client / where do MCP files live" questions with verified facts
before Phase 1 design — all now resolved per Decisions 1-6 above.
