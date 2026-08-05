# Quickstart: Validating the Rollout Configuration System

Prerequisites: the `specify` CLI installed and on `PATH` (already the case in
this environment), and this repository checked out with
`rollout-config.template.yml` and `extension.yml` at its root (see
[plan.md](./plan.md) Project Structure).

Steps 2-5 import `specify_cli.extensions.ConfigManager` directly to exercise
the *real* installed loader. Since `specify-cli` is typically installed into
an isolated tool environment (e.g. via `uv tool install`), resolve its own
bundled interpreter first rather than assuming the system `python3` can
import `specify_cli`:

```bash
SPECIFY_PY="$(sed -n '1s/^#!//p' "$(command -v specify)")"
[ -x "$SPECIFY_PY" ] || SPECIFY_PY=python3
```

## 1. Template parses and contains no secrets (User Story 1 / SC-001, SC-002)

```bash
"$SPECIFY_PY" - <<'PY'
import yaml
from pathlib import Path

data = yaml.safe_load(Path("rollout-config.template.yml").read_text())

assert data["provider"] == "launchdarkly"
assert "project_key" in data["launchdarkly"]
assert isinstance(data["launchdarkly"]["environments"], list)
assert set(data["mcp"]) >= {"command", "args", "version", "repository", "token_env_var"}
assert isinstance(data["hooks"]["enabled"], bool)

# Crude secret-free sanity check: no field's *value* looks like a live token
# (long opaque strings) — this is a smoke check, not the automated
# secret-scanning explicitly out of scope for this feature.
def flat_values(d):
    for v in d.values():
        if isinstance(v, dict):
            yield from flat_values(v)
        elif isinstance(v, list):
            yield from v
        else:
            yield v

for v in flat_values(data):
    if isinstance(v, str):
        assert len(v) < 60 or v.startswith("http"), f"suspiciously long value: {v!r}"

print("OK: template parses, has the full schema, no obviously-secret values")
PY
```

**Expected**: prints `OK: template parses, has the full schema, no
obviously-secret values`.

## 2. Copy template to the resolved project location and confirm it resolves (User Story 1 / SC-001)

```bash
mkdir -p .specify/extensions/rollout
cp extension.yml .specify/extensions/rollout/extension.yml
cp rollout-config.template.yml .specify/extensions/rollout/rollout-config.yml

"$SPECIFY_PY" - <<'PY'
from pathlib import Path
from specify_cli.extensions import ConfigManager

cm = ConfigManager(Path("."), "rollout")
config = cm.get_config()

assert config["provider"] == "launchdarkly"
assert config["hooks"]["enabled"] is True
print("OK: resolved config with no local override or env vars:", config)
PY
```

**Expected**: prints the fully-merged config with `hooks.enabled: True` and
no error — confirms defaults + project layers merge correctly with no local
override or env var present (FR-012 — a missing local file is not an error).

## 3. Disable hooks via the project config (User Story 2 / SC-003)

```bash
"$SPECIFY_PY" - <<'PY'
import yaml
from pathlib import Path

p = Path(".specify/extensions/rollout/rollout-config.yml")
data = yaml.safe_load(p.read_text())
data["hooks"]["enabled"] = False
p.write_text(yaml.safe_dump(data))
PY

"$SPECIFY_PY" - <<'PY'
from pathlib import Path
from specify_cli.extensions import ConfigManager

config = ConfigManager(Path("."), "rollout").get_config()
assert config["hooks"]["enabled"] is False
print("OK: hooks.enabled resolves to False after project-config edit")
PY
```

**Expected**: prints `OK: hooks.enabled resolves to False after
project-config edit`.

## 4. Local override affects only its own field (User Story 3 / SC-004, SC-005)

```bash
cat > .specify/extensions/rollout/local-config.yml <<'YAML'
launchdarkly:
  project_key: my-sandbox-project
YAML

"$SPECIFY_PY" - <<'PY'
from pathlib import Path
from specify_cli.extensions import ConfigManager

config = ConfigManager(Path("."), "rollout").get_config()
assert config["launchdarkly"]["project_key"] == "my-sandbox-project"
assert config["hooks"]["enabled"] is False  # unaffected by the local override
print("OK: local override applies only to project_key; hooks.enabled unchanged")
PY

git check-ignore .specify/extensions/rollout/local-config.yml && \
  echo "OK: local-config.yml is excluded from version control"
```

**Expected**: both `OK:` lines print. The `git check-ignore` check passes in
*this* repository because `.gitignore` already excludes the entire
`.specify/extensions/` tree (this repo's own dev-install artifact rule) —
adopting projects must add their own equivalent rule for
`.specify/extensions/rollout/local-config.yml` (documented in
`rollout-config.template.yml` and `README.md`; see research.md).

## 5. Env var overrides the hooks toggle (FR-007, edge case: env var wins)

```bash
SPECKIT_ROLLOUT_HOOKS_ENABLED=true "$SPECIFY_PY" - <<'PY'
from pathlib import Path
from specify_cli.extensions import ConfigManager

config = ConfigManager(Path("."), "rollout").get_config()
# NOTE: env var values are always raw strings — this is the documented
# limitation from research.md, not a bug in this quickstart.
assert config["hooks"]["enabled"] == "true"
print("OK: env var wins over project config, as a raw string:", config["hooks"]["enabled"])
PY
```

**Expected**: prints `OK: env var wins over project config, as a raw
string: true` — demonstrating both that the env-var layer has the highest
precedence (FR-007) and the string-typing caveat a future gate script must
handle (see research.md and data-model.md's Hooks Toggle entity).

## Cleanup

```bash
rm -rf .specify/extensions/rollout
```

## Notes

- Steps 1-5 map to the spec's three user stories and five success criteria —
  see [spec.md](./spec.md).
- Step 2 onward uses the real installed `ConfigManager` class directly
  (rather than a hand-rolled re-implementation) so this validation stays
  faithful to the actual Spec Kit loader — see research.md.
- No doctrine or gate-script content is exercised here: reading
  `hooks.enabled` from within an actual `before_*` briefing command is a
  later feature's scope (per spec.md's Out of Scope).
