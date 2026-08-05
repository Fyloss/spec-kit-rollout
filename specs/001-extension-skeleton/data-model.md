# Data Model: Rollout Extension Skeleton

This feature has no runtime data model (no database, no in-memory domain
objects). The "entities" are the structural elements of the extension package
itself, as declared in `extension.yml` and resolved by the Spec Kit extension
manager at install time.

## Extension (package identity)

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string, `^[a-z0-9-]+$` | yes | `rollout`; must not collide with a core command namespace |
| `name` | string | yes | Human-readable display name |
| `version` | string, PEP 440 version | yes | `1.0.0` |
| `description` | string | yes | Short package description |
| `author` | string | no (convention) | Free-form passthrough field |
| `repository` | string (URL) | no (convention) | Free-form passthrough field |
| `license` | string | no (convention) | `MIT` |
| `homepage` | string (URL) | no (convention) | Free-form passthrough field |
| `category` | string | no | Free-form; vision suggests "integration" |
| `effect` | `read-only` \| `read-write` | no | `read-write` (writes spec/plan/tasks content and, later, calls provider MCP tools) |

## Requires (compatibility)

| Field | Type | Required | Notes |
|---|---|---|---|
| `speckit_version` | PEP 440 SpecifierSet string | yes | `">=0.12.0"` |

## Command (one of 8 instances)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string, `^speckit\.rollout\.[a-z0-9-]+$` | yes | Namespace segment must equal `extension.id` |
| `file` | relative path string | yes | `commands/<slug>.md`; must exist, no path traversal |
| `description` | string | recommended | Shown by `specify extension list`/`info` |
| `aliases` | string[] | no | Not used in this feature |

**Instances** (8): `brief-specify`, `brief-clarify`, `brief-plan`,
`brief-tasks`, `brief-analyze`, `brief-checklist`, `brief-implement`,
`connect` — each mapped 1:1 to a placeholder file under `commands/`.

## Hook (one of 7 instances, keyed by lifecycle event)

| Field | Type | Required | Notes |
|---|---|---|---|
| event key | one of the 7 event names | yes | `before_specify`, `before_clarify`, `before_plan`, `before_tasks`, `before_analyze`, `before_checklist`, `before_implement` |
| `command` | string, must reference a declared command `name` | yes | e.g. `speckit.rollout.brief-specify` |
| `optional` | boolean | yes for this feature | Always `false` — defaults to `true` if omitted, per the installed validator |
| `priority` | integer >= 1 | no | Not needed (single hook per event, no ordering conflict) |

**Relationship**: Each hook event maps to exactly one of the 7 `brief-*`
commands (event → command is 1:1, and every `brief-*` command is targeted by
exactly one hook). `connect` has no hook — it is a manually invoked, one-time
setup command per the vision (section 7 / Decision D2).

## Config declaration

| Field | Type | Required | Notes |
|---|---|---|---|
| `provides.config[].id` | string | no (descriptive) | `rollout-config` |
| `provides.config[].file` | relative path string | no (descriptive) | `rollout-config.yml` (project-level, not shipped in the package) |
| `provides.config[].template` | relative path string | no (descriptive) | `rollout-config.template.yml`; must exist in the package |
| `provides.config[].required` | boolean | no (descriptive) | `false` |
| `config.defaults` | mapping | no | Placeholder default values, resolved today by `ConfigManager` |
| `config.config_schema` | mapping | no | Placeholder schema description, not enforced by the installed CLI |

**State**: Config has no lifecycle/state transitions in this feature — it is a
static declaration with placeholder values; real provider configuration
(provider id, project/environment keys, pinned MCP spec) is out of scope here.

## Packaging files (not manifest-declared, but required by the spec)

| File | Required | Notes |
|---|---|---|
| `README.md` | yes | Package overview |
| `LICENSE` | yes | MIT license text |
| `CHANGELOG.md` | yes | Records `1.0.0` initial release |
| `.extensionignore` | yes | Gitignore-pattern exclusions for dev-only files |
