# Quickstart: Verifying the Rollout Connect Setup Command

This guide walks through validating `commands/connect.md` against the three
user stories in spec.md, using fixture files and text-based read-throughs
rather than a real MCP server connection or a real LaunchDarkly token
(consistent with Constitution Principle V and Features 004-010's
verification approach).

## Prerequisites

- Repository checked out locally with `commands/connect.md` rewritten per
  this feature's tasks.md.
- A scratch working directory (not committed) to simulate a target project,
  since this repo's own `.specify/integration.json` should not be modified
  by verification.
- No git commits are required to exist in this repo (working tree only,
  consistent with prior features' notes).

## Scenario 1 — Supported client, no prior MCP config (User Story 1, P1)

**Setup**: In a scratch directory, create:
- `.specify/integration.json` with `{"integration": "cursor_agent"}`.
- `.specify/extensions/rollout/rollout-config.yml` with a fully populated
  `mcp:` block (`command`, `args`, `version`, `repository`, `token_env_var`)
  per Feature 002's schema.
- No `.cursor/mcp.json` file.

**Read-through check**: Confirm `commands/connect.md` instructs, in order:
(1) read `.specify/integration.json`'s `integration` field; (2) look up
`cursor_agent` in the adapter mapping and find `supports_project_scope: true`,
`.cursor/mcp.json`, `mcpServers` key; (3) since no file exists, create
`.cursor/mcp.json` with a `mcpServers.launchdarkly` entry containing
`command`, `args`, and an `env` entry referencing `token_env_var`'s name via
`${env:VAR_NAME}` syntax — no token value anywhere.

**Expected outcome description in the doctrine**: the command reports the
file path written and the detected client (`cursor_agent`).

## Scenario 2 — Existing unrelated entries preserved (User Story 1 continued)

**Setup**: Same as Scenario 1, but pre-populate `.cursor/mcp.json` with one
unrelated server entry (e.g. `"playwright": {...}`) before running.

**Read-through check**: Confirm the doctrine instructs adding the
`launchdarkly` entry alongside `playwright`, never removing or rewriting the
existing entry, and never rewriting other top-level file structure.

## Scenario 3 — Idempotent re-run (User Story 3, P1)

**Setup**: Reuse Scenario 2's resulting file (now containing both
`playwright` and `launchdarkly`).

**Read-through check**: Confirm the doctrine instructs, on a second run:
(1) detect the same client; (2) locate the existing `launchdarkly` entry by
name under `mcpServers`; (3) compare its body to the freshly resolved pin;
(4) if identical, leave the file unchanged; if drifted (e.g. simulate by
hand-editing `command` to a stale value first), update only that one entry's
body in place — no second `launchdarkly` entry is ever created, and
`playwright` remains untouched.

## Scenario 4 — Unmapped / no-project-scope client fallback (User Story 2, P2)

**Setup**: Change `.specify/integration.json`'s `integration` to `cline`.

**Read-through check**: Confirm the doctrine's adapter-lookup step finds
`cline` mapped with `supports_project_scope: false` (research.md Decision 3),
takes the fallback path, and:
1. Creates or modifies no file.
2. Prints a complete `mcpServers`-shaped JSON snippet (Cline's own format)
   containing `command`, `args`, and an illustrative env-var-name reference.
3. Prints the exact `token_env_var` name plus a one-line reminder to set it
   as an OS environment variable.
4. Contains no token value anywhere in the printed output.

**Repeat** with `integration` set to a value absent from the mapping
entirely (e.g. `windsurf`, per research.md Decision 3) and confirm the same
four checks hold, with reporting text distinguishing "not a recognized
adapter" from Cline's "recognized but no project-scoped MCP config" case
(FR-008).

## Scenario 5 — Malformed existing config (Edge Case)

**Setup**: Reuse Scenario 1's setup, but pre-populate `.cursor/mcp.json`
with invalid JSON (e.g. a trailing comma or unclosed brace).

**Read-through check**: Confirm the doctrine instructs attempting a standard
JSON parse, treating the failure as the malformed case: stop, report the
problem, and fall back to printing the copy-paste snippet — never attempting
to blindly overwrite or auto-repair the file (FR-010).

## Scenario 6 — Empty/unconfigured pin (Edge Case)

**Setup**: Reuse Scenario 1's setup, but leave `mcp.command` empty in
`rollout-config.yml`.

**Read-through check**: Confirm the doctrine instructs reporting that the
pin is not yet configured, taking neither the write path nor the
fallback-snippet path with fabricated values (FR-011).

## Scenario 7 — Detection failure (Edge Case)

**Setup**: Remove `.specify/integration.json` entirely (or leave its
`integration` field empty).

**Read-through check**: Confirm the doctrine instructs reporting that
detection failed and falling back to the copy-paste snippet path rather than
guessing a client.

## Scenario 8 — Multi-integration project (Edge Case)

**Setup**: In `.specify/integration.json`, set `installed_integrations` to
two or more entries (e.g. `["copilot", "cursor_agent"]`) while `integration`
names only one of them (e.g. `"cursor_agent"`).

**Read-through check**: Confirm the doctrine instructs detection to read
only the `integration` field's single value and act exclusively on that one
client, never iterating or acting on any other entry present in
`installed_integrations` (spec.md Edge Case — multi-integration project;
research.md Decision 1).

## Cleanup

Delete the scratch working directory created for this verification — none
of its contents are committed to this repository.

## Cross-cutting checks

```bash
# Confirm no example/placeholder token value ever appears
grep -in "api[_-]key\|token" commands/connect.md | grep -v "token_env_var\|token env\|env-var\|env var\|environment variable\|token value"

# Confirm the adapter mapping table covers at least the FR-001 minimum client set
grep -in "copilot\|claude\|cline\|cursor\|windsurf\|gemini\|codex" commands/connect.md

# Confirm idempotency and no-overwrite language is present
grep -in "idempotent\|preserve\|untouched" commands/connect.md

# Confirm explicit non-action guarantees are present (FR-009)
grep -in "never launch\|never connect\|never start\|never prompt\|never read\|never store" commands/connect.md
```

All four checks are expected to return at least one match each (the first
is expected to return **zero** matches once the trailing `grep -v` filter is
applied — i.e., every "token" mention is about handling the name/reference,
never a literal secret value).
