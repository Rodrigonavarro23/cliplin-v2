@constraints
# governed_by:
#   - docs/adrs/000-cliplin-v2-agent-native.md
#   - docs/tdrs/multi-host-plugin-packaging.md
#   - docs/tdrs/plugin-packaging.md
#   - docs/tdrs/installation.md
# conflicts: []
# gaps: []
# escalation_triggers:
#   - "A host changes its plugin or marketplace manifest schema"
Feature: Install Cliplin v2 in multiple AI development hosts
  As a developer using Cliplin v2
  I want the same harness to install in Claude Code and Codex
  So that its spec-first workflow remains host-neutral without duplicating its skills

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-08-30
  Scenario: Claude Code installs the shared plugin through its marketplace
    Given the repository contains the shared plugin under plugins/cliplin-v2
    When the developer uses the Claude installer
    Then Claude Code registers the .claude-plugin marketplace
    And it installs cliplin-v2 from that marketplace

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-08-30
  Scenario: Codex installs the shared plugin through its marketplace
    Given the repository contains a valid .agents/plugins/marketplace.json
    And plugins/cliplin-v2 contains a valid .codex-plugin/plugin.json
    When the developer uses the Codex installer
    Then Codex registers the repository marketplace
    And it installs cliplin-v2 from that marketplace

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-08-30
  Scenario: both hosts consume one canonical skill set
    Given Claude Code and Codex load plugins/cliplin-v2
    When either host discovers the plugin skills
    Then both hosts read the same skills directories
    And no host-specific copy of a skill is required

  @type:edge
  @priority:P2
  @status:implemented
  @changed:2026-08-30
  Scenario: the legacy installer remains compatible
    Given an existing user invokes install.sh with a supported argument
    When the installer runs
    Then it delegates to the Claude-specific installer
    And existing Claude installation commands keep their behavior
