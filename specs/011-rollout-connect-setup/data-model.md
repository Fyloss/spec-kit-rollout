# Phase 1 Data Model: Rollout Connect Setup Command

This feature authors doctrine content (`commands/connect.md`), not
application code — there is no new persisted schema owned by this repo. The
entities below are the conceptual objects the doctrine instructs the acting
agent to read, construct, and write at runtime, per research.md's grounded
findings.

## Entity: Client Integration Adapter

One row of the per-integration mapping the doctrine maintains (FR-002),
associating a Spec Kit client integration with how (and whether) to write
its MCP configuration.

| Field | Description |
|---|---|
| `integration_key` | The exact value Spec Kit's `.specify/integration.json` `integration` field uses for this client (e.g. `copilot`, `claude`, `cursor_agent`, `codex`, `gemini`, `cline`) |
| `mcp_config_path` | Project-relative path to the client's MCP configuration file (e.g. `.vscode/mcp.json`), or absent if `supports_project_scope` is false |
| `format` | `json` or `toml` |
| `server_map_key` | The top-level (or nested-table, for TOML) key under which individual server entries live: `servers` (Copilot), `mcpServers` (Claude Code, Cursor, Gemini CLI), `mcp_servers` (Codex TOML table) |
| `supports_project_scope` | Boolean — whether this client has any project-scoped MCP configuration mechanism at all (`false` for Cline per research.md Decision 3) |
| `env_var_reference_syntax` | How to render a reference to an environment variable's *name* (never its value) inside this format, e.g. `${env:VAR_NAME}` (Copilot, Cursor), `${VAR_NAME}` (Claude Code, Gemini CLI), `env_vars = ["VAR_NAME"]` (Codex) |
| `fallback_reason` | Set only when `supports_project_scope` is false, or the integration is entirely absent from Spec Kit's catalog: distinguishes "integrated but no project-scoped MCP surface" (Cline) from "not a recognized Spec Kit integration at all" (e.g. Windsurf, per research.md) — both drive the same FR-007 behavior but with different FR-008 reporting text |

**Source of truth**: research.md Decisions 2-3, grounded in the installed
`specify-cli` 0.12.2 `specify_cli/integrations/` modules and each client's
own current MCP documentation.

**Extensibility constraint (FR-002)**: adding a new client is adding one row
to this table; the doctrine's detect → look up → write-or-fallback control
flow must not need to change to add a row.

## Entity: Pinned MCP Server Reference

The canonical, non-secret description of the official LaunchDarkly MCP
server, resolved from the project's rollout configuration (Feature 002's
`mcp.*` block in `rollout-config.yml`).

| Field | Description | Written into a client's MCP entry? |
|---|---|---|
| `command` | Launch command for the MCP server process | Yes |
| `args` | Launch arguments | Yes |
| `version` | Version constraint for the pinned server | No — provenance metadata only (research.md Decision 4); consumed by `before_implement` (Feature 010), not by this feature's file-write path |
| `repository` | Source repository URL | No — provenance metadata only, same rationale as `version` |
| `token_env_var` | Name only of the OS environment variable the MCP server process reads at launch | Yes — but only its *name*, rendered via the target adapter's `env_var_reference_syntax`; the value is never read, held, or written by this feature (FR-004, Constitution Principle V) |

**Empty-pin guard (FR-011)**: if `command` (or any field required to form a
usable entry) is empty in the resolved configuration, the doctrine must
report "pin not yet configured" and take neither the write path nor the
snippet path with fabricated values.

## Entity: Written MCP Server Entry

The concrete object/table this feature adds or updates inside a supported
client's MCP configuration file.

| Field | Description |
|---|---|
| `client_config_path` | Resolved from the matched Client Integration Adapter's `mcp_config_path` |
| `server_name` | A fixed, recognizable identifier for the LaunchDarkly entry (e.g. `launchdarkly`) used both to write and, on re-run, to *find* the existing entry for idempotent update (FR-005) |
| `entry_body` | `{command, args, env: {<token_env_var name>: <adapter's env-var-reference-syntax rendering>}}` (or the TOML-table equivalent for Codex, using `env_vars` name-forwarding instead of an `env` value) |
| `sibling_entries_untouched` | Invariant: every other key in the server map, and every other top-level key in the file (e.g. Gemini CLI's `settings.json` has unrelated keys beyond `mcpServers`), must be byte-for-byte unchanged (FR-006) |

**Idempotency rule (FR-005)**: on re-run, the doctrine locates the existing
entry by `server_name` within `server_map_key` and replaces only that one
entry's body if it differs from the newly resolved `entry_body`; it never
appends a second entry under a different name and never rewrites unrelated
entries or file structure.

## Entity: Copy-Paste Fallback Output

What the doctrine instructs printing when the active client's adapter has
`supports_project_scope = false`, or is absent from the mapping entirely
(FR-007).

| Field | Description |
|---|---|
| `snippet` | A complete, correctly formatted example server entry (JSON or a generic/illustrative shape when no client-specific format applies), containing `command`, `args`, and an illustrative env-var-name reference — never a real path this feature attempts to write to disk |
| `env_var_reminder` | The exact name of `mcp.token_env_var`, with a one-line instruction to set it as an OS environment variable before use |
| `detected_reason` | Which of the two fallback triggers applied (per the Client Integration Adapter's `fallback_reason`, or "detection failed" per the spec.md Edge Case) |

**No-file-write invariant**: this path MUST NOT create or modify any file on
disk (FR-007, User Story 2's Independent Test).

## Relationships

```text
.specify/integration.json `integration` field (Spec Kit's own state)
   │  (Decision 1 — detection)
   ▼
Client Integration Adapter lookup (rollout's own mapping — Decision 2/3)
   │
   ├─ no match / supports_project_scope=false ──► Copy-Paste Fallback Output
   │                                               (no file write — FR-007)
   │
   └─ match, supports_project_scope=true
        │
        ▼
Pinned MCP Server Reference resolved from rollout-config.yml `mcp.*`
        │
        ├─ command empty / unusable ──► "pin not yet configured" report (FR-011)
        │
        └─ usable
             │
             ▼
     Existing client MCP config file readable/absent?
        │
        ├─ malformed (parse failure) ──► stop, report, fall back to snippet (FR-010)
        │
        └─ parses OK or absent
             │
             ▼
     Written MCP Server Entry created or updated in place,
     all sibling entries/keys preserved (FR-003/FR-005/FR-006),
     token value never written (FR-004)
             │
             ▼
     Report action taken + client detected (FR-008)
```

## State Transitions

This feature introduces no persisted state machine of its own. Each
`/speckit.rollout.connect` invocation re-evaluates the full path above from
scratch; the only "state" that changes across runs is the target client's
own MCP configuration file, which idempotent re-runs must converge to a
stable single-entry result (FR-005).
