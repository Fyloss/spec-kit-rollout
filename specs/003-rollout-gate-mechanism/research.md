# Research: Rollout Gate Mechanism

The feature input named the mechanism's shape (marker heading, two scripts,
`hooks.enabled` override, machine-readable result + exit code) but left the
exact matching/parsing implementation open. Four decisions were needed before
design: how to resolve the current feature directory without depending on
core internals, how to read the single `hooks.enabled` field without a YAML
library, how to encode the marker's candidate-flag names so they are
extractable, and what output shape both script implementations must agree on.

## Decision: Feature-directory resolution — self-contained, not sourced from core

- **Decision**: `rollout-gate.sh` / `rollout-gate.ps1` resolve the current
  feature directory themselves, using the same two-step precedence Spec Kit's
  own scripts use (verified in `.specify/scripts/bash/common.sh`'s
  `get_feature_paths`): (1) `SPECIFY_FEATURE_DIRECTORY` env var if set: (2)
  else read the `feature_directory` key from `.specify/feature.json` at the
  repository root (found by walking upward for a `.specify/` directory,
  mirroring `find_specify_root`). Parsing `feature.json` prefers `jq`, falls
  back to `python3`, falls back to a `grep`/`sed` one-liner — the same
  fallback order `common.sh`'s `read_feature_json_feature_directory` uses.
- **Rationale**: This keeps the gate scripts fully self-contained. Extensions
  are not documented as being able to `source` core's `.specify/scripts/bash/`
  files, and core's own repo-memory notes (`spec-kit-extension-schema.md`)
  record that extension behavior must be verified from installed CLI source
  rather than assumed — there is no stated compatibility contract for an
  extension depending on core's internal function names or file layout across
  `specify-cli` versions. Reimplementing the same ~15-line resolution
  (env var → JSON key, with a tool fallback chain) is small, stable surface
  area (`.specify/feature.json`'s shape is part of the documented per-feature
  state Spec Kit itself relies on) and avoids a fragile cross-package
  dependency.
- **Alternatives considered**: Sourcing `.specify/scripts/bash/common.sh`
  directly — rejected: no compatibility guarantee, and the PowerShell gate
  script would have no equivalent core file to source from at all (core only
  ships bash-flavored scripts in this installed version), which would make
  the two implementations asymmetric. Shelling out to `specify` CLI to ask
  for the feature directory — rejected: no such subcommand exists in the
  installed CLI surface today, and it would add a process-spawn + CLI
  version dependency for a one-line JSON read.

## Decision: `hooks.enabled` resolution — single-field text extraction, no YAML library

- **Decision**: Both scripts resolve `hooks.enabled` by checking, in
  ascending precedence (matching 002-config-system's documented resolution
  contract): (1) extension defaults at
  `.specify/extensions/rollout/extension.yml`'s `hooks:` block; (2) project
  config `.specify/extensions/rollout/rollout-config.yml`'s `hooks:` block;
  (3) local override `.specify/extensions/rollout/local-config.yml`'s
  `hooks:` block; (4) the `SPECKIT_ROLLOUT_HOOKS_ENABLED` env var. Each
  YAML-file layer is read with a small, purpose-built line scan (find the
  top-level `hooks:` line, then the next indented `enabled:` line before the
  next top-level key) rather than a general YAML parser. A layer that is
  absent, unreadable, or does not contain the key contributes nothing (falls
  through). The env var, if set, is compared case-insensitively against
  `false`/`0`/`no` (→ disabled) and `true`/`1`/`yes` (→ enabled); any other
  value is treated as unset (falls through), per data-model.md's documented
  "non-boolean values fall back to the safe default" rule. If no layer
  resolves the value, the default is `true` (enabled).
- **Rationale**: 002-config-system's `rollout-config-schema.md` contract
  explicitly delegates this: "No behavioral contract for how a gate script
  parses/validates `hooks.enabled`'s invalid-value fallback... the parsing
  implementation belongs to the feature that ships the gate script" — this
  feature. A full YAML parser is unnecessary for one boolean field at a known
  shallow nesting depth, and avoiding one keeps the scripts dependency-free
  (no `pyyaml`, no `yq` binary requirement) on both platforms, consistent
  with the marker's own "deterministic text match" design philosophy already
  used for `## Delivery Considerations` detection.
- **Alternatives considered**: Invoking the installed `specify_cli.extensions.ConfigManager`
  Python class directly (as 002-config-system's own quickstart does for
  verification) — rejected as the runtime resolution path: it requires
  locating the CLI's bundled interpreter, is far heavier than reading one
  boolean, and would make the gate script's exit code depend on Python/
  `specify-cli` being importable at hook-invocation time, which is not
  guaranteed in every environment a hook fires in. A full embedded YAML
  parser (e.g., a bash YAML-to-shell-vars snippet) — rejected as unnecessary
  complexity for a single, shallow, well-known field.

## Decision: Candidate-flag sub-convention within the marker

- **Decision**: Within the `## Delivery Considerations` section, a line
  matching (case-insensitively, ignoring leading list/markdown punctuation)
  `Candidate flag(s): <name>[, <name>...]` is the extraction target for
  candidate flag names. The heading alone is sufficient for `hasFlags=true`;
  the `Candidate flag(s):` line is optional — if absent, the gate still
  reports `hasFlags=true` with an empty flags list (per spec.md's edge case:
  "marker presence, not flag-name presence, is the gating signal").
- **Rationale**: The feature input requires the marker to contain "candidate
  flag name(s) and rollout intent" and requires the gate's output to include
  "candidate flag names" (FR-001, FR-009) — this is impossible without some
  structural convention narrower than free prose. Defining a single,
  optional, clearly labeled line is a small, additive convention (not
  "doctrine" about when/why to write a flag name — that heuristic content is
  explicitly out of scope) that stays human-readable and greppable, matching
  the marker heading's own design.
- **Alternatives considered**: An HTML comment carrying structured data
  (e.g., `<!-- rollout:flags=foo,bar -->`) — rejected: vision.md 5.1
  describes the marker as "both natural spec content and the state signal,"
  and an invisible HTML comment is a poor fit for "clearly labeled,
  human-readable" (spec.md FR-001); it would also read as an implementation
  detail bleeding into a document meant for human review. A YAML frontmatter
  block inside `spec.md` — rejected: `spec.md`'s body is prose/markdown
  throughout (per `spec-template.md`), and a frontmatter-style block
  mid-document would be inconsistent with the rest of the artifact and with
  how the extension's own `commands/*.md` frontmatter is used only at the
  very top of a file.

## Decision: Machine-readable output shape

- **Decision**: Both scripts print one `key=value` pair per line to stdout
  (e.g. `hasFlags=true`, `flags=flag_a,flag_b`, `source=spec.md`,
  `hooksEnabled=true`), and terminate with a distinct exit code per outcome
  (documented in `contracts/rollout-gate-cli.md`). Exit code is the primary
  branch signal (FR-010/SC-005); the printed lines are for diagnostics and
  for candidate-flag content, which cannot be encoded in an exit code alone.
- **Rationale**: `key=value` lines require no parsing library on either
  platform (`grep`/`cut` in bash, `-split '='` in PowerShell, or simply
  reading the lines directly as an AI agent executing the command), matching
  the project's existing "no new dependency" posture (see 002-config-system's
  Technical Context: "this feature does not introduce a config loader of its
  own"). It is also trivially human-readable, useful since the direct caller
  in most real invocations is an AI agent reading command output as text, not
  a strict machine parser.
- **Alternatives considered**: JSON output — rejected as the default: it
  would be the first place in the extension that expects a JSON parser
  (`jq`/`python3 -m json.tool`) purely to read one boolean and a short flag
  list, adding a dependency this feature does not otherwise need. (Nothing
  in this feature precludes a future `--json` flag being added by a later
  feature if a real consumer needs it; out of scope here since no such
  consumer exists yet.)

## Depends-on note: 002-config-system's schema is not yet applied to repo-root files

- **Observation**: `specs/002-config-system/tasks.md` marks its schema
  migration tasks (T002-T005) complete, but the repository's actual root
  `rollout-config.template.yml` and `extension.yml` still contain the flat
  001-placeholder shape (`hooks_enabled`, not the nested `hooks.enabled`)
  as of this feature's planning. This is a pre-existing gap in
  002-config-system's applied state, not something this feature causes or
  fixes.
- **Impact on this feature**: None on the *design* — this feature's gate
  scripts are written against the documented, authoritative contract
  (`contracts/rollout-config-schema.md`'s nested `hooks.enabled` shape),
  which is what every future real config file (once 002 is actually applied)
  will conform to. Implementation/task generation for this feature should
  note the dependency explicitly and, if 002's root files are still
  unmigrated when this feature's tasks run, either treat it as a blocking
  prerequisite to re-verify or test the resolution logic against a staged
  fixture config rather than the (currently stale) repo-root files.
