# Changelog

All notable changes to the `rollout` extension are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-07

### Added

- Initial extension skeleton: `extension.yml` manifest declaring package
  metadata, 8 commands (7 phase briefings + `connect`), 7 non-optional
  `before_*` lifecycle hooks, and a `rollout-config.yml` config declaration.
- Placeholder command files for all 8 declared commands.
- Placeholder `rollout-config.template.yml` configuration template.
- Packaging files: `README.md`, `LICENSE` (MIT), `.extensionignore`.

Real rollout doctrine, gate scripts, provider configuration values, and MCP
wiring are intentionally out of scope for this release — see
[docs/foundation/vision.md](docs/foundation/vision.md).
