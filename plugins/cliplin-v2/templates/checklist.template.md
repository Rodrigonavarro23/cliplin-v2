# Spec Quality Checklist: <Feature Name>

## Content quality
- [ ] No implementation detail leaked into Feature:/Scenario: text (no framework, language, API names)
- [ ] Written in business/observable-behavior language, not system-internal language

## Scenario completeness
- [ ] Every scenario has concrete Given/When/Then — no placeholder or vague steps
- [ ] Every scenario is independently testable on its own
- [ ] Edge cases implied by governing TDRs/ADRs are covered or explicitly noted as a gap
- [ ] Every agent-proposed scenario has `@type` and, if edge/complementary, a `# why:` citing its source

## Constraints completeness
- [ ] `governed_by` is non-empty
- [ ] `conflicts` and `gaps` are explicit lists (`[]` if none), never omitted

## Notes
<!-- Only filled if items still fail after 3 self-correction iterations (docs/tdrs/spec-quality-checklist.md) -->
