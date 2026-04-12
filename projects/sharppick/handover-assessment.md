# SharpPick — Handover Assessment

**Date**: 2026-04-12
**Assessor**: Ahmed (me2resh)
**Status**: handover

## Origin

- **Where it came from**: Built in-house by me2resh as a solo project
- **Original owner**: me2resh
- **Repo location**: https://github.com/me2resh/SharpPick
- **First commit date**: 2026-04-02
- **Last commit date**: 2026-04-02

## Current State

### Tech stack
- Language: Swift 6.2
- Runtime: macOS 14+ (Sonoma)
- Framework: SwiftUI
- Database: None (reads from Apple Photos via PhotoKit)
- Test framework: None detected
- CI: GitHub Actions — manual release pipeline (DMG + ZIP artifacts)
- Build system: Swift Package Manager
- External dependencies: None (all Apple frameworks: Photos, Vision, CoreImage)

### Build status
- `swift build`: not attempted (no local clone)
- `swift test`: not attempted
- Lint: no linter configured

### Test coverage
- Estimated: **0%** — no test targets in Package.swift, no test files in the tree

### Repo activity
- Total commits: 3
- Commits in last 90 days: 3 (project is 10 days old)
- Open issues: 4
- Open PRs: 0
- Top contributors: me2resh (2 commits), actions-user (1)

### Open issues
1. [Feature] License key protection for commercial distribution
2. [Security] Security review before public release
3. [Release] Apple App Store review preparation
4. [Feature] Auto-update mechanism for direct distribution

### Existing AgDRs
The project already has 3 Agent Decision Records — good practice carried over:
- AgDR-0001: Feature print caching strategy
- AgDR-0002: Clustering algorithm
- AgDR-0003: Sharpness scoring method

## Quality Risks

### Security
- No security review has been performed (issue #2 is open for this)
- App accesses the user's full Photos library via PhotoKit — entitlement surface
- Ad-hoc code signing in CI (no notarization, no Developer ID)
- No secrets or credentials detected in the repo (good — zero external dependencies)

### Dependencies
- Zero external dependencies — no supply chain risk
- Uses Swift 6.2 (latest) and macOS 14+ — current and supported

### Technical debt
- **No tests** — zero test targets, zero test files. This is the biggest gap.
- No linter or formatter configured (no SwiftLint, no swift-format)
- No `.swiftlint.yml` or equivalent code quality tooling
- Release pipeline commits directly to main via GitHub Actions bot (no PR for version bumps)

### Operational
- CI is release-only (manual trigger) — no build/test pipeline on PRs
- No monitoring, crash reporting, or telemetry (by design — privacy-first app)
- No code signing with Developer ID — app will trigger Gatekeeper warnings
- No notarization — required for non-App Store distribution on modern macOS

## Integration Plan

### Roles that apply
- **tech-lead** — architecture oversight, decision review
- **frontend-engineer** — SwiftUI is the UI layer (closest match in the role set)
- **security-auditor** — Photos library access, code signing, distribution security
- **platform-engineer** — CI pipeline needs PR checks, not just release

### Workflows that kick in
- [x] PR workflow (`.claude/rules/pr-workflow.md`) — every change goes through a PR
- [x] AgDR for technical decisions (already in use — 3 existing AgDRs)
- [x] Code Reviewer agent on every PR
- [x] Security Reviewer agent on first pass and high-risk PRs
- [ ] `/audit-deps` — not applicable (zero external dependencies)

### Hooks to enable
- [x] `block-git-add-all`
- [x] `block-main-push`
- [x] `validate-branch-name` (ticket_prefix: GH)
- [x] `validate-pr-create`
- [x] `pre-push-gate`
- [x] `check-secrets`

### CI templates to copy in
- [ ] `golden-paths/pipelines/ci.yml` — adapt for Swift (replace npm commands with swift build/test)
- [ ] `golden-paths/pipelines/security.yml` — secrets detection still applies
- [ ] `golden-paths/pipelines/pr-title-check.yml`

### Registry entry

```yaml
- name: sharppick
  repo: me2resh/SharpPick
  workspace: workspace/sharppick
  docs: projects/sharppick
  status: handover
  tier: P1
  roles:
    - tech-lead
    - frontend-engineer
    - security-auditor
    - platform-engineer
  tags:
    - desktop-app
    - macos
    - privacy-first
  ticket_prefix: GH
```

## Next Steps

1. **Add a test target to Package.swift and write unit tests for the services layer** — ClusteringService, SimilarityEngine, and ImageQualityAnalyzer are pure logic and testable without Photos access. Coverage is currently 0%.
2. **Set up a PR-triggered CI workflow** — the current `release.yml` only runs on manual dispatch. Copy and adapt `golden-paths/pipelines/ci.yml` for `swift build && swift test` on every PR.
3. **Run `/security-review` on the codebase** — issue #2 is open for this. PhotoKit entitlements, ad-hoc code signing, and distribution model need review before public release.
4. **`/decide` on code signing and distribution strategy** — ad-hoc signing vs Developer ID vs App Store. This affects issues #1 (license keys), #3 (App Store), and #4 (auto-update).
5. **Add SwiftLint or swift-format** — no code quality tooling currently in place.

## Post-Handover Checklist

- [ ] Clone into `workspace/sharppick/` for local development
- [ ] Add test target and reach >80% coverage on services layer — close before the first feature PR
- [ ] Set up PR-triggered CI — scheduled in the first 2 weeks
- [ ] Complete security review (issue #2) before any public distribution
- [ ] Decide on distribution model (issue #1, #3, #4) via `/decide`
- [ ] Add `sharppick` to the weekly `/stakeholder-update` rollup
- [ ] Run `/code-review` on the most recent commit to calibrate review standards

## Open Questions
- What is the target distribution model — App Store, direct DMG, or both?
- Is commercial licensing planned (issue #1) or will this be free/open-source?
- Are there plans to support older macOS versions (pre-Sonoma)?
