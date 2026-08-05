# Contract: Rollout Gate Script CLI

This is the external interface both gate script implementations
(`scripts/bash/rollout-gate.sh` and `scripts/powershell/rollout-gate.ps1`)
must satisfy identically. Callers — today, manual verification per
quickstart.md; in the future, the seven `brief-*.md` briefing commands — only
need to depend on this contract, never on the scripts' internal parsing
logic.

## Invocation

```bash
scripts/bash/rollout-gate.sh [--mode default|analyze]
```

```powershell
scripts/powershell/rollout-gate.ps1 [-Mode default|analyze]
```

- No argument is required; omitting the mode flag is equivalent to
  `--mode default` / `-Mode default`.
- `default` mode searches only the resolved feature's `spec.md` for the
  marker (FR-005).
- `analyze` mode additionally searches `plan.md` and/or `tasks.md` in the
  same resolved feature directory (FR-006) — `spec.md` is still checked
  first; the first file (in the order `spec.md`, `plan.md`, `tasks.md`) that
  contains the marker heading is reported as `source`.
- Neither script reads any other argument, flag, or stdin input. Both
  scripts resolve the feature directory and configuration themselves (see
  data-model.md) — no path or config location is ever passed in by the
  caller, so gate state can never accidentally be pointed at another
  feature's directory.

## Output (stdout)

One `key=value` pair per line, in this fixed field order, always all four
fields present on every invocation regardless of outcome:

```text
hasFlags=<true|false>
flags=<comma-separated flag names, or empty>
source=<spec.md|plan.md|tasks.md|(empty)>
hooksEnabled=<true|false>
```

Example — marker present, hooks enabled, default mode:

```text
hasFlags=true
flags=checkout_v2
source=spec.md
hooksEnabled=true
```

Example — no marker (or hooks disabled):

```text
hasFlags=false
flags=
source=
hooksEnabled=false
```

Diagnostic messages (e.g., "feature directory could not be resolved") are
written to **stderr**, never mixed into the four stdout fields above, so a
caller reading stdout can always rely on exactly four lines.

## Exit codes

| Code | Meaning | `hasFlags` | When a briefing command sees this code |
|---|---|---|---|
| `0` | Rollout — marker present and hooks enabled | `true` | Proceed with phase-specific doctrine (doctrine content out of scope for this feature) |
| `1` | No rollout — marker absent, or hooks disabled, or both | `false` | Emit the one-line no-op and stop (FR-008, FR-011) |
| `2` | Diagnostic — feature directory could not be resolved | `false` (fail-safe) | Treat identically to code `1` (no-op and stop); the distinct code exists so a caller that wants to log/alert on this specific condition can, without it ever blocking normal operation (FR-010, spec.md edge case) |

Callers that only need "proceed vs. stop" MAY treat any non-zero exit code as
"stop" (codes `1` and `2` both mean "no-op"); callers that want to
distinguish "cleanly no rollout" from "could not even determine" MAY branch
on code `2` specifically.

## Cross-implementation equivalence

For the same resolved feature directory, the same file contents, and the
same resolved configuration, both scripts MUST produce:

- the same `hasFlags` value,
- the same `flags` value (same set of names; ordering may follow each
  script's natural text-scan order and is not itself part of the contract),
- the same `source` value,
- the same `hooksEnabled` value,
- the same exit code.

(FR-013, spec.md SC-004)

## Non-goals of this contract

- No contract for the phase-specific doctrine text a briefing command emits
  when `hasFlags=true` — that is authored by each per-phase feature named in
  vision.md 5.1.
- No contract for how a briefing command is wired to invoke this script
  (e.g., which markdown instructions call it) — deferred to those same
  per-phase features.
- No `--json` or alternate output-format flag — plain `key=value` lines are
  the only supported output shape in this feature (research.md).
