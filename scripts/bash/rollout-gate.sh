#!/usr/bin/env bash
# rollout-gate.sh — Self-gating state check shared by every rollout hook.
#
# Usage:
#   scripts/bash/rollout-gate.sh [--mode default|analyze]
#
# Resolves the current feature directory, searches for the literal
# "## Delivery Considerations" marker heading (spec.md only in "default"
# mode; spec.md, then plan.md, then tasks.md, first match wins, in
# "analyze" mode), folds in the resolved `hooks.enabled` configuration
# toggle as an override, and prints a fixed four-line machine-readable
# result to stdout, always in this order:
#
#   hasFlags=<true|false>
#   flags=<comma-separated candidate flag names, or empty>
#   source=<spec.md|plan.md|tasks.md|(empty)>
#   hooksEnabled=<true|false>
#
# Diagnostic messages go to stderr only — stdout always carries exactly
# the four lines above.
#
# Exit codes:
#   0 = rollout (marker present and hooks enabled)
#   1 = no rollout (marker absent, or hooks disabled)
#   2 = diagnostic: feature directory could not be resolved (fail-safe,
#       treated identically to exit 1 by callers that don't care to
#       distinguish it)
#
# See specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md for
# the full contract both this script and rollout-gate.ps1 must satisfy
# identically.

set -u

MODE="default"

while [ $# -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:-default}"
      shift 2
      ;;
    --mode=*)
      MODE="${1#--mode=}"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ "$MODE" != "default" ] && [ "$MODE" != "analyze" ]; then
  MODE="default"
fi

# --- Locate the Spec Kit project root by walking upward for a .specify/ dir ---
find_specify_root() {
  dir="$PWD"
  while :; do
    if [ -d "$dir/.specify" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    parent=$(dirname "$dir")
    if [ "$parent" = "$dir" ]; then
      return 1
    fi
    dir="$parent"
  done
}

SPECIFY_ROOT=""
if root=$(find_specify_root); then
  SPECIFY_ROOT="$root"
fi

# --- Read feature.json's feature_directory key: jq -> python3 -> grep/sed ---
read_feature_json_dir() {
  feature_json="$1"
  [ -f "$feature_json" ] || return 1

  if command -v jq >/dev/null 2>&1; then
    value=$(jq -r '.feature_directory // empty' "$feature_json" 2>/dev/null)
  elif command -v python3 >/dev/null 2>&1; then
    value=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    v = data.get("feature_directory", "")
    if v:
        print(v)
except Exception:
    pass
' "$feature_json" 2>/dev/null)
  else
    value=$(grep -o '"feature_directory"[[:space:]]*:[[:space:]]*"[^"]*"' "$feature_json" 2>/dev/null \
      | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/' | head -n1)
  fi

  if [ -n "${value:-}" ]; then
    printf '%s\n' "$value"
    return 0
  fi
  return 1
}

# --- Resolve the feature directory ---
FEATURE_DIR=""
RESOLVED=0

if [ -n "${SPECIFY_FEATURE_DIRECTORY:-}" ]; then
  case "$SPECIFY_FEATURE_DIRECTORY" in
    /*) FEATURE_DIR="$SPECIFY_FEATURE_DIRECTORY" ;;
    *)
      if [ -n "$SPECIFY_ROOT" ]; then
        FEATURE_DIR="$SPECIFY_ROOT/$SPECIFY_FEATURE_DIRECTORY"
      else
        FEATURE_DIR="$SPECIFY_FEATURE_DIRECTORY"
      fi
      ;;
  esac
  RESOLVED=1
elif [ -n "$SPECIFY_ROOT" ] && rel_dir=$(read_feature_json_dir "$SPECIFY_ROOT/.specify/feature.json"); then
  case "$rel_dir" in
    /*) FEATURE_DIR="$rel_dir" ;;
    *) FEATURE_DIR="$SPECIFY_ROOT/$rel_dir" ;;
  esac
  RESOLVED=1
fi

emit_result() {
  printf 'hasFlags=%s\n' "$1"
  printf 'flags=%s\n' "$2"
  printf 'source=%s\n' "$3"
  printf 'hooksEnabled=%s\n' "$4"
}

if [ "$RESOLVED" -ne 1 ]; then
  echo "rollout-gate: could not resolve the current feature directory (no SPECIFY_FEATURE_DIRECTORY env var and no readable .specify/feature.json)" >&2
  emit_result "false" "" "" "true"
  exit 2
fi

# --- Resolve hooks.enabled: extension defaults -> project config -> local override -> env var ---
# Each YAML layer is read with a small, indentation-aware line scan for a
# `hooks:` key (at whatever nesting depth it appears in that file) followed
# by an `enabled:` key indented under it — no YAML library required.
extract_hooks_enabled() {
  file="$1"
  [ -f "$file" ] || return 1
  awk '
    function indent_of(s,    i, c, n) {
      n = length(s)
      i = 0
      while (i < n) {
        c = substr(s, i + 1, 1)
        if (c == " ") { i++ } else { break }
      }
      return i
    }
    /^[[:space:]]*hooks:[[:space:]]*$/ {
      if (!in_hooks) {
        hooks_indent = indent_of($0)
        in_hooks = 1
      }
      next
    }
    in_hooks {
      if ($0 ~ /^[[:space:]]*$/) { next }
      cur_indent = indent_of($0)
      if (cur_indent <= hooks_indent) {
        in_hooks = 0
        next
      }
      if ($0 ~ /^[[:space:]]*enabled:[[:space:]]*/) {
        val = $0
        sub(/^[[:space:]]*enabled:[[:space:]]*/, "", val)
        sub(/[[:space:]]*#.*$/, "", val)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        if (val != "") {
          print val
          exit
        }
      }
    }
  ' "$file" 2>/dev/null
}

normalize_bool() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    true|1|yes) printf 'true\n'; return 0 ;;
    false|0|no) printf 'false\n'; return 0 ;;
    *) return 1 ;;
  esac
}

HOOKS_ENABLED="true"

if [ -n "$SPECIFY_ROOT" ]; then
  for layer_file in \
    "$SPECIFY_ROOT/.specify/extensions/rollout/extension.yml" \
    "$SPECIFY_ROOT/.specify/extensions/rollout/rollout-config.yml" \
    "$SPECIFY_ROOT/.specify/extensions/rollout/local-config.yml"; do
    if raw=$(extract_hooks_enabled "$layer_file") && [ -n "$raw" ]; then
      if norm=$(normalize_bool "$raw"); then
        HOOKS_ENABLED="$norm"
      fi
    fi
  done
fi

if [ -n "${SPECKIT_ROLLOUT_HOOKS_ENABLED:-}" ]; then
  if norm=$(normalize_bool "$SPECKIT_ROLLOUT_HOOKS_ENABLED"); then
    HOOKS_ENABLED="$norm"
  fi
fi

# --- Marker search: literal "## Delivery Considerations" heading line ---
has_marker() {
  file="$1"
  [ -f "$file" ] || return 1
  grep -Eq '^## Delivery Considerations[[:space:]]*$' "$file" 2>/dev/null
}

extract_flags_line() {
  file="$1"
  awk '
    /^## Delivery Considerations[[:space:]]*$/ { in_section = 1; next }
    in_section && /^## / { in_section = 0 }
    in_section {
      lower = tolower($0)
      if (match(lower, /candidate flag\(s\):/)) {
        rest = substr($0, RSTART + RLENGTH)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", rest)
        print rest
        exit
      }
    }
  ' "$file" 2>/dev/null
}

if [ "$MODE" = "analyze" ]; then
  search_files="spec.md plan.md tasks.md"
else
  search_files="spec.md"
fi

SOURCE=""
FLAGS=""
MARKER_FOUND=0

for fname in $search_files; do
  candidate="$FEATURE_DIR/$fname"
  if has_marker "$candidate"; then
    MARKER_FOUND=1
    SOURCE="$fname"
    FLAGS=$(extract_flags_line "$candidate")
    break
  fi
done

if [ "$HOOKS_ENABLED" = "false" ]; then
  emit_result "false" "" "" "false"
  exit 1
fi

if [ "$MARKER_FOUND" -eq 1 ]; then
  emit_result "true" "$FLAGS" "$SOURCE" "$HOOKS_ENABLED"
  exit 0
fi

emit_result "false" "" "" "$HOOKS_ENABLED"
exit 1
