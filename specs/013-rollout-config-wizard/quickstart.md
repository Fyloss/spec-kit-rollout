# Quickstart: Verifying the Rollout Config Wizard

This guide walks through validating `commands/config.md` and
`commands/provider.md` against the user stories and edge cases in spec.md,
using fixture files and text-based read-throughs rather than a real MCP
server connection or a real LaunchDarkly token (consistent with
Constitution Principle V and Features 004-012's verification approach).

## Prerequisites

- Repository checked out locally with `commands/config.md` and
  `commands/provider.md` written per this feature's tasks.md.
- A scratch working directory (not committed) to simulate a target project.
- Optional, read-only reference: this repository's own `.vscode/mcp.json`
  (a real, already-configured **hosted** LaunchDarkly MCP server) may be
  consulted to see what a real hosted-branch capability result looks like.
  No real token is ever read, stored, or required for any scenario below —
  every scenario uses simulated/fixture MCP responses.

## Scenario 1 — Hosted branch, happy path (User Story 1, P1)

**Setup**: Simulate a single introspected MCP server whose live
project-listing probe (step 3) succeeds and returns two projects, each with
two environments.

**Read-through check**: Confirm `commands/config.md` instructs, in order:
(1) discover the one candidate server, skip disambiguation; (2) probe →
success-with-data → classify `hosted`; (3) present the two projects, then
the selected project's two environments; (4) perform read verification
against the selection; (5) show a full summary and require explicit
confirmation; (6) write a `provider: launchdarkly` block with
`project_key`, `environments`, `server_type: hosted` — no `mcp.*` field
anywhere; (7) report the branch taken and values written.

## Scenario 2 — Zero candidates detected (User Story 2, P1)

**Setup**: Simulate no introspected MCP servers at all.

**Read-through check**: Confirm the doctrine stops immediately after step 1
with clear guidance, writes no file, and performs no further steps
(including no server-type probe).

## Scenario 3 — Multiple candidates require disambiguation (User Story 3)

**Setup**: Simulate two introspected MCP servers.

**Read-through check**: Confirm the doctrine asks the developer to pick one
before proceeding to step 3, and that the unselected server is never probed.

## Scenario 4 — Local branch, manual entry (User Story 7)

**Setup**: Simulate a single candidate server whose live project-listing
probe (step 3) returns a clean "capability not found" result.

**Read-through check**: Confirm classification is `local`; confirm the
doctrine prompts for manual project ID and environment key entry (no
placeholder values suggested); confirm read verification is attempted
against the typed values; confirm the written block includes
`server_type: local`.

## Scenario 5 — Local branch, explicit opt-out (User Story 7)

**Setup**: Same as Scenario 4, but the developer chooses the opt-out option
instead of typing values.

**Read-through check**: Confirm no project ID or environment key is written
(absent, never a fabricated placeholder); confirm read verification is
explicitly skipped, with a clear note recorded in the final report (not
silently omitted); confirm the final summary/confirmation step still runs
before any write.

## Scenario 6 — Ambiguous/timeout probe treated as local (Edge Case)

**Setup**: Simulate the step-3 probe returning a timeout or an
unclassifiable transport error (neither a clean success-with-data nor a
clean not-found).

**Read-through check**: Confirm the doctrine classifies this as `local`
(never blocks, never asks the developer to resolve the ambiguity itself)
and proceeds to the local branch (Scenario 4/5's flow).

## Scenario 7 — Read verification failure (Edge Case)

**Setup**: Simulate a resolved project/environment (hosted or local) whose
read-verification check fails.

**Read-through check**: Confirm the doctrine presents the failure and asks
the developer to cancel or explicitly continue anyway — never silently
proceeding as if verification passed, and never writing a file until that
choice is made.

## Scenario 8 — Idempotent re-run changing one selection (User Story 5)

**Setup**: Reuse Scenario 1's resulting `rollout-config.yml`. Re-run the
wizard, this time selecting a different environment for the same project.

**Read-through check**: Confirm the existing `launchdarkly:` block's
`environments` value is updated in place — no duplicate block, no other
field disturbed, `server_type` re-verified fresh (not reused from the
prior run's stored value) even though it resolves to the same `hosted`
result.

## Scenario 9 — Provider switch reusing an existing block (User Story 6)

**Setup**: Reuse Scenario 1's resulting `rollout-config.yml` (provider:
launchdarkly). Add a second, pre-existing `unleash:` block by hand (fixture
setup only, not written by this feature). Run
`speckit.rollout.provider unleash`.

**Read-through check**: Confirm only the top-level `provider:` field
changes to `unleash`; confirm neither the `launchdarkly:` nor `unleash:`
block's contents are modified; confirm no re-prompting occurs since a block
already exists.

## Scenario 10 — Provider switch triggering a new preset (User Story 6)

**Setup**: Reuse Scenario 1's resulting `rollout-config.yml`. Run
`speckit.rollout.provider unleash` where no `unleash:` block exists yet.

**Read-through check**: Confirm the doctrine runs `unleash`'s own preset
flow (in V1, since only `launchdarkly` has a real preset, confirm the
doctrine states this clearly rather than fabricating an `unleash` preset);
confirm the existing `launchdarkly:` block is left untouched either way.
