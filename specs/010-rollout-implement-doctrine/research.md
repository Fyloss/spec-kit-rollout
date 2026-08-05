# Phase 0 Research: Rollout Implement Doctrine

No `[NEEDS CLARIFICATION]` markers exist in spec.md — the quality checklist
passed on first draft (consistent with Features 004-009). This document
records the design decisions made while translating the spec's functional
requirements into concrete doctrine content for `commands/brief-implement.md`.

## Decision: Reuse existing gate/lineage contracts; author no new contract file

**Decision**: This feature does not add a `contracts/` directory. It reuses:
`specs/003-rollout-gate-mechanism/contracts/rollout-gate-cli.md` for the gate
script's stdout shape, the `## Delivery Strategy` heading convention from
Feature 006 (`commands/brief-plan.md`), and the six rollout-task categories
from Feature 007 (`commands/brief-tasks.md`).

**Rationale**: Same rationale as Features 004-009 — this feature authors
prompt content (a `brief-*.md` command body), not a new machine-readable
interface. Introducing a parallel contract for the marker/heading/task shapes
would create a second source of truth that could drift from the existing
ones, which Constitution Principle III explicitly warns against ("a marker or
heading contract can never drift between the two script implementations or
between the contract doc and the doctrine that reads/writes it").

**Alternatives considered**: A dedicated
`contracts/mcp-intent-binding.md` documenting the seven provider-neutral
intents as a formal contract was considered, since this is the first feature
to define an MCP-facing vocabulary. Rejected because the intent vocabulary is
inherently doctrine (natural-language instruction to the agent), not a
machine-checkable interface like the gate script's stdout — there is no
second implementation of this vocabulary to keep in sync with, unlike the
bash/PowerShell gate script pair. The seven intents are instead documented as
entities in data-model.md, consistent with how Feature 008 documented its new
"rollout-chain finding" entities without a contracts file.

## Decision: Two-stage gate mirrors Features 007/008, not the simpler 004-006 pattern

**Decision**: `commands/brief-implement.md` performs (1) the shared gate
script check against `spec.md`, then (2) an independent scan of `tasks.md` for
rollout-task presence, before any MCP introspection or provider action.

**Rationale**: Constitution Principle III requires provider actions to be
"derived from tasks + plan," never fabricated from the spec marker alone.
Since the gate script only reports marker presence in `spec.md` (default
mode), a second, feature-specific check of `tasks.md` is required to confirm
there is actually something to execute — identical reasoning to why Feature
007 added a second gate for `plan.md`'s Delivery Strategy before generating
tasks, and Feature 008 added the same two checks (Delivery Strategy +
rollout tasks) before treating the chain as consistent.

**Alternatives considered**: Skipping the second gate and instead having the
doctrine "try" MCP introspection whenever the marker is present, falling back
silently if `tasks.md` had nothing rollout-related. Rejected: this would risk
inventing execution parameters from the plan's Delivery Strategy directly
(skipping the tasks link in the lineage chain), violating Principle III's
one-direction flow (`plan -> tasks -> implement`), and would blur the
distinct "not ready yet" status message required by FR-004.

## Decision: MCP introspection instructed generically, no assumed tool names

**Decision**: The doctrine instructs invoking the three standard MCP
discovery operations (`tools/list`, `resources/list`, `prompts/list`) at
runtime and binding the seven provider-neutral intents to whatever is
actually advertised, rather than hardcoding expected LaunchDarkly MCP tool
names anywhere in the doctrine text.

**Rationale**: Direct implementation of Constitution Principle IV and
vision.md §6.1 — MCP's `tools/list` is a standard, self-describing,
always-fresh source of truth; a maintained capability contract mapping
intents to specific tool names would go stale as the official LaunchDarkly
MCP server's tool catalogue evolves, and would violate the "no per-provider
API wrapper" constraint.

**Alternatives considered**: Documenting a best-guess table of expected tool
names (e.g., "createFeatureFlag", "listEnvironments") as a starting point for
the agent. Rejected: even framed as a "starting point," a named table risks
being treated as authoritative by a future agent run, functionally
recreating the forbidden capability contract; the doctrine instead describes
only the *intent* in natural language and requires runtime binding every
time.

## Decision: Guardrail wording ties directly to Constitution Principle VI text

**Decision**: The production-exposure guardrail instruction in the doctrine
uses language closely mirroring the constitution's Principle VI wording
("MUST NEVER auto-advance production exposure... without an explicit,
current instruction from the user in that session. Prior plan or task
content proposing such a change is not sufficient authorization on its own
at execution time.").

**Rationale**: This is a NON-NEGOTIABLE principle (spec.md User Story 2, P1;
constitution Principle VI). Restating it verbatim-adjacent in the doctrine
minimizes the chance that a paraphrase drifts from the constitution's actual
guarantee, and gives any future constitution amendment a clear, greppable
text anchor to update in this doctrine file too.

**Alternatives considered**: A looser paraphrase ("be careful about
production changes"). Rejected as insufficiently unambiguous for a
NON-NEGOTIABLE guardrail — spec.md FR-009 and Acceptance Scenario wording
are precise about "beyond what the current task or plan explicitly
specifies," which the doctrine must preserve exactly.

## Decision: Token-handling guardrail is a standalone instruction, not folded into guardrail wording for production exposure

**Decision**: The "never read/echo/log/inline the token" instruction (FR-010)
is written as its own clearly separated doctrine paragraph, distinct from the
production-exposure guardrail paragraph (FR-009), even though both are
guardrails under the same User Story 2.

**Rationale**: Spec.md itself separates these into two independent
Acceptance Scenarios with independently testable conditions (production
exposure vs. token leakage) — collapsing them into one instruction risks an
agent treating them as a single fuzzy "be safe" reminder rather than two
distinct, independently-checkable rules. This also matches vision.md's
treatment of §6 (guardrails) and §8 (credential security) as separate
sections.

**Alternatives considered**: One combined "Guardrails" section covering both
concerns in adjacent bullet points. Considered acceptable but the standalone-
paragraph approach was chosen for maximum instruction clarity given these are
both constitution NON-NEGOTIABLE-tier concerns.

## Decision: Graceful degradation records exactly one task, referencing the existing placeholder command name

**Decision**: The plan-only-mode branch instructs recording exactly one task
that names `speckit.rollout.connect` as the remediation step, without
describing *how* to configure the MCP connection (that doctrine is Feature
011's responsibility, currently a placeholder body).

**Rationale**: FR-012 explicitly scopes this feature away from MCP
registration/setup content. `speckit.rollout.connect` is already a validly
registered command name (per `commands/connect.md`'s placeholder, which
states it's registered "so the extension installs and validates cleanly with
all 8 declared commands present") — referencing it by name is forward-
compatible and doesn't require Feature 011 to be implemented first.

**Alternatives considered**: Describing generic manual MCP setup steps
inline (e.g., "add an mcp.json entry") as a stopgap until Feature 011 exists.
Rejected: this would duplicate/anticipate Feature 011's doctrine content and
risk drifting from whatever client-adapter approach that feature ultimately
implements (vision.md §7).

## Verification approach

Consistent with Features 004-009: no live LaunchDarkly MCP server or real
token is used. Verification is a doctrine-text read-through plus targeted
`grep` checks (no token value ever appears in the file; both guardrail
paragraphs present; all seven intents named; two-stage gate present; exactly
one plan-only-mode task instruction) confirming the file satisfies FR-001
through FR-014, and a fixture-directory pass with
`scripts/bash/rollout-gate.sh` (via `SPECIFY_FEATURE_DIRECTORY`, the pattern
established in Feature 005's implementation notes) confirming
`hasFlags`/`flags` parity is unaffected by this feature's changes.
