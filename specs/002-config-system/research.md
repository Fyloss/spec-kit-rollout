# Research: Rollout Configuration System

The feature input named the four layering sources by role ("extension
defaults -> rollout-config.yml -> rollout-config.local.yml (gitignored) ->
`SPECKIT_ROLLOUT_*` env vars") but not the exact resolved paths or the loader's
actual merge semantics. Rather than trust the vision doc's prose alone, the
real `ConfigManager` implementation was read directly from the installed
`specify-cli` 0.12.2 package
(`specify_cli/extensions/__init__.py:2657-2840`), the same verification
approach used in 001-extension-skeleton (see repo-memory note
`spec-kit-extension-schema.md`). Findings below.

## Decision: Resolved file paths

- **Decision**: Project config resolves at
  `.specify/extensions/rollout/rollout-config.yml`; local override resolves
  at `.specify/extensions/rollout/local-config.yml` (not
  `rollout-config.local.yml` as the raw input suggested).
- **Rationale**: `ConfigManager.__init__` sets
  `self.extension_dir = project_root / ".specify" / "extensions" / extension_id`.
  `_get_project_config` reads `self.extension_dir / f"{self.extension_id}-config.yml"`
  → `rollout-config.yml`. `_get_local_config` reads
  `self.extension_dir / "local-config.yml"` literally — the filename is
  **not** parameterized by extension id, it is always exactly
  `local-config.yml`. This matches the correction already recorded in
  spec.md's Assumptions section (superseding the input's suggested
  `rollout-config.local.yml`).
- **Alternatives considered**: Trusting the input's literal filename
  suggestion — rejected because it does not match the loader that will
  actually read the file; shipping a template/doc for a path the CLI never
  looks at would silently fail every override.

## Decision: Extension defaults are read from the *installed* manifest copy

- **Decision**: `extension.yml`'s `config.defaults` map must be kept in sync
  with the template's documented defaults, because both files matter for
  different reasons: `extension.yml` is what `ConfigManager` actually reads
  as layer 1, while `rollout-config.template.yml` is what a human copies to
  create layer 2.
- **Rationale**: `_get_extension_defaults` reads
  `self.extension_dir / "extension.yml"` — i.e. the **installed copy** at
  `.specify/extensions/rollout/extension.yml` (written by `specify extension
  add`'s `shutil.copytree`), not this repository's root `extension.yml`
  directly. Since install copies the whole package, keeping the root
  `extension.yml`'s `config.defaults` accurate is what makes the installed
  copy's defaults correct.
- **Alternatives considered**: Only updating the template and treating
  `extension.yml`'s `config.defaults` as decorative — rejected because this
  is the one functional default-layer mechanism the installed CLI actually
  reads (confirmed already in 001's research.md); leaving it as the old flat
  `hooks_enabled: true` placeholder would make layer 1 disagree with the
  documented nested `hooks.enabled` schema.

## Decision: Env-var key-splitting constrains which fields are env-overridable

- **Decision**: The schema keeps `hooks.enabled` as a two-segment, single-word
  -per-segment path (already required by spec.md's Assumptions), and
  documents — rather than works around — the fact that other multi-word
  leaf fields (`project_key`, `token_env_var`) cannot be cleanly targeted by
  an env var.
- **Rationale**: `_get_env_config` matches keys by prefix
  `SPECKIT_ROLLOUT_` and then does
  `key[len(prefix):].lower().split("_")` — **every** underscore is treated as
  a nesting separator, with no way to distinguish "this underscore is part of
  a multi-word field name" from "this underscore separates nested sections."
  `SPECKIT_ROLLOUT_HOOKS_ENABLED` therefore correctly splits to
  `["hooks", "enabled"]`, merging into `{hooks: {enabled: "<value>"}}` — an
  exact match for the schema's nested shape. But
  `SPECKIT_ROLLOUT_PROJECT_KEY` would split to `["project", "key"]`, producing
  `{project: {key: "<value>"}}` instead of overriding a flat `project_key`
  field, and `SPECKIT_ROLLOUT_TOKEN_ENV_VAR` would split into three levels.
  This is a genuine, unavoidable limitation of the installed loader, not a
  choice this feature can design around without renaming fields to
  single-word segments (which would harm readability for no practical gain,
  since FR-007's env-var layer is explicitly scoped by User Story 2 to the
  hooks toggle).
- **Alternatives considered**: Renaming `project_key` to a single-word leaf
  (e.g. `key` nested under `launchdarkly:`) so it becomes env-overridable —
  rejected as unnecessary: the LaunchDarkly project key is not a per-developer
  override target in the spec's user stories (User Story 3's example is "a
  personal LaunchDarkly sandbox project or a locally-running MCP server
  build," both naturally suited to the local-config.yml layer, which supports
  arbitrary YAML nesting correctly). Documenting the limitation is more
  honest than silently overpromising full env-var coverage of every field.

## Decision: The hooks toggle's invalid-value fallback is a consumer concern

- **Decision**: `rollout-config.template.yml` and its documentation describe
  the safe-default behavior required by spec.md's edge case ("hooks toggle
  set to an invalid non-boolean value falls back to enabled"), but this
  feature does not implement a validating reader — that responsibility
  belongs to whichever future feature's gate script actually calls
  `ConfigManager.get_value("hooks.enabled")`.
- **Rationale**: `ConfigManager` performs no type coercion or validation; YAML
  layers (defaults, project, local) parse to native `bool`/`str`/etc. via
  `yaml.safe_load`, but the env-var layer (`_get_env_config`) always produces
  raw strings (`os.environ` values are strings), so
  `SPECKIT_ROLLOUT_HOOKS_ENABLED=false` resolves to the *string* `"false"`,
  not the boolean `False`. A naive consumer doing `if not config["hooks"]["enabled"]`
  would treat that truthy non-empty string as *enabled*, not disabled — a real
  correctness trap. This feature documents the trap and the required
  safe-default behavior; implementing the actual gate-script parsing logic is
  out of scope here (it lives with the `before_*` hook commands, a later
  feature per spec.md's Out of Scope).
- **Alternatives considered**: Silently ignoring the string-vs-bool
  discrepancy — rejected because it would ship a schema whose documented
  edge-case behavior (FR edge case) is not actually achievable by a naive
  reader, setting up a predictable bug for the feature that consumes this
  config next.

## Decision: `.gitignore` responsibility for the local override file is a documentation, not a code, deliverable

- **Decision**: Document, in `rollout-config.template.yml`'s comments and in
  `README.md`, that adopting projects must ensure
  `.specify/extensions/rollout/local-config.yml` is excluded from their own
  version control — Spec Kit's extension installer does not manage a
  consuming project's `.gitignore` automatically.
- **Rationale**: Grepping the installed `specify_cli` package for
  `.gitignore`-writing logic in the extensions/install code path found none;
  `ConfigManager`'s docstring calls the local file "gitignored" descriptively,
  but nothing enforces it. This repository's own `.gitignore` already
  excludes the entire `.specify/extensions/` tree (recorded for 001 as "Spec
  Kit local runtime state... not part of this repository's source"), which
  incidentally also covers this repo's own local-config.yml during
  self-testing — but that rule is about *this* repo's dev-install artifact,
  not a mechanism this feature ships to other adopting projects.
- **Alternatives considered**: Assuming the CLI auto-manages this (matching a
  literal reading of "gitignored" in the vision/spec text) — falsified by
  reading the installer source; no such behavior exists, so the only
  reliable mitigation this feature can ship is documentation instructing
  adopters to add the ignore rule themselves.

## Decision: Provider pluggability shape

- **Decision**: Keep a top-level `provider: launchdarkly` selector, and nest
  all LaunchDarkly-specific pointer fields (project key, environments) under
  a sibling `launchdarkly:` block; the pinned MCP server reference lives
  under its own `mcp:` block since the server pin (command/args/version/repo)
  is a provider-adjacent but structurally distinct concern from the
  provider's own project/environment identifiers.
- **Rationale**: Satisfies FR-002 ("adding a future provider requires only a
  new value for this field and adjacent provider-specific pointer fields, not
  a schema redesign") — a future `provider: unleash` would add a sibling
  `unleash:` block without touching `launchdarkly:`, `mcp:`, or `hooks:`.
- **Alternatives considered**: A flat schema with provider-prefixed key names
  (e.g. `launchdarkly_project_key`) — rejected as it does not scale to
  multiple providers coexisting in the schema documentation and is a worse
  fit for FR-002's explicit pluggability requirement.

## Decision: No test framework / contract tests for this feature

- **Decision**: Validation is via a YAML-parse + secret-inspection check on
  the template, plus a real resolution check using the installed
  `ConfigManager` class directly (see quickstart.md) — not a bespoke unit
  test suite.
- **Rationale**: This feature produces no executable code of its own; the
  authoritative merge behavior already exists in the installed CLI. The
  quickstart's validation calls that real class directly rather than
  re-implementing (and potentially drifting from) its merge algorithm.
- **Alternatives considered**: A hand-rolled Python re-implementation of the
  layering logic for testing — rejected as redundant and a drift risk; using
  the real `ConfigManager` is both simpler and more faithful.
