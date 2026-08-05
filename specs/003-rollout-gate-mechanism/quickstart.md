# Quickstart: Validating the Rollout Gate Mechanism

Prerequisites: this repository checked out, with `scripts/bash/rollout-gate.sh`
and `scripts/powershell/rollout-gate.ps1` implemented per
[contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md), run from the
repository root (or any subdirectory — both scripts resolve the repo root by
walking upward for `.specify/`, per [data-model.md](./data-model.md)).

These steps use small, disposable fixture feature directories under `specs/`
so verification never depends on — or mutates — this repository's own real
feature specs (001/002/003).

## 1. Marker absent → `hasFlags=false` (User Story 1 / SC-002)

```bash
mkdir -p specs/999-gate-fixture-no-marker
cat > specs/999-gate-fixture-no-marker/spec.md <<'EOF'
# Feature Specification: Fixture

No delivery considerations here.
EOF

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-no-marker scripts/bash/rollout-gate.sh
echo "exit=$?"
# Expect: hasFlags=false / flags= / source= / hooksEnabled=true (default) / exit=1
```

Repeat with the PowerShell script (`pwsh scripts/powershell/rollout-gate.ps1`,
with `$env:SPECIFY_FEATURE_DIRECTORY` set the same way) and confirm identical
output fields and exit code.

## 2. Marker present → `hasFlags=true` + flag name(s) (User Story 2 / SC-001)

```bash
mkdir -p specs/999-gate-fixture-marker
cat > specs/999-gate-fixture-marker/spec.md <<'EOF'
# Feature Specification: Fixture

## Delivery Considerations

This change touches payment processing and should roll out gradually.

Candidate flag(s): checkout_v2

## Requirements
EOF

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-marker scripts/bash/rollout-gate.sh
echo "exit=$?"
# Expect: hasFlags=true / flags=checkout_v2 / source=spec.md / hooksEnabled=true / exit=0
```

Vary the surrounding prose/punctuation around the heading and confirm
detection still succeeds (spec.md acceptance scenario 3) — only the literal
`## Delivery Considerations` heading line matters.

## 3. Hooks disabled overrides a present marker (User Story 3 / SC-003)

```bash
mkdir -p .specify/extensions/rollout
cat > .specify/extensions/rollout/rollout-config.yml <<'EOF'
hooks:
  enabled: false
EOF

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-marker scripts/bash/rollout-gate.sh
echo "exit=$?"
# Expect: hasFlags=false / hooksEnabled=false / exit=1, identical to step 1's
# "no marker" case, even though the marker is present.

rm .specify/extensions/rollout/rollout-config.yml
```

## 4. Analyze mode finds the marker in `plan.md` (User Story 4)

```bash
mkdir -p specs/999-gate-fixture-plan-only
cat > specs/999-gate-fixture-plan-only/spec.md <<'EOF'
# Feature Specification: Fixture
No marker here.
EOF
cat > specs/999-gate-fixture-plan-only/plan.md <<'EOF'
## Delivery Considerations
Candidate flag(s): checkout_v2
EOF

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-plan-only scripts/bash/rollout-gate.sh --mode analyze
echo "exit=$?"
# Expect: hasFlags=true / source=plan.md / exit=0

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-plan-only scripts/bash/rollout-gate.sh
echo "exit=$?"
# Expect (default mode, same fixture): hasFlags=false / exit=1 — plan.md is
# not consulted outside analyze mode.
```

## 5. Feature directory unresolved → fail-safe

```bash
env -u SPECIFY_FEATURE_DIRECTORY scripts/bash/rollout-gate.sh
echo "exit=$?"
# Run from a directory/state where .specify/feature.json cannot resolve a
# feature: expect hasFlags=false and exit=2 (see contracts/rollout-gate-cli.md).
```

## 6. Cross-platform parity (SC-004)

Run steps 1-4 with both `scripts/bash/rollout-gate.sh` (Linux/macOS) and
`scripts/powershell/rollout-gate.ps1` (Windows PowerShell or `pwsh`) against
the same fixtures and confirm every field and exit code matches, per
[contracts/rollout-gate-cli.md](./contracts/rollout-gate-cli.md)'s
cross-implementation equivalence requirement.

## 7. Per-feature isolation across concurrently existing features (SC-006)

```bash
mkdir -p specs/999-gate-fixture-a specs/999-gate-fixture-b
cat > specs/999-gate-fixture-a/spec.md <<'EOF'
# Feature Specification: Fixture A

## Delivery Considerations
Candidate flag(s): flag_a
EOF
cat > specs/999-gate-fixture-b/spec.md <<'EOF'
# Feature Specification: Fixture B

No delivery considerations here.
EOF

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-a scripts/bash/rollout-gate.sh
echo "exit=$?"
# Expect: hasFlags=true / flags=flag_a / source=spec.md / exit=0 — unaffected
# by fixture B's absent marker existing at the same time.

SPECIFY_FEATURE_DIRECTORY=specs/999-gate-fixture-b scripts/bash/rollout-gate.sh
echo "exit=$?"
# Expect: hasFlags=false / exit=1 — unaffected by fixture A's marker existing
# at the same time.
```

Repeat both invocations with `scripts/powershell/rollout-gate.ps1` and confirm
the same per-feature isolation.

## Cleanup

```bash
rm -rf specs/999-gate-fixture-no-marker specs/999-gate-fixture-marker specs/999-gate-fixture-plan-only specs/999-gate-fixture-a specs/999-gate-fixture-b
rmdir .specify/extensions/rollout 2>/dev/null || true
```
