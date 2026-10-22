# See docs/tdrs/feature-constraints-format.md for block format.

@constraints
# governed_by:
#   - docs/adrs/000-cliplin-v2-agent-native.md
#   - docs/tdrs/spec-review.md
#   - docs/tdrs/plugin-packaging.md
#   - docs/tdrs/multi-host-plugin-packaging.md
#   - docs/tdrs/feature-constraints-format.md
#   - docs/tdrs/spec-quality-checklist.md
#   - docs/tdrs/scenario-priority.md
#   - docs/tdrs/context-summary-format.md
#   - docs/tdrs/cycle-validate-report.md
# conflicts: []
# gaps:
#   - "Whether cycle-init should run spec-review on its own draft (its quality checklist step) is out of scope for this cycle; spec-review is invoked on request or by an agent that orchestrates Cliplin (e.g. Cliplin Studio's Requirements and Architect agents)"
# escalation_triggers:
#   - "If the review would need to edit a spec, or run anything other than its lint script and reading git commands, stop"
#   - "If a check can only be justified by one project's own convention rather than a framework document, leave it out of the catalog and raise it instead of adding it"
Feature: Spec review — how a project's specs are written, against Cliplin's own rules
  As a developer or an agent working in a Cliplin repo
  I want a read-only review of how the specs are written, with concrete improvements
  So that spec defects are caught before anyone builds on them, without the review changing a spec

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-10-22
  Scenario: Reviewing the whole tree leaves a report of cited findings and changes no spec
    Given a repo with features, technical decisions and a context summary
    When I ask for a spec review with no scope
    Then a report of the review is left among the repo's local Cliplin files
    And every finding cites its file and line, quotes the text and names the rule and the framework document it comes from
    And no spec, tag or context summary is changed

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-10-22
  Scenario: Reviewing only what changed since a reference
    Given a repo where two specs changed since a given reference and others did not
    When I ask for a spec review of what changed since that reference
    Then only the two changed specs are reviewed, besides excerpts of the documents they rely on
    And the report says which files it read in full and which it only sampled

  @type:main
  @priority:P1
  @status:implemented
  @changed:2026-10-22
  Scenario: Each finding says how serious it is and whether fixing it changes what the spec says
    Given a feature with a missing constraints field and a scenario whose outcome depends on another scenario
    When I ask for a spec review of that feature
    Then each finding carries a severity of blocker, major, minor or informational
    And each says whether its fix is editorial or needs a new spec cycle because it changes what the spec says

  @type:main
  # why: a read-only reviewer (e.g. Cliplin Studio's Architect) cannot write files, so the review must be usable from its answer alone
  @priority:P1
  @status:implemented
  @changed:2026-10-22
  Scenario: A review that writes nothing returns its findings in its answer
    Given a repo copy in which nothing may be written
    When I ask for a spec review whose findings come back only in its answer
    Then the answer holds the findings grouped as a report would group them
    And no file is written anywhere, including the lint's output

  @type:edge
  # why: plugin-packaging allows a standard-library python3 helper only if the skill completes without it
  @priority:P2
  @status:implemented
  @changed:2026-10-22
  Scenario: Without python the review still runs and says the lint was skipped
    Given a machine where python3 is not available
    When I ask for a spec review
    Then the review reads and judges the specs as usual
    And it says that its mechanical lint was unavailable and why

  @type:edge
  # why: human decision 2026-10-22 — the review applies Cliplin's framework rules only, never one project's conventions
  @priority:P2
  @status:implemented
  @changed:2026-10-22
  Scenario: A project's own writing convention is not reported as a defect
    Given a technical decision whose rules carry dated "Amended" notes and a "RESOLVED" line
    When I ask for a spec review of it
    Then those notes are not reported as findings
    And the review reports only what a Cliplin framework document states

  @type:complementary
  # why: practice proven in the wedov2 spec reviewer — unverified lint output must never pass as a verified finding
  @priority:P3
  @status:implemented
  @changed:2026-10-22
  Scenario: Lint output the reviewer did not confirm is kept apart from verified findings
    Given a lint result with a finding the reviewer did not open and another that is wrong
    When the review is written
    Then the unopened finding is marked as not verified
    And the wrong one is listed under the lint's calibration with the check that produced it
