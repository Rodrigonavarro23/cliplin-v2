@constraints
# governed_by:
#   - docs/adrs/000-cliplin-v2-agent-native.md
#   - docs/tdrs/cycle-commands.md
#   - docs/tdrs/multi-repo-coordination.md
#   - docs/tdrs/context-summary-format.md
#   - docs/tdrs/deterministic-context-discovery.md
#   - docs/tdrs/feature-constraints-format.md
#   - docs/tdrs/plugin-packaging.md
#   - docs/tdrs/reverse-engineering.md
#   - docs/tdrs/cycle-validate-report.md
#   - docs/tdrs/clarification-limits.md
#   - docs/tdrs/spec-quality-checklist.md
#   - docs/tdrs/scenario-priority.md
#   - docs/tdrs/extension-hooks.md
# conflicts: []
# gaps:
#   - "Recursion (a child repo that itself declares .gitmodules and becomes a coordinator in turn) has no dedicated scenario in this feature file — accepted as implicitly covered by re-applying Scenarios 'cycle-init runs as worker' / 'cycle-init runs as coordinator' at each level, not tested separately in this cycle"
# escalation_triggers:
#   - "A submodule declared in .gitmodules has no .cliplin/context-summary.yaml yet (scout cannot judge relevance, and must not default to not-relevant)"
#   - "A path listed in governed_by does not exist on disk when cycle-validate runs"
#   - "deterministic-context-discovery finds an existing .feature file that plausibly covers the same concept as a new request, under a different slug"
#   - "A recommended reverse-engineer run is declined by the human, leaving a child repo with no baseline context-summary.yaml — cycle-worker must proceed without one, not block"
Feature: ACD Cycle Initialization and Coordination
  As a developer using Cliplin v2 inside an AI host (e.g. Claude Code)
  I want a single entry point (cycle-init) that detects whether my repo works alone
  or coordinates changes across child repos declared as git submodules
  So that I get the same spec-first, human-approved workflow regardless of repo topology,
  without having to choose a mode manually or install a CLI/binary/vector-DB server

  @type:main
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-init runs as worker in a repo without child repos
    Given a repo with no .gitmodules file
    And a feature request with no matching .feature file for its slug
    When cycle-init is invoked with the request
    Then the agent detects worker mode
    And it runs deterministic-context-discovery locally before assuming the feature is new
    And it proceeds with the authorship cycle in this repo only

  @type:main
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-init runs as coordinator in a repo with child repos
    Given a repo with a .gitmodules file declaring at least one submodule
    When cycle-init is invoked with a feature request
    Then the agent detects coordinator mode
    And it spawns one scout sub-agent per declared submodule
    And each scout reads only that submodule's .cliplin/context-summary.yaml

  @type:main
  @status:implemented
  @changed:2026-07-13
  Scenario: coordinator delegates full work only to repos the scout marked relevant
    Given a coordinator has collected scout verdicts for its declared submodules
    And at least one submodule was marked relevant and at least one was marked not relevant
    When the coordinator proceeds to the full phase
    Then it spawns a cycle-worker sub-agent only for the relevant submodule
    And the not-relevant submodule receives no sub-agent and is not modified

  @type:main
  @status:implemented
  @changed:2026-07-13
  Scenario: context-summary.yaml is updated when a cycle closes
    Given a repo has just completed cycle-run for an approved feature
    And cycle-validate has passed for that session
    When the session closes
    Then the agent updates .cliplin/context-summary.yaml with any new concept or rule
      introduced or relied upon during the session that was not already captured
    And it does not treat context-summary.yaml as hand-maintained source of truth

  @type:edge
  # why: docs/tdrs/cycle-commands.md rule 5 requires checking for related existing
  # features before assuming "new", to avoid creating a duplicate .feature file for
  # the same behavior under a different slug
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-init finds a plausibly related existing feature under a different slug
    Given a feature request whose exact slug has no matching .feature file
    And deterministic-context-discovery finds an existing .feature file covering a
      closely related concept under a different slug
    When cycle-init evaluates whether to start authorship or evolution
    Then it does not silently create a new .feature file
    And it asks the human to confirm whether this is a new feature or an evolution
      of the related one found

  @type:edge
  # why: docs/tdrs/multi-repo-coordination.md "Escalation aggregation" rule requires
  # a single combined prompt instead of one interruption per child repo
  @status:implemented
  @changed:2026-07-13
  Scenario: coordinator aggregates gaps from multiple child repos into one escalation
    Given two or more cycle-worker sub-agents each produced unresolved gaps or
      conflicts in their local cycles
    When the coordinator aggregates results from the full phase
    Then it presents all unresolved items to the human in a single combined prompt
    And it does not escalate each child repo's gaps separately

  @type:complementary
  # why: completes coverage of the ADC completeness rule (docs/tdrs/feature-constraints-format.md)
  # at cycle close time, not only at cycle start time
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-validate blocks cycle closure when governed_by references a missing file
    Given a .feature file's @constraints block lists a path in governed_by
    And that path does not exist in the repo
    When cycle-validate runs as the closing step of cycle-run
    Then it reports the missing path and does not mark the cycle closed
    And it waits for the human to resolve it — no automatic retry, no silent skip
    And it does not update context-summary.yaml until the gap is resolved

  @type:edge
  # why: discovered by running cycle-init's coordinator path against real, unspec'd
  # repos (expressjs/express, body-parser, cookie-parser) — every real submodule
  # lacked context-summary.yaml, and the original generic escalation message gave
  # the human no concrete next step
  @status:implemented
  @changed:2026-07-13
  Scenario: scout recommends reverse-engineer when a child repo has no context-summary.yaml
    Given a coordinator has spawned a scout sub-agent for a declared submodule
    And that submodule has no .cliplin/context-summary.yaml
    When the scout reports its verdict
    Then the escalation_trigger message recommends running reverse-engineer on that
      specific repo, not a generic notice
    And the coordinator does not run reverse-engineer automatically
    And the coordinator presents the recommendation to the human and waits

  @type:main
  @status:implemented
  @changed:2026-07-13
  Scenario: reverse-engineer bootstraps context-summary.yaml on first run in an unspecced repo
    Given a repo has no Cliplin specs and no .cliplin/context-summary.yaml
    When reverse-engineer runs and the human approves at least one proposed baseline spec
    Then reverse-engineer generates .cliplin/context-summary.yaml via context-summary-sync
      reflecting only the approved specs
    And partial coverage is accepted — unsurveyed parts of the repo are left as an
      open gap, not a blocking failure

  @type:edge
  # why: comparative testing against GitHub Spec Kit (2026-07-13) confirmed
  # cycle-validate could narrate "checks passed" without the checks having
  # actually run — a real gap in the determinism claim this project makes
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-validate writes a persisted report instead of only narrating pass or fail
    Given cycle-run has reached its closing step
    When cycle-validate runs its checks
    Then it writes .cliplin/cycles/<cycle_id>.json with every check's actual evidence
      before reporting anything to the human
    And this happens whether the checks pass or fail — a failed run still produces
      a report, with overall set to fail and closed_at left null
    And context-summary-sync only runs after a report with overall:pass exists on disk
      for this cycle

  @type:edge
  # why: comparative report vs GitHub Spec Kit found their capped, prioritized
  # [NEEDS CLARIFICATION] scheme more disciplined than our open-ended interview
  @priority:P2
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-init caps clarification questions at 3, ordered by impact
    Given cycle-init's interview phase has more than 3 candidate questions
    When it selects which to ask the human
    Then it asks at most 3, ordered scope first, then security/privacy, then user
      experience, then technical details
    And any remaining candidate questions become documented default assumptions,
      not silent guesses

  @type:main
  # why: @constraints proves governance/traceability, not spec quality — this
  # closes that gap, adapted from GitHub Spec Kit's requirements.md checklist
  @priority:P2
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-init validates a draft against a quality checklist before critique
    Given cycle-init has drafted scenarios for a feature
    When it runs the quality checklist from templates/checklist.template.md
    Then it self-corrects any failing item directly, without asking the human
    And it re-checks, up to a maximum of 3 iterations
    And remaining failures after 3 iterations are documented and carried into the
      critique report rather than looped on forever

  @type:edge
  # why: cycle-commands.md already caps sessions at 3 scenarios but never decided
  # which 3 — found missing when comparing to Spec Kit's prioritized user stories
  @priority:P2
  @status:implemented
  @changed:2026-07-13
  Scenario: cycle-run selects scenarios by priority when the human doesn't specify
    Given a feature has more than 3 scenarios in scope
    And the human asked to implement "the feature" without naming specific scenarios
    When cycle-run selects scope for this session
    Then it selects @priority:P1 scenarios first, then P2, then P3
    And if more than 3 scenarios share the same priority tier, it asks the human
      to choose rather than guessing an order

  @type:complementary
  # why: comparative report vs GitHub Spec Kit found no place for a team to bolt
  # on custom behavior without editing core skills directly
  @priority:P3
  @status:implemented
  @changed:2026-07-13
  Scenario: a mandatory extension hook actually runs, not just gets announced
    Given .cliplin/extensions.yml declares a hook with optional:false at a hook point
    When cycle-init or cycle-run reaches that hook point
    Then it actually invokes the referenced skill or script and waits for it to finish
    And announcing that the hook exists is not treated as having run it

  @type:complementary
  # why: this project has no CLI/binary executor to defer condition evaluation to,
  # unlike the reference pattern — the agent itself must judge conditions
  @priority:P3
  @status:implemented
  @changed:2026-07-13
  Scenario: an extension hook with no matching condition is skipped without asking
    Given a hook entry has a natural-language condition that does not apply to
      the current cycle's context
    When cycle-init or cycle-run evaluates whether to dispatch it
    Then it judges the condition itself and skips the hook silently
    And it does not ask the human to evaluate the condition
