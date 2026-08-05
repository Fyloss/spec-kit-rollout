---
description: "rollout: one-time MCP setup command — detects the active Spec Kit integration and writes the pinned LaunchDarkly MCP server registration to the client's MCP configuration file, or prints a copy-paste snippet if the client is unmapped or lacks project scope"
visibility: "public"
mode: "user-invoked"
---

# `speckit.rollout.connect`

**Role**: One-time setup command that detects the active Spec Kit client integration (Copilot, Claude Code, Cline, Cursor, Windsurf, Gemini CLI, Codex, etc.), looks it up in a per-client adapter mapping, and either:
1. Writes the pinned LaunchDarkly MCP server registration to that client's MCP configuration file (if supported), or
2. Prints a ready-to-paste copy-paste snippet (if the client is unmapped or lacks project-scoped MCP configuration).

The command never writes the credential value — only the environment-variable name — and is fully idempotent: re-running it against the same client results in zero functional change if the entry is already correct.

**User Stories Implemented**:
- **US1 (P1)**: Detect a supported client integration and write its MCP configuration file with the pinned LaunchDarkly MCP server entry.
- **US2 (P2)**: For unmapped or config-less clients, print a ready-to-paste snippet instead of writing any file.
- **US3 (P1)**: Ensure idempotent re-runs preserve existing configuration and update only the LaunchDarkly entry if it has drifted.

---

## Foundational Infrastructure

### Client Detection

The command detects which Spec Kit client integration is active in the current project by reading the project's `.specify/integration.json` file and extracting the `integration` string field. This file is written and maintained by Spec Kit itself (`specify-cli` 0.12.2+) and serves as the single source of truth for the active integration state.

**Detection Algorithm**:
1. Attempt to read `.specify/integration.json` from the project root.
2. Extract the top-level `integration` field (e.g., `"copilot"`, `"cursor_agent"`, `"cline"`).
3. If the file is missing, unreadable, or the `integration` field is absent or empty, detection has failed — report detection failure and fall back to the copy-paste path (see "Unmapped/No-Project-Scope Fallback Path" section).
4. If detection succeeds, the integration key is now known. Proceed to the adapter mapping lookup.

**Invariant for multi-integration projects**: If `.specify/integration.json` contains more than one entry in `installed_integrations`, the command MUST act only on the single `integration` field value, never iterating or acting on any other installed integration.

**Error handling**: If `.specify/integration.json` cannot be parsed as JSON (or its equivalent representation in the project's format), report "detection failed" and proceed to the fallback path. Do not attempt error recovery or guessing.

### Client Integration Adapter Mapping

The adapter mapping is a lookup table that associates each Spec Kit client integration with metadata needed to write its MCP configuration file. Each client is one row in this mapping; extending coverage to a new client is adding one row and changing no control-flow logic.

**Adapter Mapping Table**:

| integration_key | mcp_config_path | format | server_map_key | supports_project_scope | env_var_reference_syntax | fallback_reason |
|---|---|---|---|---|---|---|
| `copilot` | `.vscode/mcp.json` | json | `servers` | true | `${env:VAR_NAME}` | *(n/a)* |
| `claude` | `.mcp.json` | json | `mcpServers` | true | `${VAR_NAME}` | *(n/a)* |
| `cursor_agent` | `.cursor/mcp.json` | json | `mcpServers` | true | `${env:VAR_NAME}` | *(n/a)* |
| `codex` | `.codex/config.toml` | toml | `mcp_servers` | true | `env_vars = ["VAR_NAME"]` | *(n/a)* |
| `gemini` | `.gemini/settings.json` | json | `mcpServers` | true | `${VAR_NAME}` | *(n/a)* |
| `cline` | *(n/a)* | json | `mcpServers` | false | `${env:VAR_NAME}` | `Recognized integration; no project-scoped MCP configuration support` |
| *(unmapped)* | *(n/a)* | json | `mcpServers` | *(n/a)* | `${VAR_NAME}` | `Client integration not in Spec Kit's catalog` |

**Adapter Lookup Algorithm**:
1. Search the adapter mapping table for a row matching the detected `integration_key`.
2. If a row is found:
   - If `supports_project_scope` is **true**, proceed to the "Supported Client Write Path" section (User Story 1).
   - If `supports_project_scope` is **false**, proceed to the "Unmapped/No-Project-Scope Fallback Path" section (User Story 2), using the `fallback_reason` value from the row.
3. If no row is found (integration is entirely absent from Spec Kit's catalog):
   - Proceed to the "Unmapped/No-Project-Scope Fallback Path" section, with `fallback_reason` = `"Client integration not in Spec Kit's catalog"`.

**Extensibility constraint (FR-002)**: Adding a new client is adding one row to this table with all required fields populated. The detection, lookup, write, and fallback control flows must not change.

### Resolve Pinned MCP Server Reference

The command reads the project's rollout configuration file (Feature 002's `rollout-config.yml` or equivalent resolved config) and extracts the pinned MCP server specification. This is the canonical, non-secret description of the official LaunchDarkly MCP server that will be registered in the client's configuration file.

**Pinned MCP Server Fields** (all required for a valid entry):
- `mcp.command`: Launch command for the MCP server process (e.g., `"launchdarkly-mcp-server"`).
- `mcp.args`: Launch arguments as a list or space-separated string (e.g., `["--port", "3000"]`).
- `mcp.version`: Version constraint for the pinned server (e.g., `"~1.0.0"`). This is provenance metadata only — it MUST NOT be written into any client's MCP configuration file.
- `mcp.repository`: Source repository URL (e.g., `"https://github.com/launchdarkly/mcp-server"`). This is provenance metadata only — it MUST NOT be written into any client's MCP configuration file.
- `mcp.token_env_var`: Name only of the OS environment variable the MCP server process reads at launch (e.g., `"LAUNCHDARKLY_API_KEY"`). This name (not its value) MUST be written into the client's MCP entry, rendered according to that client's `env_var_reference_syntax`.

**Resolution Algorithm**:
1. Attempt to read and parse the project's rollout configuration file (typically `.specify/extensions/rollout/rollout-config.yml` or `.specify/extensions/rollout/local-config.yml`, following the config layering rules).
2. Extract the `mcp` object/table and its fields: `command`, `args`, `version`, `repository`, `token_env_var`.
3. Validate that all required fields are present and non-empty. If any required field (`command`, `args`, or `token_env_var`) is empty, missing, or unparseable:
   - Report: `"Pin not yet configured. Ensure mcp.command, mcp.args, and mcp.token_env_var are set in your rollout configuration."` and take neither the write path nor the fallback-snippet path.
   - Stop execution (do not fabricate placeholder values).
4. If all fields are valid, the pin is resolved. Proceed to the write or fallback path (determined by the adapter mapping lookup).

**Error handling**: If the rollout configuration file cannot be read or parsed, report the read/parse error and proceed to the fallback path.

### Common Error Handling & Validation

This section documents the error cases encountered across all control-flow paths and the consistent responses to each:

**1. Malformed JSON/TOML in Existing File**:
   - When the command attempts to read an existing MCP configuration file (per the "Write/Update MCP Configuration File" section), the file is parsed in the declared `format` (JSON or TOML).
   - If parsing fails (e.g., trailing comma, unclosed brace, syntax error), stop immediately, report the parse error with line/character details if available, and proceed to the copy-paste fallback path.
   - Do NOT attempt automatic repair, reformat, or partial re-write of the file. Let the developer merge the snippet manually.

**2. Detection Failure** (`.specify/integration.json` missing, unreadable, or `integration` field absent):
   - Report: `"Client integration detection failed. Please verify .specify/integration.json is present and contains an 'integration' field."`
   - Proceed to the copy-paste fallback path with a generic server snippet.

**3. Empty/Unconfigured Pin** (`mcp.command`, `mcp.args`, or `mcp.token_env_var` empty or missing):
   - Report: `"Pin not yet configured. Ensure mcp.command, mcp.args, and mcp.token_env_var are set in your rollout configuration."`
   - Take neither the write path nor the fallback-snippet path. Stop.

**4. File Read/Write Errors** (permission denied, disk full, etc.):
   - Report the specific I/O error.
   - Proceed to the copy-paste fallback path to allow manual merge.

### Non-Action Guarantees

The command MUST NEVER perform any of the following, across every control-flow path (detection, write, fallback, error handling):

- **NEVER launch or start the MCP server process**: The command is purely a registration utility. It does not execute `mcp.command`, does not spawn the server, and does not establish any connection to it.
- **NEVER prompt the developer for a token value**: No interactive prompts, no stdin reads, no "enter your API key" dialogs.
- **NEVER read a token value** from any source: not from the environment (even if `mcp.token_env_var` names an env var, the command does not read its value), not from a file, not from stdin, not from any credential store.
- **NEVER store a token value** anywhere: not in a temporary file, not in memory retained after execution, not in a log.
- **NEVER echo, print, or forward a token value** anywhere: not to stdout, not to stderr, not to any file, not to any external service.

**What the command DOES reference**: Only the `mcp.token_env_var` field — its *name* (e.g., `"LAUNCHDARKLY_API_KEY"`) — which is written into the MCP entry using the client's `env_var_reference_syntax` (e.g., `"${env:LAUNCHDARKLY_API_KEY}"` for Copilot, or `"${LAUNCHDARKLY_API_KEY}"` for Claude Code). The environment variable's value is read by the MCP server itself at launch time, not by this command.

---

## User Story 1: Supported Client Write Path (US1, Priority: P1)

### Supported Client Write Path Algorithm

When the adapter mapping lookup finds a matching client row with `supports_project_scope = true`, the command follows this write path:

**Step 1: Branch Decision**
- Check the matched adapter row's `supports_project_scope` field.
- If `true`, proceed with Step 2 (write path).
- If `false`, branch to the "Unmapped/No-Project-Scope Fallback Path" section instead (User Story 2).

**Step 2: Resolve Pin and Prepare Write**
- Ensure the pinned MCP server reference has been resolved (see "Resolve Pinned MCP Server Reference" section).
- Extract `mcp.command`, `mcp.args`, `mcp.token_env_var`, and the adapter's `env_var_reference_syntax`.

**Step 3: Write or Update the Client's MCP Configuration File**
- Follow the detailed algorithm in the "Write/Update MCP Configuration File" section.

**Step 4: Report the Outcome**
- Follow the "Reporting for Write Path" section to generate the appropriate message.

### Write/Update MCP Configuration File

This section provides detailed, client-format-specific instructions for reading, modifying, and writing a supported client's MCP configuration file.

**General Preconditions**:
- The adapter mapping has been consulted and `supports_project_scope = true`.
- The pinned MCP server reference is resolved and valid (non-empty `command`, `args`, `token_env_var`).
- The adapter row provides: `mcp_config_path`, `format`, `server_map_key`, and `env_var_reference_syntax`.

**Algorithm** (format-agnostic, applies to all supported clients):

1. **Read Existing File (if present)**:
   - Construct the file path: `<project_root> / <mcp_config_path>` (e.g., `.vscode/mcp.json` for Copilot).
   - If the file does not exist, proceed to "Create File" (below).
   - If the file exists, attempt to parse it in the declared `format` (JSON or TOML).
     - Parse failure: Report the error and proceed to the copy-paste fallback path (see "Common Error Handling & Validation").
     - Parse success: Proceed to "Locate or Create Server Map Key" (below).

2. **Create File** (if it does not exist):
   - Create the file with an empty top-level object/table (`{}` for JSON, `""` for TOML).
   - Proceed to "Locate or Create Server Map Key" (below).

3. **Locate or Create Server Map Key**:
   - The server map key is the top-level (for most formats) or nested-table (for TOML) location where individual MCP server entries are stored.
   - Check if the parsed file contains this key. For JSON, check for `file[server_map_key]`. For TOML, check for the dotted-path key.
   - If the key is present and is a table/object, proceed to "Locate or Create LaunchDarkly Entry" (below).
   - If the key is absent, create it as an empty object/table and proceed.

4. **Locate or Create LaunchDarkly Entry**:
   - Within the server map key, check if an entry named `"launchdarkly"` already exists.
   - If it exists, proceed to "Update Existing Entry" (below).
   - If it does not exist, proceed to "Create New Entry" (below).

5. **Create New Entry**:
   - Construct a new MCP server entry with:
     - `command`: `mcp.command` (exact value).
     - `args`: `mcp.args` (exact value, preserving array or string format as applicable).
     - Environment variable reference: Render `mcp.token_env_var` according to the adapter's `env_var_reference_syntax`:
       - **JSON adapters** (Copilot, Cursor, Gemini CLI): Create an `env` object entry: `"env": { "<mcp.token_env_var>": "<env_var_reference_syntax>" }`. For example, Copilot: `"env": { "LAUNCHDARKLY_API_KEY": "${env:LAUNCHDARKLY_API_KEY}" }`.
       - **JSON adapters (Claude Code)**: Syntax is `"${VAR_NAME}"` without `${env:...}`. Create: `"env": { "LAUNCHDARKLY_API_KEY": "${LAUNCHDARKLY_API_KEY}" }`.
       - **TOML adapters** (Codex): Create an `env_vars` array entry: `env_vars = ["LAUNCHDARKLY_API_KEY"]` (name only, no value).
   - Add the new entry to the server map key under the name `"launchdarkly"`.
   - Proceed to "Write File" (below).

6. **Update Existing Entry**:
   - Locate the existing `"launchdarkly"` entry within the server map key.
   - Compare its `command`, `args`, and env-var fields to the newly resolved entry (see Step 5 for structure).
   - If all fields are identical, proceed directly to "Write File" with no modifications (idempotent, no change).
   - If any field differs, update only that field's value in place. Do not modify any other entry or top-level file structure.
   - Proceed to "Write File" (below).

7. **Write File**:
   - Write the modified object/table back to the file path in the declared `format` (JSON or TOML).
   - Preserve the original file encoding (UTF-8).
   - Ensure the file is written atomically (write to a temporary file, then rename, if possible, to avoid partial writes on failure).
   - If the write succeeds, proceed to "Reporting for Write Path".
   - If the write fails (I/O error), report the error and proceed to the copy-paste fallback path.

### Idempotent Update Logic

The write algorithm above (especially Step 6, "Update Existing Entry") already implements idempotency:

- On re-run, the command detects and re-resolves the same client integration.
- It reads the MCP configuration file and finds the existing `"launchdarkly"` entry.
- It compares the existing entry's body to the freshly resolved pinned spec.
- If the entry is identical to the resolved spec, **no file write occurs** — the command can report "no changes needed" and skip the I/O operation.
- If the entry has drifted from the current pin (e.g., `mcp.command` changed, or the `mcp.token_env_var` name changed), the command updates only that entry's body in place, preserving all other entries and file structure byte-for-byte.
- **Crucially**: The command never creates a second `"launchdarkly"` entry, never renames the existing one, and never appends a suffix like `"launchdarkly_v2"`. Exactly one entry persists across all re-runs.

This convergence behavior satisfies User Story 3 (Idempotent Re-run).

### Reporting for Write Path

After the file write (or decision to skip it) completes, the command reports one of the following:

- **File created and entry added**: `"Detected client: <integration_key>. Configuration file created and written: <mcp_config_path>"`
  - Example: `"Detected client: cursor_agent. Configuration file created and written: .cursor/mcp.json"`

- **File already existed, entry added**: `"Detected client: <integration_key>. Configuration file written: <mcp_config_path> (new server entry added)"`
  - Example: `"Detected client: copilot. Configuration file written: .vscode/mcp.json (new server entry added)"`

- **File existed, entry updated due to drift**: `"Detected client: <integration_key>. Configuration file updated: <mcp_config_path> (server entry refreshed to match current pin)"`
  - Example: `"Detected client: gemini. Configuration file updated: .gemini/settings.json (server entry refreshed to match current pin)"`

- **File existed, entry unchanged (idempotent re-run)**: `"Detected client: <integration_key>. Configuration already correct — no changes needed."`
  - Example: `"Detected client: cline. Configuration already correct — no changes needed."`

---

## User Story 2: Unmapped/No-Project-Scope Fallback Path (US2, Priority: P2)

### Unmapped/No-Project-Scope Fallback Path

When the adapter mapping lookup finds that the detected client is either (a) absent from the mapping entirely, or (b) present but marked with `supports_project_scope = false`, the command takes the copy-paste fallback path instead of attempting a file write.

**Fallback Trigger Conditions**:
1. **Mapped but no project scope**: The adapter row exists (e.g., Cline), but `supports_project_scope = false`.
2. **Entirely unmapped**: No adapter row exists for the detected `integration_key` (e.g., Windsurf).
3. **Detection failed**: The integration could not be detected (see "Client Detection" section for handling).

**Fallback Algorithm**:

1. **Determine Fallback Reason**:
   - If detection failed: reason = `"Client integration detection failed"`.
   - If mapped but no project scope: reason = the value of the adapter row's `fallback_reason` field (e.g., `"Recognized integration; no project-scoped MCP configuration support"` for Cline).
   - If entirely unmapped: reason = `"Client integration not in Spec Kit's catalog"`.

2. **Generate Copy-Paste Snippet** (see "Generate Copy-Paste Snippet" section).

3. **Generate Environment Variable Reminder** (see "Environment Variable Reminder" section).

4. **Print Output**: Print the snippet and reminder to stdout (or the agent's output channel).

5. **Report the Outcome** (see "Reporting for Fallback Path" section).

### Generate Copy-Paste Snippet

The copy-paste snippet is a complete, correctly formatted MCP server entry in the format appropriate for the detected client (if mapped) or a generic format (if unmapped).

**Algorithm**:

1. **Determine the Format to Use**:
   - If a mapped adapter row exists, use its `format` field (JSON or TOML) and `server_map_key` value.
   - If the client is entirely unmapped, use generic JSON format with `server_map_key = "mcpServers"` (a common default across Claude Code, Cursor, and Gemini CLI).
   - If detection failed, use generic JSON with `server_map_key = "mcpServers"`.

2. **Construct the Snippet** (format-specific):

   **JSON Format** (Copilot, Claude Code, Cursor, Gemini CLI, or generic):
   ```json
   "<mcp.server_name>": {
     "command": "<mcp.command>",
     "args": [<comma-separated mcp.args, quoted if strings>],
     "env": {
       "<mcp.token_env_var>": "<env_var_reference_syntax>"
     }
   }
   ```
   Example for LaunchDarkly on Claude Code:
   ```json
   "launchdarkly": {
     "command": "launchdarkly-mcp-server",
     "args": ["--port", "3000"],
     "env": {
       "LAUNCHDARKLY_API_KEY": "${LAUNCHDARKLY_API_KEY}"
     }
   }
   ```

   **TOML Format** (Codex):
   ```toml
   [mcp_servers.launchdarkly]
   command = "<mcp.command>"
   args = [<comma-separated mcp.args, quoted if strings>]
   env_vars = ["<mcp.token_env_var>"]
   ```
   Example:
   ```toml
   [mcp_servers.launchdarkly]
   command = "launchdarkly-mcp-server"
   args = ["--port", "3000"]
   env_vars = ["LAUNCHDARKLY_API_KEY"]
   ```

3. **Include Environment Variable Reference**:
   - If a mapped adapter row exists, use its `env_var_reference_syntax` to render the token env-var name.
   - If unmapped, use a generic syntax: `"${<mcp.token_env_var>}"` (e.g., `"${LAUNCHDARKLY_API_KEY}"`).

4. **Output the Snippet**: Print the snippet in a code block (Markdown triple-backtick format) with the format label:
   ````
   ```json
   "launchdarkly": {
     ...
   }
   ```
   ````
   Or for TOML:
   ````
   ```toml
   [mcp_servers.launchdarkly]
   ...
   ```
   ````

### Environment Variable Reminder

After the snippet is printed, output a reminder instructing the developer to set the environment variable:

**Reminder Text**:
```
Environment variable required:
Set the following environment variable on your system before using the MCP server:
  export <mcp.token_env_var>=<your_api_key_value>

Replace <your_api_key_value> with your actual LaunchDarkly API key.
```

**Example**:
```
Environment variable required:
Set the following environment variable on your system before using the MCP server:
  export LAUNCHDARKLY_API_KEY=your_actual_api_key_here

Replace your_actual_api_key_here with your actual LaunchDarkly API key.
```

### Reporting for Fallback Path

After the snippet and reminder are printed, report one of the following:

- **Unmapped or no-project-scope client, fallback used**:
  - If mapped but no project scope: `"Detected client: <integration_key>. Configuration not supported in project scope. Snippet printed above — copy the server entry and set the environment variable manually."`
    - Example: `"Detected client: cline. Configuration not supported in project scope. Snippet printed above — copy the server entry and set the environment variable manually."`
  - If entirely unmapped: `"Detected client: <integration_key>. Client integration not in Spec Kit's catalog. Snippet printed above — copy the server entry and set the environment variable manually."`
    - Example: `"Detected client: windsurf. Client integration not in Spec Kit's catalog. Snippet printed above — copy the server entry and set the environment variable manually."`

- **Detection failed, fallback used**: `"Client integration detection failed. Snippet printed above — copy the server entry, identify your client's MCP configuration file manually, and set the environment variable."`

---

## User Story 3: Idempotent Re-run Behavior (US3, Priority: P1)

User Story 3's idempotency is largely implemented in the write path (see "Idempotent Update Logic" section in User Story 1). This section reinforces the guarantees and adds explicit validation logic.

### Idempotency Validation

Before writing the MCP configuration file (in the write path), validate that idempotency will be preserved:

**Validation Algorithm**:

1. **Check if Entry Already Exists**:
   - If the `"launchdarkly"` entry does not exist in the client's MCP configuration file, proceed to create it (already covered in "Write/Update MCP Configuration File").

2. **Compare Existing Entry to Freshly Resolved Entry**:
   - Extract the existing entry's `command`, `args`, and `env` fields.
   - Extract the freshly resolved entry's `command`, `args`, and `env` fields (from the current pin).
   - Perform a field-by-field comparison (not a string comparison, to account for formatting differences like extra whitespace in JSON).

3. **No Changes Needed**:
   - If all fields are identical, skip the file write entirely and report: `"Detected client: <integration_key>. Configuration already correct — no changes needed."`.

4. **Update Required**:
   - If any field differs, proceed to update the entry in place (see "Update Existing Entry" in the write path).

### Drift Detection & Correction

On re-run, the command detects and corrects drift in the existing `"launchdarkly"` entry:

**Drift Scenario**: Between two runs of `/speckit.rollout.connect`, the pinned MCP spec has changed (e.g., the `mcp.command` was updated in the rollout configuration) or the entry was manually edited to an incorrect value.

**Detection & Correction Algorithm**:

1. **Resolve the Current Pin**: Parse the current rollout configuration and extract the current `mcp.command`, `mcp.args`, `mcp.token_env_var`.

2. **Read the Existing Entry**: Parse the client's MCP configuration file and extract the existing `"launchdarkly"` entry's `command`, `args`, and `env` fields.

3. **Compare Field by Field**:
   - Does `existing.command` equal `current_pin.command`?
   - Does `existing.args` equal `current_pin.args`?
   - Does `existing.env` reference equal the rendered form of `current_pin.token_env_var`?
   - If all match, proceed to "Report: No Change" (below).
   - If any field differs, proceed to "Update and Report" (below).

4. **Update and Report**:
   - Update the drifted field(s) in place.
   - Do NOT create a second entry, rename the entry, or modify any other entry or file structure.
   - Report: `"Detected client: <integration_key>. Configuration file updated: <mcp_config_path> (server entry refreshed to match current pin)"`

5. **Report: No Change**:
   - Report: `"Detected client: <integration_key>. Configuration already correct — no changes needed."`.

### Reporting for Idempotent Re-run

On re-run, the command reports one of the following outcomes (these are the same as reported by the write path, illustrating idempotency):

- **No change**: `"Detected client: <integration_key>. Configuration already correct — no changes needed."`
- **Entry updated due to drift**: `"Detected client: <integration_key>. Configuration file updated: <mcp_config_path> (server entry refreshed to match current pin)"`
- **Fallback path on re-run**: `"Detected client: <integration_key>. Configuration not supported in project scope. Snippet printed above — copy the server entry and set the environment variable manually."` (if the client transitioned from write-able to unmapped, or if re-run detects the pin is no longer configured)

---

## Testing & Validation (Quickstart Scenarios)

This feature is validated through manual read-through and scripted fixture exercises, following Constitution Principle V (no live external services). Each scenario below documents the setup, the expected behavior described by the doctrine, and the verification steps.

### Scenario 1: Supported client, no prior MPC config (US1, P1)

**Setup**:
- Create a scratch directory to simulate a target project.
- Create `.specify/integration.json` with `{"integration": "cursor_agent"}`.
- Create `.specify/extensions/rollout/rollout-config.yml` with a fully populated `mcp:` block (see Feature 002's schema: `command`, `args`, `version`, `repository`, `token_env_var`).
- No `.cursor/mcp.json` file exists yet.

**Read-through check**: Confirm the doctrine in "User Story 1" instructs:
1. Read `.specify/integration.json` and extract `"cursor_agent"`.
2. Look up `cursor_agent` in the adapter mapping and find `supports_project_scope: true`, path `.cursor/mcp.json`, key `mcpServers`, syntax `${env:VAR_NAME}`.
3. No existing file, so create `.cursor/mcp.json` as `{}`.
4. Create the `mcpServers` key.
5. Create a `launchdarkly` entry under `mcpServers` with `command`, `args`, and `env: { LAUNCHDARKLY_API_KEY: "${env:LAUNCHDARKLY_API_KEY}" }` (no token value).
6. Write the file.
7. Report: `"Detected client: cursor_agent. Configuration file created and written: .cursor/mcp.json"`.

**Validation**: The resulting `.cursor/mcp.json` contains exactly the structure described, with zero token values.

### Scenario 2: Existing unrelated entries preserved (US1, P1)

**Setup**: Same as Scenario 1, but pre-populate `.cursor/mcp.json` with:
```json
{
  "mcpServers": {
    "playwright": {
      "command": "playwright-server",
      "args": []
    }
  }
}
```

**Read-through check**: Confirm the doctrine instructs:
1. Read the existing file and parse it successfully.
2. Locate `mcpServers`.
3. No existing `launchdarkly` entry, so create a new one.
4. Add `launchdarkly` entry alongside `playwright` under `mcpServers`.
5. Write the file without removing or modifying `playwright`.
6. Report: `"Detected client: cursor_agent. Configuration file written: .cursor/mcp.json (new server entry added)"`.

**Validation**: The resulting file contains both `playwright` and `launchdarkly` entries, byte-for-byte identical except for the added LaunchDarkly entry.

### Scenario 3: Idempotent re-run (US3, P1)

**Setup**: Reuse Scenario 2's resulting file (containing both `playwright` and `launchdarkly`).

**Read-through check**: Confirm the doctrine instructs:
1. Detect the same `cursor_agent` client.
2. Read the existing file and parse successfully.
3. Locate the existing `launchdarkly` entry.
4. Compare its body to the freshly resolved pin.
5. If identical (no drift), report no change and skip file write.
6. If drifted (e.g., simulate by hand-editing `command` to `"old-command"`), update only that field in place.
7. Write the file with only the updated field, preserving `playwright` and all other content.
8. Never create a second `launchdarkly` entry.

**Validation**: After re-run, the file still contains exactly one `launchdarkly` entry (never two), all other content intact.

### Scenario 4: Unmapped/no-project-scope client fallback (US2, P2)

**Setup**: Change `.specify/integration.json` to `{"integration": "cline"}`.

**Read-through check**: Confirm the doctrine instructs:
1. Detect `cline` client.
2. Look up `cline` in the adapter mapping and find `supports_project_scope: false`, `fallback_reason: "Recognized integration; no project-scoped MCP configuration support"`.
3. Take fallback path.
4. Create no file on disk.
5. Print a complete `mcpServers`-shaped JSON snippet (Cline's format) with `command`, `args`, and `env: { LAUNCHDARKLY_API_KEY: "${env:LAUNCHDARKLY_API_KEY}" }` (no token value).
6. Print the environment variable reminder: `"export LAUNCHDARKLY_API_KEY=..."`
7. Report: `"Detected client: cline. Configuration not supported in project scope. Snippet printed above — copy the server entry and set the environment variable manually."`

**Validation**:
- No file created or modified on disk.
- Printed snippet contains no token value.
- Reminder includes exact `mcp.token_env_var` name.

### Scenario 4b: Entirely unmapped client (e.g., Windsurf)

**Setup**: Change `.specify/integration.json` to `{"integration": "windsurf"}` (not in the adapter mapping).

**Read-through check**: Confirm the doctrine instructs:
1. Detect `windsurf` client.
2. Look up `windsurf` in the adapter mapping and find no row (entirely unmapped).
3. Take fallback path with reason `"Client integration not in Spec Kit's catalog"`.
4. Generate a generic JSON snippet (no client-specific format known) with the generic `${VAR_NAME}` syntax (not `${env:VAR_NAME}`).
5. Print snippet and reminder (same as Scenario 4).
6. Report: `"Detected client: windsurf. Client integration not in Spec Kit's catalog. Snippet printed above — copy the server entry and set the environment variable manually."` (distinguishing from Scenario 4's mapped-but-no-scope reason).

**Validation**: Reporting text differs from Scenario 4, correctly distinguishing the two fallback cases.

### Scenario 5: Malformed existing config (Edge Case, FR-010)

**Setup**: Reuse Scenario 1's setup, but pre-populate `.cursor/mcp.json` with invalid JSON:
```json
{
  "mcpServers": {
    "playwright": { "command": "playwright-server", } // trailing comma
  }
}
```

**Read-through check**: Confirm the doctrine instructs:
1. Attempt to read and parse `.cursor/mcp.json`.
2. Parse fails due to trailing comma.
3. Report the parse error (e.g., `"JSON parse error at line 4, character 5: trailing comma in object"`).
4. Proceed to copy-paste fallback path (do NOT blindly overwrite).
5. Print snippet and reminder.
6. Report: `"Detected client: cursor_agent. Configuration file contains syntax errors. Snippet printed above — please merge the entry manually after fixing the file."`

**Validation**: No file is overwritten or corrupted. Manual merge path is clear.

### Scenario 6: Empty/unconfigured pin (Edge Case, FR-011)

**Setup**: Reuse Scenario 1's setup, but leave `mcp.command` empty in `rollout-config.yml`:
```yaml
mcp:
  command: ""
  args: []
  version: ""
  repository: ""
  token_env_var: "LAUNCHDARKLY_API_KEY"
```

**Read-through check**: Confirm the doctrine instructs:
1. Attempt to resolve the pinned MCP server reference.
2. Detect that `mcp.command` is empty.
3. Report: `"Pin not yet configured. Ensure mcp.command, mcp.args, and mcp.token_env_var are set in your rollout configuration."`
4. Take neither the write path nor the fallback-snippet path.
5. Stop execution.

**Validation**: No file created, no snippet printed, command exits with a clear error message.

### Scenario 7: Detection failure (Edge Case)

**Setup**: Reuse Scenario 1's setup, but delete `.specify/integration.json` entirely.

**Read-through check**: Confirm the doctrine instructs:
1. Attempt to read `.specify/integration.json`.
2. File does not exist.
3. Report: `"Client integration detection failed. Please verify .specify/integration.json is present and contains an 'integration' field."`
4. Proceed to copy-paste fallback path with generic JSON snippet.
5. Print snippet and reminder.

**Validation**: No file is created in the project, fallback snippet is printed, developer is given manual merge path.

### Scenario 8: Multi-integration project (Edge Case)

**Setup**: Populate `.specify/integration.json` with:
```json
{
  "integration": "cursor_agent",
  "installed_integrations": ["copilot", "cursor_agent", "cline"]
}
```

**Read-through check**: Confirm the doctrine instructs:
1. Detect the active integration from the `integration` field: `cursor_agent`.
2. Ignore `installed_integrations` (do not act on copilot or cline).
3. Look up only `cursor_agent` in the adapter mapping.
4. Write only `.cursor/mcp.json` (not `.vscode/mcp.json` for Copilot or fallback for Cline).

**Validation**: Only `.cursor/mcp.json` is created/modified; no other client's configuration is touched.

### Cross-Cutting Checks

In addition to the eight scenarios above, verify the following across the entire `commands/connect.md` doctrine:

- **FR-004 (No token value)**: Grep the entire file for any example token values (e.g., placeholder API keys like `"XXXX"`, `"secret"`, `"token123"`). None should appear outside of `<mcp.token_env_var>`, `<token env>`, `<env-var>`, or `<environment variable>` context. If found, the doctrine violates FR-004.

- **FR-001 (Minimum client set)**: Confirm the adapter mapping table includes at least the clients listed in spec.md's minimum set: `copilot`, `claude`, `cline`, `cursor_agent`, `windsurf`, `gemini`, `codex`. If fewer than 7 clients are listed, FR-001 is not satisfied.

- **FR-005 & FR-006 (Idempotency and preservation)**: Search the doctrine for language supporting idempotency and no-overwrite guarantees: "exactly one entry", "never duplicate", "preserve", "untouched", "byte-for-byte unchanged". If this language is absent, the doctrine may not correctly guide idempotent re-runs.

- **FR-009 (Non-action guarantees)**: Search the doctrine for explicit statements of what the command NEVER does: "never launches", "never connects to", "never starts the MCP server", "never prompts for token", "never reads token value", "never stores token value", "never echoes token". All six guarantees should be present and unambiguous.

---

## Summary

This command is the first user-invoked (not hook-based) setup command in the rollout extension. It demonstrates:

1. **Client Detection via Spec Kit's own state** (FR-001): Reading `.specify/integration.json` ensures coverage tracks all Spec Kit-supported clients without duplication.

2. **Per-client Adapter Mapping** (FR-002): A simple, extensible table that associates each client with its MCP configuration file path, format, and project-scope support. Adding a new client is one added row.

3. **Pinned Server Registration** (FR-003 to FR-006): Writing the pinned LaunchDarkly MCP server entry into the client's configuration file while preserving all other entries and structure.

4. **Credential Security** (FR-004, FR-009): Only `mcp.token_env_var`'s *name* is ever written or printed; the value is never read, stored, or forwarded.

5. **Idempotent Re-run** (FR-005, User Story 3): Re-running the command against the same client results in zero functional change if the entry is already correct, or updates only the drifted entry if the pin has changed.

6. **Graceful Fallback** (FR-007): For unmapped or no-project-scope clients, the command prints a copy-paste snippet instead of guessing or failing.

7. **Consistent Reporting** (FR-008): Every run concludes with clear reporting of the detected client and the action taken.

8. **Error Handling** (FR-010, FR-011): Malformed files and empty pins are reported and do not corrupt the developer's configuration.
