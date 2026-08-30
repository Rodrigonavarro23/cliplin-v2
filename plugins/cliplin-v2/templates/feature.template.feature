# Skeleton for a new .feature file — see docs/tdrs/feature-constraints-format.md
# Fill @constraints only after context loading + gap assessment (cycle-init Step 0.5/0.6).
# The Feature: description block is human-owned — the agent proposes, never rewrites it later.

@constraints
# governed_by:
#   - <path>
# conflicts: []
# gaps: []
# escalation_triggers: []
Feature: <Feature Name>
  As a <actor>
  I want <capability>
  So that <benefit>

  @type:main
  @status:new
  Scenario: <scenario name>
    Given <precondition>
    When <action>
    Then <observable outcome>
