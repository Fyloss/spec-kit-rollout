# Contract: Rollout Config Wizard (`speckit.rollout.config`)

This contract defines the external, observable behavior of the
`speckit.rollout.config` command — the interface an executing agent must
honor and that a verifier (quickstart.md) can check against, independent of
the exact wording of the doctrine text in `commands/config.md`.

## Invocation

- Command name: `speckit.rollout.config` (registered in `extension.yml`
  under `provides.commands`).
- User-invoked only. Never auto-executed by a `before_*` hook (unlike
  Features 004-010's briefing commands).
- Safely re-runnable any number of times (FR-016) — each run is independent;
  no run depends on a prior run's in-memory state (only on the current
  content of `rollout-config.yml`, which it may read to show current values
  before offering to change them).

## Step contract

Step numbering mirrors spec.md's Assumptions section (provider → MCP
detection/selection → automatic server-type detection → project →
environment(s) → read verification → final confirmation) — the same
numbering data-model.md's Rollout Config Wizard Run table uses.

| # | Step | Required outcome |
|---|------|-------------------|
| 1 | Provider selection | Present "LaunchDarkly" as the only selectable provider; any other listed provider name is visibly disabled with a "coming soon" label and not selectable. |
| 2 | Discover MCP servers / resolve candidates | Reads the developer's own MCP client configuration read-only. MUST NOT write, launch, or register any MCP server. Zero candidates → print guidance and stop; zero files written, zero further steps executed. One → proceed automatically. Many → prompt developer to pick one. |
| 3 | Determine server type | Live call to whichever tool lists LaunchDarkly projects. Success-with-data → `hosted`. Clean not-found → `local`. Any other outcome (timeout, ambiguous error) → treated as `local`. MUST NOT be skipped, cached, or reused from a prior run. |
| 4a | Hosted: select project | Present real, live project options; selection must come from that live result set, never invented. |
| 4b | Local: select project | Prompt for manual project ID (freeform, developer-typed), OR an explicit opt-out. MUST NOT fabricate a placeholder value if the developer does not supply one. |
| 5a | Hosted: select environment(s) | Present real, live environment options for the selected project; selection must come from that live result set. |
| 5b | Local: select environment(s) | Prompt for manual environment key(s) (freeform, developer-typed) unless opted out at 4b. MUST NOT fabricate a placeholder value if the developer does not supply one. |
| 6 | Read verification | Attempt a read-only check of the resolved project/environment (skipped only via 4b's explicit opt-out, which must be recorded in the run's outcome text). On failure, ask the developer whether to cancel or continue — MUST NOT silently proceed as if verification passed. |
| 7 | Final confirmation, write, and report | Show a complete summary of what will be written; MUST NOT write anything until the developer explicitly confirms. Once confirmed, write exactly one modular provider block (see data-model.md's Provider Config Block) into `rollout-config.yml` — MUST NOT write any `mcp.*` field (FR-017/FR-019) and MUST NOT touch any other provider's existing block — then report server type determined, branch taken, values written (or the opt-out note), and file path written. |

## Prohibited actions (apply to every step)

- MUST NOT request, read, prompt for, log, or store a credential/token value
  at any point (FR-023).
- MUST NOT launch, install, or modify the developer's MCP client
  configuration (that remains entirely the developer's own responsibility).
- MUST NOT write to `rollout-config.yml` before step 7's explicit
  confirmation.
- MUST NOT fabricate any project ID, environment key, or server-type value
  when the developer has not supplied or confirmed one.

## Output shape (`rollout-config.yml`, after step 7)

See [data-model.md](../data-model.md)'s Provider Config Block for the exact
field list. Example shape for a single configured provider:

```yaml
provider: launchdarkly

launchdarkly:
  project_key: my-project
  environments: [production]
  server_type: hosted
```

A second, sibling provider block (future feature) would add a new top-level
key alongside `launchdarkly:`, never modifying it.
