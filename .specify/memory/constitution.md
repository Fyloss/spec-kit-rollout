<!--
Sync Impact Report — Amendment
Version change: 1.0.0 → 1.1.0
Rationale: MINOR bump — materially expands guidance on Principle III by
  adding an explicit carve-out distinguishing gate-state marker back-fill
  from content derivation; no principle removed or redefined, so not MAJOR;
  the added sentence changes what is permitted (not just wording), so not a
  PATCH-level non-semantic fix.
Modified principles:
  - III. Strict Content Lineage — added a clarifying carve-out: writing the
    `## Delivery Considerations` *marker* into `spec.md` at plan time (state
    back-fill for late-introduced rollout intent, per vision.md §5.2 and
    Feature 006's `/plan`-arguments sniff) is gate-state bookkeeping, not the
    "content" whose one-direction flow this principle governs, and is
    therefore not an instance of the forbidden "spec content from plan"
    pattern — provided the back-filled marker verbatim-matches the Feature
    003 contract and no other spec.md content is authored from plan-phase
    input.
Added sections: none
Removed sections: none
Templates requiring updates:
  - .specify/templates/plan-template.md — ✅ no change needed (Constitution
    Check gate is generic, self-populates from this file at plan time)
  - .specify/templates/spec-template.md — ✅ no change needed
  - .specify/templates/tasks-template.md — ✅ no change needed
  - .specify/templates/checklist-template.md — ✅ no change needed
  - specs/006-rollout-plan-doctrine/plan.md — ⚠ follow-up: Constitution
    Check section must be re-run against this ratified constitution (was
    written against the unratified template and is stale)
Follow-up TODOs: none
-->
# Rollout Extension Constitution

## Core Principles

### I. Additive-Only Extension
The `rollout` extension MUST NEVER edit or fork a Spec Kit core template. All
doctrine MUST ship exclusively via `before_*` hooks that invoke this
extension's own `speckit.rollout.brief-*` commands. This is not a style
preference: Spec Kit core templates are replace-not-merge (first-match-wins),
so any attempt to edit them directly would silently break on upgrade or
collide with other extensions. Hooks are therefore the only safe, additive
injection point, and every doctrine change MUST be expressed as a change to a
`brief-*` command file, never as a change to a core template.

### II. Self-Gating, Near-Zero Noise
Every hook MUST gate itself using the rollout-gate script/contract before
emitting any doctrine content. If the current feature's `spec.md` (or, in
`analyze` mode, `plan.md`/`tasks.md`) does not contain the
`## Delivery Considerations` marker, the hook's command MUST emit a single
one-line no-op message and stop. Doctrine content MUST NOT be injected into
the agent's context for features that never signaled rollout intent. This
keeps the extension's cost to adopting teams at effectively zero when rollout
is not in play.

### III. Strict Content Lineage
The marker and heading text used to gate and carry rollout state MUST match
the contract in
[specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md](specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md)
exactly — no paraphrasing, reordering, or casing changes. Rollout content
MUST flow in one direction only: `plan.md`'s `Delivery Strategy` is derived
from `spec.md`'s `Delivery Considerations`; `tasks.md`'s rollout tasks are
derived from `plan.md`'s `Delivery Strategy`; `before_implement` acts on
`tasks.md` + `plan.md`. Content MUST NEVER be regenerated sideways (e.g.,
re-deriving plan content from tasks, or spec content from plan). Any change
to the marker text, heading text, or the `Delivery Strategy`/`Delivery
Considerations` label conventions MUST update
`contracts/rollout-gate-cli.md` and both `scripts/bash/rollout-gate.sh` and
`scripts/powershell/rollout-gate.ps1` in the same change — a marker or
heading contract can never drift between the two script implementations or
between the contract doc and the doctrine that reads/writes it.

### IV. Provider-Neutral Doctrine, Official MCP Only
Doctrine MUST describe provider intents generically (discover environments,
discover segments/audiences, create flag, set targeting rules, set rollout
percentage, read flag status, archive flag) and MUST bind those intents to
real tools only via MCP introspection (`tools/list`, `resources/list`,
`prompts/list`) at runtime. The extension MUST NOT build a per-provider API
wrapper or maintain a bespoke capability contract per provider. Only the
pinned, official provider MCP server referenced in config MAY be used;
doctrine MUST NOT instruct the agent to search for, substitute, or fall back
to an alternative, forked, or unofficial MCP server under any circumstance.

**Marker back-fill is state, not content**: Writing the `## Delivery
Considerations` marker into `spec.md` at a later phase (e.g., a `/plan`-time
back-fill when rollout intent is introduced late, per vision.md §5.2's
"late-introduced intent" and "content lineage — spec.md is consulted only
for flag/no-flag state" rules) is gate-state bookkeeping, not the authored
"content" this principle's one-direction flow governs, and is therefore not
an instance of the forbidden "spec content from plan" pattern — provided
(a) the back-filled marker verbatim-matches the heading and label convention
in `contracts/rollout-gate-cli.md`, and (b) no other `spec.md` content
(requirements, user stories, success criteria) is authored or rewritten from
plan-phase (or later-phase) input.

### V. Credential Security Is Non-Negotiable
Provider tokens MUST NEVER be committed to the repository, echoed in any
command output, or placed into the model's context window. Tokens are
consumed exclusively by the MCP server process via an environment variable
inherited at process launch. Committed and generated config (including
`rollout-config.yml` and any extension defaults) MUST hold only non-secret
pointers — provider id, project key, environment names, and the expected
env-var *name* — never a secret value. Any doctrine, command, or script that
would read, log, or forward a token value is a constitution violation and
MUST be rejected in review.

### VI. Guardrailed Provider Execution (NON-NEGOTIABLE)
`before_implement` actions MUST NEVER auto-advance production exposure —
increasing rollout percentage, ramping to 100%, or archiving a flag — without
an explicit, current instruction from the user in that session. Prior plan or
task content proposing such a change is not sufficient authorization on its
own at execution time. When no provider MCP is reachable, the extension MUST
degrade gracefully to plan-only mode: it documents the `Delivery Strategy`
and emits a task to configure/run setup, and MUST NOT hard-fail the
workflow.

## Scope Constraints

- Adding a new feature-flag provider MUST preserve Principle IV in full: the
  doctrine stays provider-neutral and MUST NOT special-case a provider's
  wording, flow, or terminology into the shared briefing commands. At most, an
  optional, clearly-labeled per-provider advisory note MAY be added.
- `speckit.rollout.connect` MUST remain idempotent (safe to re-run with no
  duplicate or conflicting state) and MUST NEVER write a secret value to any
  file it generates or updates.

## Development Workflow

- Any doctrine change that touches the `Delivery Considerations` /
  `Delivery Strategy` marker or heading contract MUST cross-check both
  `scripts/bash/rollout-gate.sh` and `scripts/powershell/rollout-gate.ps1` in
  the same change, and MUST verify both against
  `specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` before
  merging. A change that updates one script, or the contract doc, without the
  other is incomplete and MUST NOT be merged.

## Governance

This constitution supersedes any conflicting guidance in individual feature
specs, plans, or command doctrine. Where this document is silent on how to
interpret a principle, `docs/foundation/vision.md` is the authoritative
reference.

Amendments require: (1) a documented rationale for the change, (2) a semver
version bump — MAJOR for backward-incompatible principle removals or
redefinitions, MINOR for adding a new principle or materially expanding
guidance, PATCH for clarifications and non-semantic wording fixes — and (3) a
Sync Impact Report prepended to this file recording the version change,
affected principles/sections, and any templates or docs flagged for
follow-up. All feature plans MUST pass the Constitution Check gate before
Phase 0 research and MUST re-verify it after Phase 1 design; any unresolved
violation must be justified in the plan's Complexity Tracking section or the
plan MUST be revised to comply.

**Version**: 1.1.0 | **Ratified**: 2026-07-08 | **Last Amended**: 2026-07-08
