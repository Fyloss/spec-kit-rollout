# Contract: `rollout-config.yml` Configuration Schema (interface to gate scripts & briefing commands)

This feature's external interface is the resolved configuration read by
future gate scripts and `before_*` briefing commands via the installed Spec
Kit `ConfigManager` (`specify_cli.extensions.ConfigManager`). This contract
documents the exact shape this feature commits to, grounded in the installed
`specify-cli` 0.12.2 `ConfigManager` source (see research.md).

## Shape

```yaml
# rollout-config.template.yml (and, once copied, rollout-config.yml)

provider: launchdarkly

launchdarkly:
  project_key: ""
  environments: []

mcp:
  command: ""
  args: []
  version: ""
  repository: ""
  token_env_var: "LAUNCHDARKLY_API_TOKEN"

hooks:
  enabled: true
```

## Guarantees this feature makes

1. `rollout-config.template.yml` parses as valid YAML and contains zero
   secret/credential values anywhere (FR-001, FR-010, FR-013).
2. `provider` is a plain string; `"launchdarkly"` is the only value
   recognized in V1, but any other string value MUST NOT cause a parse or
   validation error (spec.md edge case) — pluggability, not enum enforcement.
3. `launchdarkly.project_key` and `launchdarkly.environments` hold only
   placeholder/example non-secret identifiers in the committed template.
4. `mcp.token_env_var` holds only the **name** of an OS environment variable
   — never a token value — in every committed file this feature produces
   (template, docs, examples).
5. `hooks.enabled` is a boolean, default `true`, at the nested path
   `hooks.enabled` (not the flat `hooks_enabled` used by the 001 placeholder).
6. `extension.yml`'s `config.defaults` mirrors this same nested shape exactly
   (`provider: launchdarkly`, `hooks: {enabled: true}`), since that file is
   what `ConfigManager` actually reads as the defaults layer once installed.
7. Every inline comment required by FR-006 is present in the committed
   template: (a) never commit secrets here; (b) the token is consumed only by
   the MCP server process; (c) the agent must never read or echo the token
   value.

## Resolution contract (consumed by future features)

| Layer | Precedence | Path | Produced by this feature? |
|---|---|---|---|
| Extension defaults | lowest | `extension.yml` `config.defaults` (installed copy at `.specify/extensions/rollout/extension.yml`) | Yes — updated by this feature |
| Project config | 2nd | `.specify/extensions/rollout/rollout-config.yml` | No — per-adopting-project artifact; this feature ships the template it's copied from |
| Local override | 3rd | `.specify/extensions/rollout/local-config.yml` | No — per-developer artifact; this feature documents its existence and required `.gitignore` treatment |
| Env vars | highest | `SPECKIT_ROLLOUT_*` (prefix-matched, underscore-split into nested keys) | No — OS-level; this feature documents the exact splitting behavior and its limits |

A field is unset at a layer → the merge falls through to the next
lower-precedence layer's value for that field (FR-007); a missing project or
local config file contributes nothing and is not an error (FR-012).

## Consumers of this contract

- Future `before_*` briefing command gate scripts (a later feature) — read
  `hooks.enabled` to decide no-op vs. full doctrine injection.
- Future `speckit.rollout.connect` implementation — reads `mcp.*` and
  `launchdarkly.*` to register the pinned MCP server.
- Future provider-action doctrine (`before_implement`) — reads `provider`,
  `launchdarkly.project_key`, `launchdarkly.environments`.

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
