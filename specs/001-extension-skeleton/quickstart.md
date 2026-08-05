# Quickstart: Validating the Rollout Extension Skeleton

Prerequisites: the `specify` CLI installed and on `PATH` (already the case in
this environment — `specify` resolves via `uv tool install specify-cli`), and
this repository checked out with the package files at its root (see
[plan.md](./plan.md) Project Structure).

## 1. Install in development mode (User Story 1 / SC-001)

From a Spec Kit-initialized project (this repo, or any other project with
`.specify/`), run:

```bash
specify extension add . --dev
```

**Expected**: command exits successfully with no validation errors printed.
If it reports a `ValidationError`, the manifest or a referenced file is wrong
— see [contracts/extension-manifest.md](./contracts/extension-manifest.md)
for the exact required shape.

## 2. Confirm registration (User Story 2 / SC-002, SC-003)

```bash
specify extension list
```

**Expected**: an entry for `rollout` showing
`Commands: 8 | Hooks: 7 | Priority: <n> | Status: Enabled`.

For a stricter, scriptable check of naming and file-existence (SC-003,
SC-004), lint the manifest directly:

```bash
python3 - <<'PY'
import re, sys, yaml
from pathlib import Path

manifest = yaml.safe_load(Path("extension.yml").read_text())
pattern = re.compile(r"^speckit\.rollout\.[a-z0-9-]+$")

commands = manifest["provides"]["commands"]
assert len(commands) == 8, f"expected 8 commands, got {len(commands)}"
for cmd in commands:
    assert pattern.match(cmd["name"]), f"bad command name: {cmd['name']}"
    assert Path(cmd["file"]).is_file(), f"missing command file: {cmd['file']}"

hooks = manifest["hooks"]
assert len(hooks) == 7, f"expected 7 hooks, got {len(hooks)}"
for event, hook in hooks.items():
    assert hook["optional"] is False, f"hook {event} must be optional: false"

for cfg in manifest["provides"].get("config", []):
    if cfg.get("template"):
        assert Path(cfg["template"]).is_file(), f"missing config template: {cfg['template']}"

print("OK: 8 commands, 7 hooks, all referenced files present")
PY
```

**Expected**: prints `OK: 8 commands, 7 hooks, all referenced files present`.

## 3. Remove cleanly (User Story 3 / SC-005)

```bash
specify extension remove rollout
specify extension list
```

**Expected**: the removal command succeeds; the subsequent `list` no longer
shows `rollout`, and no `speckit.rollout.*` commands or `before_*` hooks
remain registered in the project's `.specify/extensions.yml` (or equivalent
project config) afterward.

## Notes

- These three steps map directly to the spec's three user stories and five
  success criteria — see [spec.md](./spec.md).
- No doctrine content is exercised by this quickstart: the placeholder
  command files only need to exist and be referenced correctly, per the
  feature's explicit scope boundary.
