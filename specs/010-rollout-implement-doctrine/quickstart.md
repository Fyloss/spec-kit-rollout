# Quickstart: Verifying the Rollout Implement Doctrine

This guide walks through validating `commands/brief-implement.md` against
the four user stories in spec.md, using text-based checks rather than a live
LaunchDarkly MCP server (no real MCP connection or token is used anywhere in
this guide, consistent with Constitution Principle V and Features 004-009's
verification approach).

## Prerequisites

- Repository checked out locally with `commands/brief-implement.md` rewritten
  per this feature's tasks.md.
- `scripts/bash/rollout-gate.sh` (or `scripts/powershell/rollout-gate.ps1` on
  Windows) present and executable.
- No git commits are required to exist in this repo (consistent with prior
  features' notes — working tree only).

## Scenario 1 — Full chain present, MCP reachable (User Story 1, P1)

**Setup**: Create a scratch fixture feature directory, e.g.
`specs/999-quickstart-fixture/`, with:
- `spec.md` containing the exact `## Delivery Considerations` marker +
  `Candidate flag(s): checkout_v2` line (Feature 003/004 contract).
- `plan.md` containing a `## Delivery Strategy` section naming
  `checkout_v2`, environments, targeting, telemetry gates, and rollback
  conditions (Feature 006 shape).
- `tasks.md` containing the six rollout task categories for `checkout_v2`
  (Feature 007 shape).

**Run**:

```bash
SPECIFY_FEATURE_DIRECTORY="$(pwd)/specs/999-quickstart-fixture" \
  scripts/bash/rollout-gate.sh
```

**Expected**: `hasFlags=true`, `flags=checkout_v2`, `source=spec.md`.

**Read-through check**: Confirm `commands/brief-implement.md` instructs, in
order: (1) run the gate script; (2) on `hasFlags=true`, scan `tasks.md` for
rollout task presence; (3) on presence, introspect the pinned MCP server via
`tools/list`/`resources/list`/`prompts/list` before binding any tool; (4) bind
all seven provider-neutral intents to advertised tools; (5) execute
create-flag/configure-environments/configure-targeting using parameters
traceable to `plan.md`'s Delivery Strategy and `tasks.md`'s rollout tasks,
never invented or re-derived from `spec.md` alone.

## Scenario 2 — Guardrails (User Story 2, P1)

**Read-through check**: Confirm two distinct, standalone instruction
paragraphs exist in `commands/brief-implement.md`:

1. A production-exposure guardrail: never invoke a tool that would advance
   live production exposure (percentage increase already serving production
   traffic, or enabling a flag in a production environment) beyond what the
   current task/plan specifies, unless the user has explicitly instructed
   that specific advance in the current session.
2. A token-handling guardrail: never read, echo, log, or inline the provider
   API token under any circumstance; the doctrine text itself contains no
   token value or placeholder resembling one.

**Verification command**:

```bash
grep -in "token" commands/brief-implement.md
```

**Expected**: Every match is an instruction *about* not handling tokens (e.g.,
"never read, echo, log, or inline the provider API token"), never a literal
token value, example token string, or environment-variable value.

## Scenario 3 — Non-rollout feature (User Story 3, P1)

**Setup**: Use a fixture feature directory whose `spec.md` has no
`## Delivery Considerations` marker (or reuse the "no-marker" fixture
pattern from Feature 005's verification, e.g.
`specs/998-quickstart-fixture-no-marker/`).

**Run**:

```bash
SPECIFY_FEATURE_DIRECTORY="$(pwd)/specs/998-quickstart-fixture-no-marker" \
  scripts/bash/rollout-gate.sh
```

**Expected**: `hasFlags=false`.

**Read-through check**: Confirm the doctrine's no-marker branch is a single
line of output text with no MCP introspection, no provider action, and no
plan-only-mode task instruction reachable from that branch.

## Scenario 4 — Graceful degradation, MCP unreachable (User Story 4, P2)

**Setup**: Reuse Scenario 1's fixture (marker + Delivery Strategy + rollout
tasks all present).

**Read-through check**: Confirm the doctrine instructs, when MCP
introspection fails or no server is configured/reachable: (1) do not fail or
halt the overall `/speckit.implement` run; (2) record exactly one task
naming `speckit.rollout.connect` as the remediation step; (3) that task
contains no inline MCP registration/setup steps of its own (reserved for
Feature 011) and no fabricated/simulated provider action in place of the
missing MCP.

## Scenario 5 — Marker present, rollout tasks absent (Edge Case)

**Setup**: Fixture with `spec.md`'s marker present but `tasks.md` containing
none of Feature 007's six rollout task categories (e.g., `/speckit.tasks`
never run, or run before the marker existed).

**Read-through check**: Confirm the doctrine emits a status message distinct
from both the no-marker message (Scenario 3) and the graceful-degradation
message (Scenario 4), recommending `/speckit.tasks`, and that no MCP
introspection or provider action is attempted from this branch.

## Cleanup

Delete any scratch fixture directories created for this verification (e.g.
`specs/999-quickstart-fixture/`, `specs/998-quickstart-fixture-no-marker/`)
— they are not committed, consistent with Features 004-005's implementation
notes.

## Cross-cutting checks

```bash
# Confirm all seven provider-neutral intents are named
grep -in "discover environments\|discover segments\|create flag\|set targeting\|set percentage rollout\|read flag status\|archive flag" commands/brief-implement.md

# Confirm the pinned-server / no-substitution instruction is present
grep -in "pinned\|substitut" commands/brief-implement.md

# Confirm speckit.rollout.connect is referenced for graceful degradation
grep -n "speckit.rollout.connect" commands/brief-implement.md
```

All three checks are expected to return at least one match each.
