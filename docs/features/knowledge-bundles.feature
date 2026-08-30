@constraints
# governed_by:
#   - docs/tdrs/knowledge-bundle-management.md
#   - docs/tdrs/deterministic-context-discovery.md
#   - docs/tdrs/context-summary-format.md
#   - docs/tdrs/feature-constraints-format.md
#   - docs/tdrs/plugin-packaging.md
#   - docs/business/cliplin-framework.md
# conflicts: []
# gaps: []
# escalation_triggers:
#   - "A bundle's manifest entry points to a source that no longer resolves (git clone/sparse-checkout fails)"
#   - "Two enabled bundles declare the same priority and genuinely contradict on the same concept"
Feature: Knowledge Bundle Management
  As a developer using Cliplin v2
  I want to install, remove, and update domain knowledge packages (bundles) from git sources
  So that I can reuse shared governance (e.g. accessibility, security architecture) without
  authoring it from scratch, the same capability GitHub Spec Kit offers via presets — without
  needing a CLI, and without changing how existing .feature/@constraints/context-summary.yaml work

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-07-13
  Scenario: installing a bundle makes its content discoverable without changing existing schemas
    Given no bundle is installed yet
    When the human asks to add a bundle from a git source
    Then knowledge-bundle clones it under .cliplin/knowledge/<name>-<source>/
    And it appends an entry to .cliplin/bundles.yaml
    And context-summary-sync folds in the bundle's concepts and rules
    And the .feature, @constraints, and context-summary.yaml schemas are unchanged —
      the bundle only adds more find_via targets, nothing about the format changes

  @type:main
  @priority:P2
  @status:implemented
  @changed:2026-07-13
  Scenario: deterministic-context-discovery finds concepts from an installed bundle
    Given a bundle is installed and enabled
    When cycle-init runs deterministic-context-discovery for a matching concept
    Then the glob fan-out searches .cliplin/knowledge/** in addition to docs/
    And a matching TDR/ADR from the bundle can be cited in governed_by

  @type:edge
  # why: docs/tdrs/knowledge-bundle-management.md requires priority to only
  # order compatible overlap, never silently resolve a real contradiction
  @priority:P2
  @status:implemented
  @changed:2026-07-13
  Scenario: priority orders compatible overlap between two sources without asking
    Given two enabled bundles both have a TDR touching the same concept
    And their content does not actually contradict, only overlaps
    When deterministic-context-discovery matches both
    Then the higher-priority bundle's doc is cited first in governed_by
    And the human is not asked to resolve anything

  @type:edge
  # why: same TDR rule — a genuine contradiction must never be silently
  # decided by priority, it's always a human decision
  @priority:P2
  @status:implemented
  @changed:2026-07-13
  Scenario: a genuine contradiction between sources still escalates despite priority
    Given two enabled bundles have TDRs that actually contradict each other on
      the same concept, not just overlap
    When deterministic-context-discovery matches both
    Then it is recorded as a [CONFLICT], not silently resolved by priority
    And it is escalated to the human the same as any other conflict

  @type:complementary
  # why: prevents an installed bundle from quietly overriding a project's own
  # governing decisions, which would be a surprising and risky default
  @priority:P3
  @status:implemented
  @changed:2026-07-13
  Scenario: project-native docs are not silently overridden by a bundle
    Given a project-native TDR and a bundle TDR cover the same concept
    And the bundle was not explicitly configured with a higher priority than
      project-native docs
    When deterministic-context-discovery matches both
    Then the project-native doc is treated as higher priority by default
