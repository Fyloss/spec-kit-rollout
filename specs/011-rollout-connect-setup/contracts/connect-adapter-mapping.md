# Contract: Client Integration Adapter Mapping (interface owned by `commands/connect.md`)

This feature's external interface is the per-integration adapter mapping
`commands/connect.md` commits to maintaining and the read/write behavior it
performs against a detected client's MCP configuration file. This contract
documents the exact shape and guarantees this feature commits to, grounded in
research.md's Decisions 1-4.

## Detection input contract

`commands/connect.md` MUST read the active integration from the project's
`.specify/integration.json`, specifically its top-level `integration` string
field (schema `integration_state_schema: 1`, as installed by `specify-cli`
0.12.2). It MUST NOT iterate `installed_integrations` to act on more than
one integration in a single run (spec.md Edge Case — multi-integration
projects). If this file is missing, unreadable, or the `integration` field is
absent/empty, detection is considered to have failed and the command MUST
take the copy-paste fallback path (spec.md Edge Case).

## Adapter mapping shape

Each row (see data-model.md's Client Integration Adapter entity) MUST supply:

```text
integration_key            (string, matches Spec Kit's integration.json value)
mcp_config_path             (project-relative path, or absent)
format                       ("json" | "toml")
server_map_key               (string, or dotted table path for TOML)
supports_project_scope       (boolean)
env_var_reference_syntax      (template string containing the token env var's name only)
fallback_reason               (present only when supports_project_scope=false, or omitted from the table entirely for a fully-unmapped client)
```

A new client is added by appending one row; no other part of the doctrine's
control flow may need to change (FR-002).

## Write contract (supported, project-scoped client)

When `supports_project_scope` is true and the resolved Pinned MCP Server
Reference has a non-empty `command`:

1. Read the existing file at `mcp_config_path` if present; parse in the
   adapter's declared `format`.
   - Parse failure → stop, report the problem, take the fallback path
     (FR-010). Do not attempt a partial or best-effort rewrite.
2. Locate an existing entry named `launchdarkly` under `server_map_key`
   (creating `server_map_key` and/or the file itself if entirely absent).
3. Write/replace only that one entry with:
   - `command`: `mcp.command`
   - `args`: `mcp.args`
   - the token env-var's name rendered via `env_var_reference_syntax` (never
     the value) — for JSON-format adapters this is an `env` object entry
     keyed by `mcp.token_env_var`'s name; for the Codex TOML adapter this is
     an `env_vars` array entry containing the name string only.
4. Every other key in `server_map_key`, and every other top-level key in the
   file, MUST be byte-for-byte unchanged (FR-006).
5. `mcp.version` and `mcp.repository` MUST NOT appear anywhere in the
   written file (research.md Decision 4).

Re-running steps 1-5 against a file already containing a correct
`launchdarkly` entry MUST result in no functional change (FR-005) — this is
the idempotency contract. Re-running when the entry has drifted from the
current pin MUST update only that entry's body, never adding a second entry.

## Fallback contract (unmapped, or mapped without project scope, client)

When the detected client's adapter row is absent, or present with
`supports_project_scope = false`:

1. No file on disk is created or modified.
2. The command prints a complete, correctly formatted example server entry
   (using the adapter's `format`/`server_map_key`/`env_var_reference_syntax`
   when a row exists — e.g. Cline's entry still uses `mcpServers` JSON shape
   for the printed example even though no project-scoped file exists to
   write it to — or a generic JSON shape when no row exists at all, e.g. an
   entirely unmapped client) plus the exact `mcp.token_env_var` name and a
   one-line reminder to set it as an OS environment variable.
3. The printed output MUST NOT contain a token value (FR-004 applies to
   output as well as files).

## Empty-pin contract

When `mcp.command` (or another field required to form a usable entry) is
empty in the resolved `rollout-config.yml`, the command MUST report that the
pin is not yet configured and MUST take neither the write path nor the
fallback-snippet path with fabricated placeholder values (FR-011).

## Reporting contract (FR-008)

Every run MUST conclude with a report stating: (a) which client integration
was detected (or that detection failed), and (b) which of the four outcomes
occurred — file written, file updated, snippet printed, or pin-not-configured
reported.

## Consumers of this contract

- `commands/connect.md`'s own doctrine body (this feature's sole
  deliverable) — the contract this file's content must satisfy.
- Any future feature extending the adapter mapping with an additional client
  row must preserve every guarantee above unchanged.

## Non-goals of this contract

- No contract for the full MCP specification or any client's complete
  configuration schema (timeouts, OAuth, sandboxing, etc.) — only the subset
  (`command`, `args`, env-var-name reference) this feature's FR-003/FR-004
  touch (research.md Decision 5).
- No contract for how a future provider (beyond LaunchDarkly) would extend
  this mapping — out of scope per vision.md V1 scope boundaries.
- No automated schema-validation tooling contract — verification is via
  read-through and manual fixture exercises (see quickstart.md), consistent
  with Features 004-010's content-only verification pattern.
