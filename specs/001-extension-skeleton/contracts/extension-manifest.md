# Contract: `extension.yml` Manifest (interface to the Spec Kit CLI)

This package's only external interface is the manifest read by the `specify`
CLI's extension manager (`specify extension add|list|remove|info`). This
contract documents the exact shape this feature commits to, grounded in the
installed `specify-cli` 0.12.2 validator (see research.md).

## Shape

```yaml
schema_version: "1.0"

extension:
  id: rollout
  name: <human-readable name>
  version: 1.0.0
  description: <short description>
  author: <author>
  repository: <repository URL>
  license: MIT
  homepage: <homepage URL>
  category: integration
  effect: read-write

requires:
  speckit_version: ">=0.12.0"

provides:
  commands:
    - name: speckit.rollout.brief-specify
      file: commands/brief-specify.md
      description: <purpose>
    - name: speckit.rollout.brief-clarify
      file: commands/brief-clarify.md
      description: <purpose>
    - name: speckit.rollout.brief-plan
      file: commands/brief-plan.md
      description: <purpose>
    - name: speckit.rollout.brief-tasks
      file: commands/brief-tasks.md
      description: <purpose>
    - name: speckit.rollout.brief-analyze
      file: commands/brief-analyze.md
      description: <purpose>
    - name: speckit.rollout.brief-checklist
      file: commands/brief-checklist.md
      description: <purpose>
    - name: speckit.rollout.brief-implement
      file: commands/brief-implement.md
      description: <purpose>
    - name: speckit.rollout.connect
      file: commands/connect.md
      description: <purpose>
  config:
    - id: rollout-config
      file: rollout-config.yml
      template: rollout-config.template.yml
      required: false

hooks:
  before_specify:
    command: speckit.rollout.brief-specify
    optional: false
  before_clarify:
    command: speckit.rollout.brief-clarify
    optional: false
  before_plan:
    command: speckit.rollout.brief-plan
    optional: false
  before_tasks:
    command: speckit.rollout.brief-tasks
    optional: false
  before_analyze:
    command: speckit.rollout.brief-analyze
    optional: false
  before_checklist:
    command: speckit.rollout.brief-checklist
    optional: false
  before_implement:
    command: speckit.rollout.brief-implement
    optional: false

config:
  defaults: { ... placeholder ... }
  config_schema: { ... placeholder ... }
```

## Guarantees this package makes

1. `schema_version` is exactly `"1.0"`.
2. `extension.id` is exactly `rollout`.
3. Exactly 8 entries under `provides.commands`; every `name` matches
   `^speckit\.rollout\.[a-z0-9-]+$`; every `file` exists in the package.
4. Exactly 7 keys under the top-level `hooks` mapping, each with
   `optional: false` and a `command` value that exactly matches one of the 8
   declared command names.
5. `requires.speckit_version` is a valid PEP 440 specifier whose range
   includes `0.12.2`.
6. `provides.config[0].template` (`rollout-config.template.yml`) exists in the
   package. `provides.config[0].file` (`rollout-config.yml`) is a
   project-level file the extension does **not** ship (consistent with
   `required: false` — no config is mandatory to install).

## Consumers of this contract

- `specify extension add --dev` — parses and structurally validates the
  manifest; installs commands, registers hooks in project config.
- `specify extension list` / `info` — reads `command_count` /
  `hook_count` (`len(provides.commands)` / `len(hooks)`) and `enabled` status
  for display.
- `specify extension remove` — unregisters hooks and removes installed
  commands/config by `extension.id`.

## Non-goals of this contract

- No behavioral contract for what the 7 briefing commands or `connect`
  actually instruct the agent to do — their file content in this feature is a
  placeholder only (real doctrine is a later feature's contract).
- No contract for `rollout-config.yml`'s real key/value shape beyond the
  placeholder `config_schema` — a future feature will define the actual
  provider/environment/MCP-pin schema.
