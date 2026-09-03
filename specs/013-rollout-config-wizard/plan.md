# Implementation Plan: Rollout Config Wizard

**Branch**: `013-rollout-config-wizard` | **Date**: 2026-08-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-rollout-config-wizard/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Replace `commands/connect.md` (Feature 011's pinned-MCP, client-adapter-write
command) with a new, re-runnable, user-invoked `speckit.rollout.config`
wizard, plus a new `speckit.rollout.provider` command for switching/adding a
provider without re-running the whole wizard. The wizard's seven steps: (1)
introspect the developer's already-configured MCP servers (never launches or
registers one itself — that remains the developer's own client-native setup,
consistent with 011's non-goal); (2) if zero LaunchDarkly-capable candidates
are found, stop with guidance and take no further action; if multiple exist,
ask the developer to disambiguate; (3) for the selected server, perform a
read-only, never-cached, every-run **hosted-vs-local type determination** by
attempting a live call to whichever introspected tool lists the developer's
LaunchDarkly projects — success (with results) means hosted, a clean
"capability not found" means local, and any ambiguous/timeout outcome is
also treated as local so the wizard never stalls (research.md Findings
3-5); (4a) **hosted branch**: use the confirmed project-listing capability to
present real projects/environments for selection, then read-verify the
selection; (4b) **local branch**: prompt for manual project ID and
environment key entry (no fabricated placeholders), or an explicit opt-out
that skips read-verification with a clear recorded note; (5) show a final
summary and require explicit confirmation before writing anything; (6) write
exactly one **modular provider config block** (`provider: launchdarkly` +
a `launchdarkly:` block) into `rollout-config.yml`, replacing the old flat
pinned `mcp.*` shape entirely — no MCP command/args/version/repository is
ever written into config again, since the developer's own client already
owns that registration; (7) report the outcome. The sibling
`speckit.rollout.provider <provider_name>` command lets a developer switch
the active `provider:` value and, for a provider with no existing config
block yet, run that provider's own preset (LaunchDarkly is the only real
preset in V1) — reusing an existing block for a previously-configured
provider without re-prompting. This is the first feature in this repository
whose config schema is genuinely modular (a new provider adds a sibling
block, never touches `provider`'s type or another provider's block) and the
first to introduce live, behavioral MCP capability detection as opposed to
static, pinned configuration.

## Technical Context

**Language/Version**: N/A (no code) — the deliverable is agent-facing
Markdown prompt content in two command files (`commands/config.md` — new,
replacing `commands/connect.md`; `commands/provider.md` — new), an edited
section of `commands/brief-implement.md`, and updated YAML schema/config
files, following the same YAML-frontmatter + Markdown-body command format
used throughout this repository.

**Primary Dependencies**: Consumes and rewrites the `mcp.*` / `launchdarkly.*`
field shape in `rollout-config.template.yml` (Feature 002's schema,
superseding it with the modular per-provider block from spec.md FR-026);
consumes the standard MCP discovery/introspection operations (`tools/list`,
and a live tool call) as a standard MCP client capability, per
research.md's concrete grounding (the hosted server's own published
`list-projects` tool; the local server's documented operation catalogue,
which has no project-listing operation); references (but does not rewrite
control-flow for) `commands/brief-implement.md`'s existing MCP-resolution
step (Feature 010), which this feature updates to resolve the MCP server
from the developer's own registered server instead of a pinned config
reference; and `extension.yml`'s `provides.commands` registration list,
which gains `config` and `provider` and loses `connect`.

**Storage**: N/A — no data is persisted by this feature's own artifacts. The
downstream effect (a `rollout-config.yml` provider block being written) only
happens when the *executing* agent follows this doctrine in an adopting
project, not as part of this feature's own deliverables.

**Testing**: Manual/scripted verification per quickstart.md: walk through
each user story and edge case (zero/one/many candidate servers; hosted vs.
local branching including ambiguous/timeout-as-local; read-verification
failure with cancel-or-continue; final-confirmation gate; re-run changing an
earlier selection; provider switch reusing an existing block; provider
switch triggering a new preset; local-branch manual entry; local-branch
explicit opt-out with no fabricated placeholders) using the doctrine text as
the acting agent's instructions and scratch fixture directories/files (not
committed) — never a real MCP server connection or a real LaunchDarkly
token (Constitution Principle V), consistent with Features 004-012's
verification approach. This project's own `.vscode/mcp.json` (a real,
already-configured hosted LaunchDarkly MCP server) is noted in
quickstart.md as an optional, additional live-behavior reference a verifier
MAY consult read-only (e.g., to see what a real `list-projects`-style result
looks like) but is never required, and no real token is read, stored, or
written during verification either way.

**Target Platform**: N/A — the doctrine is consumed by whatever AI coding
agent runs `/speckit.rollout.config` or `/speckit.rollout.provider` inside a
project already using this extension, and by that agent's MCP client; no
platform-specific behavior is introduced.

**Project Type**: Single project — content-only change to the existing
`rollout` extension package (repository root). No new source tree.

**Performance Goals**: N/A — a user-invoked, occasional setup/switch command,
not performance-sensitive; the one live MCP probe per run (step 3) is a
single call, not a polling loop.

**Constraints**: MUST perform hosted-vs-local determination as a live,
behavioral probe every run — never cached, never inferred from the saved
config entry's transport shape (FR-008; research.md Findings 3 and 5 show
tool-name and transport-shape heuristics are both unreliable signals on
their own). MUST NOT launch, install, or write a client's native MCP server
registration — that remains the developer's own responsibility, unchanged
from Feature 011's non-goal. MUST NOT write `mcp.command`/`mcp.args`/
`mcp.version`/`mcp.repository` into config anywhere, ever (FR-017,
superseding Feature 002/011's pinned-reference schema). MUST require an
explicit final confirmation before any file write (FR-013/FR-015). MUST
NEVER fabricate a project ID or environment key on the local branch — manual
entry or explicit, clearly-noted opt-out only (FR-011/FR-012, spec.md User
Story 7). MUST be safely re-runnable, changing only the fields the
developer chooses to change (FR-016). MUST keep `speckit.rollout.provider`
generic — switching to or presetting a second provider MUST NOT require
touching the wizard's control-flow, only adding a sibling preset (FR-025/
FR-026). MUST NEVER request, read, or store a credential/token value at any
step (FR-023). MUST update `commands/brief-implement.md`'s existing
MCP-server-resolution step (Feature 010) to resolve from the developer's
own registered server rather than a pinned config reference, including a
local-branch/no-config degrade-to-plan-only path (FR-020). MUST propagate
the new modular shape, the `provider` command, and the hosted/local
branching into `docs/foundation/vision.md`, `docs/providers.md`,
`docs/usage.md`, and `README.md` (FR-021).

**Scale/Scope**: This is the largest feature in this repository's history:
new `commands/config.md` (replacing `commands/connect.md`, which is
removed); new `commands/provider.md`; an edited section of
`commands/brief-implement.md` (MCP-resolution step only, per FR-020);
rewritten `rollout-config.template.yml` (modular per-provider shape,
FR-026); updated `extension.yml` (`provides.commands` gains `config`/
`provider`, loses `connect`; `config_schema` reflects the modular shape);
updated `specs/002-config-system/contracts/rollout-config-schema.md`
(superseded schema, per FR-017/FR-026); superseded-acceptance-criteria
annotations added to `specs/002-config-system/spec.md`,
`specs/010-rollout-implement-doctrine/spec.md`, and
`specs/011-rollout-connect-setup/spec.md` (each of which documented the now
-superseded pinned/connect behavior as passing acceptance criteria); updated
`docs/foundation/vision.md`, `docs/providers.md`, `docs/usage.md`,
`README.md`; and this feature's own new `contracts/` directory (two new
contracts: the wizard's step contract, and the `provider` command's
switch/preset contract).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` v2.0.0 is ratified (2026-07-08, last
amended 2026-08-12) with six Core Principles plus Scope Constraints. The
v2.0.0 amendment was made specifically to resolve this feature's Principle
IV conflict, identified during this plan's first pass (see history below);
this plan is checked against the current, amended text:

- **I. Additive-Only Extension**: PASS — this feature only rewrites/adds
  files already within this extension's own package (`commands/*.md`,
  `extension.yml`, `rollout-config.template.yml`, `docs/*`, `README.md`);
  it touches no Spec Kit core template. Removing `commands/connect.md` and
  its `extension.yml` registration is an intra-extension change, not an
  edit to Spec Kit core.
- **II. Self-Gating, Near-Zero Noise**: N/A for the two new commands (both
  are user-invoked, one-time-or-occasional setup/switch commands, not
  `before_*` hook briefings — the same status Feature 011's `connect`
  held, per the Scope Constraints section's explicit distinction). The
  `commands/brief-implement.md` section this feature edits keeps its
  existing self-gating behavior (Feature 010's two-stage gate-script +
  tasks.md check) completely unchanged — only the MCP-server-resolution
  *source* changes, not the gating logic. PASS for the edited portion.
- **III. Strict Content Lineage**: PASS/N/A — this feature does not read or
  derive content from the spec→plan→tasks lineage; its only inputs are the
  developer's live MCP context (step 1-4) and their own interactive
  choices (steps 4-6). No marker or heading text is produced or altered.
- **IV. Provider-Neutral Doctrine, Official MCP Only**: PASS — **resolved**.
  An earlier pass of this Constitution Check flagged a direct conflict
  between this feature's live-discovery mechanism and the then-ratified
  v1.1.0 wording ("only the pinned, official provider MCP server referenced
  in config," never "search for" an alternative). That conflict was
  resolved by a `/speckit.constitution` amendment (v1.1.0 → v2.0.0, 2026-08
  -12) that redefined Principle IV to permit binding to an official
  provider MCP server either via a single pinned config reference **or** via
  live introspection of the developer's own already-registered official
  server instances, with any such discovery re-verified fresh on every
  invocation (never cached) — exactly this feature's step-3 behavior
  (research.md Findings 3-5). Substituting, forking, or falling back to an
  unofficial/unauthorized implementation remains forbidden in both
  resolution modes, so the pin's original supply-chain-safety intent is
  fully preserved.
- **V. Credential Security Is Non-Negotiable**: PASS — FR-023 requires the
  wizard never request, read, or store a credential/token value at any
  step; the modular config schema (FR-026) carries no MCP command/args/
  token-env-var field at all anymore (that information now lives entirely
  in the developer's own client-native MCP config, outside this project's
  reach) — if anything, this feature *reduces* this project's credential
  surface area versus Features 002/011's pinned `mcp.token_env_var` field.
- **VI. Guardrailed Provider Execution (NON-NEGOTIABLE)**: N/A — this
  feature performs no provider execution itself (no flag/targeting/rollout
  action); it only affects where `commands/brief-implement.md` resolves its
  MCP server *from* (FR-020), not the guardrails governing what it does
  with that server, which are Feature 010's unchanged FR-009 logic.
- **Scope Constraints**: PASS — **resolved**. The v2.0.0 amendment also
  updated the bullet formerly naming `speckit.rollout.connect` (a command
  this feature removes) to instead name `speckit.rollout.config` and
  `speckit.rollout.provider` directly, and elevated the no-fabrication
  guarantee (FR-011/FR-012) from a spec-level detail to a durable
  governance constraint. FR-016 (re-runnability), FR-023 (never touching a
  credential value), and FR-011/FR-012 (no fabricated project ID/
  environment key) all satisfy the now-current bullet text directly.

No violation remains. The Principle IV conflict and the Scope Constraints
staleness identified during this plan's first pass were both resolved by
running `/speckit.constitution` (v1.1.0 → v2.0.0, 2026-08-12) before
completing this plan, rather than being carried forward as unresolved items
in Complexity Tracking. Complexity Tracking below is retained only as a
historical record of the now-resolved conflict.

**Post-Phase 1 re-check**: data-model.md, contracts/, and quickstart.md
introduce no entity, interface, or verification approach beyond what this
Constitution Check already evaluated — no new violations, and the
previously-flagged items remain resolved.

## Project Structure

### Documentation (this feature)

```text
specs/013-rollout-config-wizard/
├── plan.md                          # This file (/speckit.plan command output)
├── research.md                      # Phase 0 output (created in specify-phase grounding, extended here)
├── data-model.md                    # Phase 1 output (/speckit.plan command)
├── quickstart.md                    # Phase 1 output (/speckit.plan command)
├── contracts/
│   ├── rollout-config-wizard.md     # Phase 1 output — new: the wizard's 7-step external contract
│   └── rollout-provider-command.md  # Phase 1 output — new: the provider-switch command's contract
├── checklists/
│   └── requirements.md              # Already produced by /speckit.specify
└── tasks.md                         # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

This feature adds a `contracts/` directory (like Feature 011, unlike
Features 004-010/012) because it introduces two genuinely new external
interfaces: the wizard's own step/branching contract, and the provider
command's switch/preset contract. It does **not** duplicate Feature 002's
`rollout-config-schema.md` contract — that file is updated in place (per
FR-017/FR-026, listed in Scale/Scope) rather than superseded by a new,
competing schema doc in this feature's own directory, keeping exactly one
canonical schema contract in the repository.

### Source Code (repository root)

No new source tree. This feature's deliverables are content changes to
existing extension files, plus two new command files:

```text
commands/
├── config.md            # New — replaces connect.md (rewritten wizard doctrine)
├── provider.md           # New — speckit.rollout.provider doctrine
└── brief-implement.md    # Edited — MCP-resolution step only (FR-020)

rollout-config.template.yml   # Rewritten — modular per-provider shape (FR-026)
extension.yml                 # Edited — commands + config_schema updated

docs/
├── foundation/vision.md  # Edited — propagate modular shape/provider command/hosted-local branching
├── providers.md          # Edited
└── usage.md              # Edited

README.md                 # Edited
```

`commands/connect.md` is removed (superseded by `commands/config.md`).

**Structure Decision**: Single project, content-only. Matches the
established pattern (each rollout feature rewrites/adds `commands/*.md`
files and, where an external interface is genuinely new, a `contracts/`
directory), scaled up because this feature spans more files than any prior
feature — justified by Scale/Scope above, not by any new source-tree
concept.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No current violations — table intentionally omitted. **Resolved history**:
an earlier pass of this plan identified two conflicts between this
feature's design and the then-ratified constitution v1.1.0 — (1) Principle
IV's literal "only the pinned config reference, never search for a
server" wording versus this feature's live-discovery-of-developer-
registered-server model, and (2) the Scope Constraints bullet naming
`speckit.rollout.connect`, a command this feature removes. Both were
resolved by running `/speckit.constitution`, which amended the constitution
to v2.0.0 (2026-08-12): Principle IV now explicitly permits live
introspection-based discovery of an official, developer-registered MCP
server (re-verified fresh every run) as an alternative to a single pinned
config reference, and the Scope Constraints bullet now names
`speckit.rollout.config`/`speckit.rollout.provider` directly. See the
Constitution Check section above for the current, passing evaluation.

