# Data Model: Rollout Config Wizard

This feature has no runtime database or in-memory domain objects. The
"entities" are the structural elements of the wizard's run-time behavior and
the config schema it writes, as declared in spec.md's Key Entities section
and elaborated here with concrete field/type detail for `/speckit.tasks` and
`/speckit.implement` to consume.

## Rollout Config Wizard Run

The single execution of `speckit.rollout.config`, from invocation to final
report. Always exactly the seven steps spec.md's Assumptions section
enumerates (provider → MCP detection/selection → automatic server-type
detection → project → environment(s) → read verification → final
confirmation), though steps 4/5/6 branch into hosted (a) vs. local (b)
sub-cases per step 3's outcome. Writing the config block and reporting the
outcome are the actions that complete step 7, not separate numbered steps.

| Step | Name | Notes |
|---|---|---|
| 1 | Provider selection | "LaunchDarkly" selectable; any other listed provider name shown disabled with a "coming soon" label (FR-003) |
| 2 | MCP server discovery & candidate resolution | Introspect the developer's already-configured MCP servers; never launches or registers one itself. Zero candidates → stop with guidance, no further action. One → proceed. Many → ask developer to disambiguate (FR-004\u2013FR-007) |
| 3 | Server type determination | Live, behavioral, never-cached probe (see MCP Server Type Determination below) |
| 4a / 4b | Project selection (hosted / local) | 4a: present real projects from the confirmed capability. 4b: manual project ID entry, or explicit opt-out (see Local Branch Manual Entry / Opt-Out below) |
| 5a / 5b | Environment selection (hosted / local) | 5a: present real environments for the selected project. 5b: manual environment key entry (opt-out skips this too) |
| 6 | Read verification | Read-only flag-listing check against the resolved project/environments; skipped only in the local opt-out sub-case (FR-012) |
| 7 | Final confirmation | Show a complete summary; require explicit confirmation before any write (FR-013/FR-015); once confirmed, write exactly one modular provider config block (see Provider Config Block below) and report the outcome |

**Invariant**: steps 4a/5a and 4b/5b are mutually exclusive per run; which
pair executes is entirely determined by step 3's outcome, never a developer
choice at step 2.

## MCP Server Selection

The outcome of steps 1-2: which of the developer's own registered MCP
servers (if any) the rest of the run operates against.

| Field | Notes |
|---|---|
| Candidate count | 0, 1, or many — drives step 2's branch |
| Selected server identifier | Client-native name/label of the chosen MCP server entry (never a value this feature invents or writes) |

## MCP Server Type Determination

The step-3 outcome: whether the selected server is **hosted** or **local**,
re-derived fresh on every run (research.md Findings 1-2, 5).

| Field | Type | Notes |
|---|---|---|
| Probe action | behavioral | Attempt a live call to whichever introspected tool lists the developer's LaunchDarkly projects (research.md Finding 3: the hosted server's own `list-projects`-shaped tool; the local server's documented operation catalogue has no equivalent) |
| Outcome: success with results | → hosted | Drives step 4a |
| Outcome: clean "capability not found" | → local | Drives step 4b |
| Outcome: ambiguous / timeout / transport error | → local (never blocks) | research.md Finding 4 — the wizard must never stall on transport noise |
| Cache policy | none — re-verified every run | Never persisted between runs, never trusted from a prior run's result |

## LaunchDarkly Project/Environment Selection (Hosted Branch)

| Field | Type | Notes |
|---|---|---|
| Project key | string | Selected from the live, confirmed project-listing capability's results |
| Environment key | string | Selected from that project's environments, same capability family |
| Read Verification Result | see below | Performed after selection, before final confirmation |

## Local Branch Manual Entry / Opt-Out

| Field | Type | Notes |
|---|---|---|
| Entry mode | `manual` \| `opt-out` | Developer's explicit choice — never inferred |
| Project ID (manual mode) | string | Typed by the developer; MUST NOT be fabricated or defaulted |
| Environment key (manual mode) | string | Typed by the developer; MUST NOT be fabricated or defaulted |
| Read verification (manual mode) | performed | Same as hosted branch, using the manually entered values |
| Read verification (opt-out mode) | explicitly skipped | A clear note recording the skip is written to the run's outcome (FR-012), not silently omitted |

## Read Verification Result

A read-only check confirming the selected/entered project + environment
values resolve to something real, performed before the final
confirmation gate (steps 4a/4b, before step 5).

| Field | Type | Notes |
|---|---|---|
| Outcome | `pass` \| `fail` \| `skipped (opt-out)` | `skipped` only reachable via the local branch's explicit opt-out |
| On `fail` | developer choice | Cancel the run, or continue anyway with an explicit acknowledgement — never silently continued |

## Provider Config Block

The modular, per-provider unit written into `rollout-config.yml` at step 6
(FR-026), replacing Feature 002's flat, single-provider schema.

| Field | Type | Notes |
|---|---|---|
| `provider` | string | The *active* provider selector — unchanged in type/role from Feature 002, still exactly one value at a time |
| `<provider_name>:` | object | One sibling block per configured provider (e.g. `launchdarkly:`) — adding a second provider adds a second sibling block, never touches the first (Extension point, mirrors Feature 002's data-model.md "Provider Descriptor" note) |
| `launchdarkly.project_key` | string | Non-secret identifier; from hosted selection, local manual entry, or absent if opted out |
| `launchdarkly.environments` | array of string | Non-secret identifiers, one or more; same sourcing as `project_key` |
| `launchdarkly.server_type` | `hosted` \| `local` \| unset | Recorded for reporting/traceability only — re-verified fresh next run regardless of this stored value (never trusted as cache) |

**Removed fields (superseding Feature 002/011)**: `mcp.command`, `mcp.args`,
`mcp.version`, `mcp.repository`, `mcp.token_env_var` no longer exist
anywhere in this schema — that information now lives entirely in the
developer's own MCP client configuration, outside this project's reach
(FR-017).

## Provider Switch (`speckit.rollout.provider <provider_name>` Run)

| Field | Type | Notes |
|---|---|---|
| Target provider name | string | The provider to switch to/preset |
| Existing block found? | boolean | If true: reuse it, update only `provider:` to point at it, no re-prompting |
| Existing block absent | — | Run that provider's own preset (LaunchDarkly is the only real preset in V1); a future provider adds a sibling preset, no core command control-flow change (FR-025) |
