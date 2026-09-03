# Feature Specification: Rollout Connect Setup Command

**Feature Branch**: `[011-rollout-connect-setup]`

**Created**: 2026-07-08

**Status**: Draft

> **Fully superseded/removed by Feature 013** (`013-rollout-config-wizard`):
> the `speckit.rollout.connect` command specified by this entire feature —
> including `commands/connect.md`, its client-MCP-configuration-file-write
> behavior, and every acceptance scenario and functional requirement below
> that relies on writing a pinned LaunchDarkly MCP server spec into a
> client's own MCP configuration file — was permanently removed, not
> deprecated-alongside (FR-001, FR-002 of Feature 013). It is replaced by
> `speckit.rollout.config`/`speckit.rollout.provider`, which never write to
> any client's MCP configuration file at all; the developer registers their
> own MCP server themselves. User Stories 1-3 below (all reliant on the
> removed write/fallback/idempotent-update behavior) and every FR/SC that
> assumed it are superseded in full. Historical text is left unchanged as a
> record of what this feature originally delivered.

**Input**: User description: "Read docs/foundation/vision.md first (sections 6.2, 7, 8). Specify commands/connect.md — the one-time setup command speckit.rollout.connect (user-invoked, not a day-2 operational command). Requirements: Read the active Spec Kit integration; derive the target client from Spec Kit's own integration catalog so coverage tracks all supported clients (Copilot, Claude Code, Cline, Cursor, Windsurf, Gemini CLI, Codex, etc.). Write the correct MCP server registration for that client from the canonical pinned server spec in config (Feature 2), referencing the token via its env-var NAME only. For clients without a known MCP config location, or that lack project-scoped MCP config, print a ready-to-paste snippet plus an env-var reminder. Idempotent; never writes the token value; never overwrites unrelated MCP entries. Maintain a per-integration adapter mapping (config file path + format) that is easy to extend for new clients. Acceptance criteria: Running connect on a supported client writes/updates that client's MCP config with the pinned LaunchDarkly MCP server. Running connect on an unmapped client prints a correct copy-paste snippet. Re-running connect is idempotent and preserves other MCP servers. No token value is ever written. Out of scope: launching the MCP or storing credentials."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-time MCP setup for a supported client (Priority: P1)

> **Superseded/removed by Feature 013** — see notice at top of file.

A developer has installed the `rollout` extension into a project that uses a
Spec Kit client integration the extension already knows how to configure
(for example, GitHub Copilot, Claude Code, Cline, Cursor, or Codex). They run
`/speckit.rollout.connect` once, as part of initial setup, and the command
detects which client integration is active for the project, looks up that
client in its adapter mapping, and writes the pinned LaunchDarkly MCP server
registration into that client's MCP configuration file — referencing the
provider token only by its environment-variable name.

**Why this priority**: This is the entire reason the command exists
(vision.md §7): without it, every developer would have to hand-author
client-specific MCP registration JSON/TOML themselves, which is exactly the
per-client friction the extension is meant to remove.

**Independent Test**: In a project using a mapped client integration with no
prior LaunchDarkly MCP entry, run `/speckit.rollout.connect` and confirm the
client's MCP configuration file now contains a LaunchDarkly server entry
matching the canonical pinned server spec (command, args, version,
repository, token env-var name) from the project's resolved rollout
configuration, with no token value present anywhere in the file.

**Acceptance Scenarios**:

1. **Given** a project whose active Spec Kit client integration is in the
   adapter mapping and has no existing MCP configuration file, **When**
   `/speckit.rollout.connect` runs, **Then** the client's MCP configuration
   file is created containing the pinned LaunchDarkly MCP server entry.
2. **Given** the same project already has an MCP configuration file with one
   or more unrelated server entries, **When** `/speckit.rollout.connect`
   runs, **Then** the pinned LaunchDarkly entry is added alongside the
   existing entries, none of which are removed or altered.
3. **Given** a completed run, **When** the resulting configuration file is
   inspected, **Then** the LaunchDarkly entry references the token exclusively
   by its environment-variable name and contains no credential value.

---

### User Story 2 - Copy-paste fallback for an unmapped or config-less client (Priority: P2)

> **Superseded/removed by Feature 013** — see notice at top of file.

A developer's project uses a Spec Kit client integration that the `rollout`
extension's adapter mapping does not yet cover, or whose Spec Kit integration
has no project-scoped MCP configuration mechanism at all. They run
`/speckit.rollout.connect` and, instead of guessing at a file to write, the
command prints a ready-to-paste MCP server registration snippet in a generic,
correct format together with a reminder of the exact environment-variable
name the developer must set.

**Why this priority**: Graceful degradation for unmapped clients keeps the
command useful across Spec Kit's full integration surface (vision.md §7)
without the extension needing to hard-code every possible client up front;
it is secondary to the primary write path because it is the exception case,
not the common one.

**Independent Test**: In a project whose active client integration is not in
the adapter mapping (or is mapped as "no project-scoped MCP config"), run
`/speckit.rollout.connect` and confirm no file on disk is created or
modified, and the command's output contains a complete, correctly formatted
MCP server snippet plus the token environment-variable name to set.

**Acceptance Scenarios**:

1. **Given** a client integration absent from the adapter mapping, **When**
   `/speckit.rollout.connect` runs, **Then** it prints a ready-to-paste MCP
   server snippet and an environment-variable reminder instead of writing any
   file.
2. **Given** a client integration present in the adapter mapping but marked
   as lacking project-scoped MCP configuration, **When**
   `/speckit.rollout.connect` runs, **Then** it takes the same print-only
   fallback path rather than attempting a file write.

---

### User Story 3 - Idempotent re-run preserves existing configuration (Priority: P1)

> **Superseded/removed by Feature 013** — see notice at top of file.

A developer who already ran `/speckit.rollout.connect` once (User Story 1)
runs it again later — for example after reinstalling the extension, updating
the pinned server version, or simply out of habit. The command detects the
existing LaunchDarkly MCP entry, updates it in place to match the current
canonical pinned server spec if it has drifted, and leaves every other part
of the client's MCP configuration file untouched. No duplicate LaunchDarkly
entries are created.

**Why this priority**: Idempotency is called out explicitly as a hard
requirement (vision.md §7) because this is a setup command developers may
reasonably run more than once; a non-idempotent implementation would corrupt
developer machines' MCP configuration over repeated use.

**Independent Test**: Run `/speckit.rollout.connect` twice in succession
against the same mapped client and confirm the client's MCP configuration
file contains exactly one LaunchDarkly server entry after both runs, with all
pre-existing unrelated entries and file structure otherwise unchanged.

**Acceptance Scenarios**:

1. **Given** a client's MCP configuration file already contains a correct
   LaunchDarkly entry from a prior run, **When**
   `/speckit.rollout.connect` runs again, **Then** the file is left
   functionally unchanged (no duplicate entry, no unrelated content
   rewritten).
2. **Given** a client's MCP configuration file contains a LaunchDarkly entry
   that no longer matches the current canonical pinned server spec (e.g. a
   stale version or command), **When** `/speckit.rollout.connect` runs,
   **Then** that single entry is updated to match the current spec and no
   second entry is created.

---

### Edge Cases

- What happens when the detected client's existing MCP configuration file
  exists but is malformed or unparseable in its expected format? The command
  must not attempt to blindly overwrite or repair it; it stops, reports the
  problem, and falls back to printing the copy-paste snippet so the developer
  can merge it manually.
- What happens when the project's resolved rollout configuration (Feature 2)
  has an empty or unpopulated pinned MCP server spec (`mcp.command`, etc.)?
  The command reports that the pin is not yet configured rather than writing
  an incomplete or empty server entry.
- How does the command behave when it cannot determine which Spec Kit client
  integration is active at all? It reports that detection failed and falls
  back to the copy-paste snippet path rather than guessing.
- What happens when a project is set up for more than one Spec Kit client
  integration at once? The command acts only on the integration through
  which it was invoked, not on every integration present in the project.

## Requirements *(mandatory)*

> **Superseded/removed by Feature 013**: FR-001 through FR-011 below all
> assumed the now-permanently-removed `speckit.rollout.connect` command and
> its client-MCP-configuration-file-write behavior — see notice at top of
> file.

### Functional Requirements

- **FR-001**: The command MUST detect the Spec Kit client integration active
  for the current project by deriving it from Spec Kit's own integration
  catalog, not from a rollout-specific hardcoded list, so that coverage
  automatically tracks whichever clients Spec Kit itself supports (including,
  at minimum, Copilot, Claude Code, Cline, Cursor, Windsurf, Gemini CLI, and
  Codex).
- **FR-002**: The command MUST maintain a per-integration adapter mapping
  associating each known client integration with its MCP configuration file
  location and configuration format, structured so a new client can be added
  by extending the mapping without changing the command's core logic.
- **FR-003**: For a client present in the adapter mapping with a known,
  project-scoped MCP configuration location, the command MUST write or
  update that client's MCP configuration file with a server entry built from
  the canonical pinned LaunchDarkly MCP server spec resolved from the
  project's rollout configuration (Feature 2): launch command, arguments,
  version constraint, repository reference, and the token environment
  variable's name.
- **FR-004**: The command MUST NOT write a token or credential value into any
  file, under any circumstance — only the environment-variable name that
  holds it.
- **FR-005**: The command MUST be idempotent: repeated runs against the same
  client integration MUST converge to exactly one LaunchDarkly MCP server
  entry that matches the current canonical pinned spec, never accumulating
  duplicates.
- **FR-006**: The command MUST preserve every other MCP server entry already
  present in a client's configuration file; only the entry identified as the
  pinned LaunchDarkly server may be added or updated.
- **FR-007**: For a client integration that is absent from the adapter
  mapping, or present but marked as lacking project-scoped MCP configuration
  support, the command MUST print a ready-to-paste MCP server registration
  snippet in that client's expected format, plus a reminder naming the exact
  environment variable the developer must set, and MUST NOT write or modify
  any file on disk in this path.
- **FR-008**: The command MUST report, after each run, which action it took
  (configuration file written/updated, with its path, or snippet printed)
  and which client integration it detected.
- **FR-009**: The command MUST NOT launch, connect to, or otherwise start the
  MCP server, and MUST NOT prompt for, read, or store a token value at any
  point during its run.
- **FR-010**: If the detected client's existing MCP configuration file cannot
  be parsed in its expected format, the command MUST NOT overwrite or modify
  that file; it MUST stop, report the problem, and fall back to the
  copy-paste snippet path instead.
- **FR-011**: If the project's resolved rollout configuration has no usable
  pinned MCP server spec (e.g. an empty launch command), the command MUST
  report that the pin is not yet configured rather than writing an
  incomplete server entry or fabricating placeholder values.

### Key Entities

- **Client Integration Adapter**: One entry in the per-integration mapping —
  identifies a Spec Kit client integration, its MCP configuration file
  location relative to the project root, its configuration format, and
  whether it supports project-scoped MCP configuration at all.
- **Pinned MCP Server Reference**: The canonical, non-secret description of
  the official LaunchDarkly MCP server (launch command, arguments, version
  constraint, repository URL, token environment-variable name) resolved from
  the project's rollout configuration (Feature 2) and written into, or
  rendered as a snippet for, a client's MCP configuration.

## Success Criteria *(mandatory)*

> **Superseded/removed by Feature 013**: SC-001 through SC-004 below all
> assumed the now-permanently-removed `speckit.rollout.connect` command —
> see notice at top of file.

### Measurable Outcomes

- **SC-001**: For a supported client integration, a developer goes from
  having no LaunchDarkly MCP registration to a fully working one by running
  the setup command exactly once and setting one environment variable — no
  manual editing of client-specific configuration files required.
- **SC-002**: Running the setup command any number of times in succession
  never results in more than one LaunchDarkly MCP server entry for a given
  client, and never removes or alters a pre-existing unrelated entry.
- **SC-003**: Across every supported and unsupported client integration, 100%
  of setup command runs produce zero occurrences of a credential/token value
  in any file written or any output printed.
- **SC-004**: For a client integration without project-scoped MCP support, a
  developer can complete setup using only the printed snippet and one
  environment variable, without needing to consult external documentation to
  determine the correct configuration shape.

## Assumptions

- Spec Kit's integration catalog (the mechanism it uses to know which client
  integrations exist and which one is active for a given project) is
  determinable at the time the setup command runs.
- The canonical pinned MCP server reference (Feature 2's `mcp.*` configuration
  block) is already populated with real, non-empty values for a given
  provider deployment by the time this command is expected to succeed at the
  write path; this feature does not populate that configuration itself.
- When a project has more than one Spec Kit client integration configured
  simultaneously, the setup command acts only on the integration through
  which it is being invoked, not on every integration present in the
  project; fully general multi-client detection is out of scope.
- "Idempotent" means safe, side-effect-bounded re-invocation is expected
  normal usage, not an exceptional recovery path.
