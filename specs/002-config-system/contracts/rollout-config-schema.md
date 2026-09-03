# Contract: `rollout-config.yml` Configuration Schema (interface to gate scripts & briefing commands)

> **Superseded in part by Feature 013** (`013-rollout-config-wizard`): the
> `mcp.*` block described below was permanently removed (FR-017/FR-026 of
> that feature) and replaced by a modular per-provider schema. This contract
> is updated in place, rather than duplicated, to remain the single
> canonical schema contract in this repository — see the "Shape" and
> "Consumers of this contract" sections below for the current, post-013
> shape.

This feature's external interface is the resolved configuration read by
future gate scripts and `before_*` briefing commands via the installed Spec
Kit `ConfigManager` (`specify_cli.extensions.ConfigManager`). This contract
documents the exact shape this feature commits to, grounded in the installed
`specify-cli` 0.12.2 `ConfigManager` source (see research.md).

## Shape

```yaml
# rollout-config.template.yml (and, once copied, rollout-config.yml)

provider: launchdarkly

# Modular per-provider block. A second provider ever configured adds its
# own sibling top-level block here (e.g. `unleash:`), never touching this
# one (Feature 013 FR-026).
launchdarkly:
  project_key: ""
  environments: []
  # "hosted" | "local" | "" (unset) — informational/reporting only, never
  # trusted as a cache; re-verified fresh on every speckit.rollout.config run.
  server_type: ""

hooks:
  enabled: true
```

The MCP server selection itself (which of the developer's own registered
MCP servers to use — name/key only) is **not** part of this file. It lives
in `.specify/extensions/rollout/local-config.yml`, under the literal, flat
key `mcp_server` (Feature 013 FR-018) — e.g. `mcp_server: launchdarkly/mcp-server`.
No `mcp.command`, `mcp.args`, `mcp.version`, `mcp.repository`, or
`mcp.token_env_var` field exists anywhere in this schema anymore.

## Guarantees this feature makes

1. `rollout-config.template.yml` parses as valid YAML and contains zero
   secret/credential values anywhere (FR-001, FR-010, FR-013).
2. `provider` is a plain string; `"launchdarkly"` is the only value
   recognized in V1, but any other string value MUST NOT cause a parse or
   validation error (spec.md edge case) — pluggability, not enum enforcement.
3. `launchdarkly.project_key` and `launchdarkly.environments` hold only
   placeholder/example non-secret identifiers in the committed template.
4. ~~`mcp.token_env_var` holds only the **name** of an OS environment
   variable...~~ **Superseded by Feature 013**: this field, and the entire
   `mcp.*` block, no longer exist. No token-related field exists in this
   schema at all.
5. `hooks.enabled` is a boolean, default `true`, at the nested path
   `hooks.enabled` (not the flat `hooks_enabled` used by the 001 placeholder).
6. `extension.yml`'s `config.defaults` mirrors this same nested shape exactly
   (`provider: launchdarkly`, `hooks: {enabled: true}`), since that file is
   what `ConfigManager` actually reads as the defaults layer once installed.
7. Every inline comment required by FR-006 is present in the committed
   template: (a) never commit secrets here; (b) no field in this schema ever
   holds a credential value, by construction (Feature 013 removed the only
   field — `mcp.token_env_var` — that referenced one, even by name).

## Resolution contract (consumed by future features)

| Layer | Precedence | Path | Produced by this feature? |
|---|---|---|---|
| Extension defaults | lowest | `extension.yml` `config.defaults` (installed copy at `.specify/extensions/rollout/extension.yml`) | Yes — updated by this feature |
| Project config | 2nd | `.specify/extensions/rollout/rollout-config.yml` | No — per-adopting-project artifact; this feature ships the template it's copied from |
| Local override | 3rd | `.specify/extensions/rollout/local-config.yml` | No — per-developer artifact; this feature documents its existence and required `.gitignore` treatment. Feature 013 additionally uses this file to store the developer's MCP server selection (name/key only). |
| Env vars | highest | `SPECKIT_ROLLOUT_*` (prefix-matched, underscore-split into nested keys) | No — OS-level; this feature documents the exact splitting behavior and its limits |

A field is unset at a layer → the merge falls through to the next
lower-precedence layer's value for that field (FR-007); a missing project or
local config file contributes nothing and is not an error (FR-012).

## Consumers of this contract

- Future `before_*` briefing command gate scripts (a later feature) — read
  `hooks.enabled` to decide no-op vs. full doctrine injection.
- `speckit.rollout.config` and `speckit.rollout.provider` (Feature 013,
  superseding the former `speckit.rollout.connect`) — read and write
  `provider` and `launchdarkly.*`, and read/write the MCP server selection
  in `local-config.yml`. Neither command ever reads or writes an `mcp.*`
  field, since none exists.
- `before_implement` provider-action doctrine — reads `provider`,
  `launchdarkly.project_key`, `launchdarkly.environments`, and the MCP
  server selection from `local-config.yml` (Feature 013 FR-020).

## Non-goals of this contract

- No behavioral contract for how a gate script parses/validates
  `hooks.enabled`'s invalid-value fallback — only the *requirement* (fall
  back to enabled) is specified here; the parsing implementation belongs to
  the feature that ships the gate script.
- No contract for provider blocks other than `launchdarkly` — a future
  provider feature defines its own sibling block and, if needed, its own
  contract addendum.
- No automated secret-scanning or pre-commit enforcement contract (Out of
  Scope per spec.md).
