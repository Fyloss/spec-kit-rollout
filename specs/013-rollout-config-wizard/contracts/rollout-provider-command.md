# Contract: Rollout Provider Switch (`speckit.rollout.provider <provider_name>`)

This contract defines the external, observable behavior of the
`speckit.rollout.provider` command, independent of the exact wording of the
doctrine text in `commands/provider.md`.

## Invocation

- Command name: `speckit.rollout.provider` (registered in `extension.yml`
  under `provides.commands`), taking one required argument: the target
  provider name (e.g. `launchdarkly`).
- User-invoked only. Never auto-executed by a `before_*` hook.

## Behavior contract

| Condition | Required outcome |
|---|---|
| `<provider_name>` already has an existing config block in `rollout-config.yml` | Reuse it as-is. Update only the top-level `provider:` value to point at it. MUST NOT re-run that provider's setup wizard or re-prompt for any field already present in its block. |
| `<provider_name>` has no existing config block | Run that provider's own preset flow to create one (in V1, only `launchdarkly` has a real preset — this is exactly `speckit.rollout.config`'s steps 1-6 scoped to that one provider). A future provider adds its own sibling preset; this command's own control-flow (argument parsing, existing-block check, `provider:` update) MUST NOT change to accommodate it (FR-025). |
| `<provider_name>` is not a recognized provider name at all | Report clearly that the name is unrecognized; MUST NOT create a malformed or empty block for it. |

## Prohibited actions

- MUST NOT modify any other provider's existing config block.
- MUST NOT request, read, prompt for, log, or store a credential/token value
  at any point (FR-023, same as the config wizard).
- MUST NOT write to `rollout-config.yml` before the same explicit-
  confirmation gate the underlying preset flow requires (when a preset runs,
  it is exactly `speckit.rollout.config`'s step 7 gate — no separate,
  weaker confirmation path is introduced for the `provider` command).

## Output shape

Only the top-level `provider:` field changes when reusing an existing
block:

```yaml
# before
provider: launchdarkly
launchdarkly: { project_key: my-project, environments: [production], server_type: hosted }
unleash: { project_key: other-project, environments: [staging], server_type: local }

# after: speckit.rollout.provider unleash
provider: unleash
launchdarkly: { project_key: my-project, environments: [production], server_type: hosted }
unleash: { project_key: other-project, environments: [staging], server_type: local }
```

Both provider blocks are preserved untouched; only the active selector
changes.
