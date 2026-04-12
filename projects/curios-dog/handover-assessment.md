# curios-dog — Handover Assessment

**Date**: 2026-04-12
**Assessor**: Ahmed (me2resh)
**Status**: handover

## Origin

- **Where it came from**: Built in-house by me2resh as a solo project
- **Original owner**: me2resh
- **Repo location**: https://github.com/me2resh/curios-dog
- **First commit date**: 2026-04-03 (repo created)
- **Last commit date**: 2026-04-06

## Current State

### Tech stack
- Language: TypeScript (716KB), HCL (31KB)
- Runtime: Node.js 22
- Frontend: Next.js 16 (App Router), React 19, Tailwind CSS 4
- Admin dashboard: React 18 + Vite 6, Radix UI, Tailwind CSS 3
- Backend: AWS SAM, Lambda, TypeScript (DDD architecture)
- Database: DynamoDB (single-table design)
- Auth: AWS Cognito (amazon-cognito-identity-js)
- Infrastructure: Terraform (CDN, WAF, DNS, Cognito, S3, API domain) + SAM (backend API)
- Test framework: Vitest 2.1
- E2E: Playwright (planned, PR #93 open)
- CI: GitHub Actions — backend (typecheck + lint + test), frontend (build), infrastructure (terraform validate), IaC checks (TFLint, Checkov)
- Linting: ESLint + Prettier (backend + admin), ESLint (web)

### Build status
- Backend `npm run typecheck`: not attempted (no local clone)
- Backend `npm run lint`: not attempted
- Backend `npm run test`: not attempted
- Web `npm run build`: not attempted
- `terraform validate`: not attempted

### Test coverage
- Backend: 39 test files covering domain, handlers (API + admin + triggers), infrastructure — coverage percentage unknown (not attempted)
- Web: 1 test file (api-client.test.ts) — minimal
- Admin: 0 test files — no tests

### Repo activity
- Total commits (last 90 days): 86
- Open issues: 24
- Open PRs: 2 (#93 — E2E tests, #111 — Twitter OAuth)
- Top contributors: atlas-apex (78 commits), me2resh (8 commits)

### Existing AgDRs
The project has 15 Agent Decision Records — well-documented decisions:
- Infrastructure: Terraform over CDK, Cognito SDK choice, DynamoDB single-table design
- Frontend: Next.js App Router, Webpack over Turbopack
- Features: Question similarity embeddings, follow/feed fanout, trending bucketed partition keys, admin atomic counters, inbox direct lookup

## Quality Risks

### Security
- P0 security fixes already landed (PR #156): cursor injection, upload XSS, email enumeration
- WAF configured (Terraform module)
- Auth via Cognito — standard AWS approach
- `.env.example` files present for both admin and web (secrets not committed — good)
- Content moderation: admin dashboard with block/hide/report workflows

### Dependencies
- Backend: 7 production deps, all AWS SDK + logging + validation — low risk
- Web: 4 production deps (Next.js 16, React 19, Cognito SDK) — current
- Admin: 10 production deps (Amplify, Radix, React Router) — current
- No known CVEs from static read (need `/audit-deps` to confirm)

### Technical debt
- **Admin dashboard has zero tests** — 0 test files
- **Web frontend has minimal tests** — 1 test file (api-client only)
- Backend test coverage percentage unknown — needs `vitest run --coverage` to baseline
- Two open PRs aging (#93 from E2E work, #111 from Twitter OAuth) — need triage
- Duplicate AgDR IDs: two AgDR-0001, two AgDR-0002, three AgDR-0009, two AgDR-0010 — numbering collision

### Operational
- CI exists and runs on every PR — good maturity for a 9-day-old project
- No monitoring/error tracking visible (no Sentry, Datadog, CloudWatch alarms)
- No deployment automation in CI — deploy is manual (`sam deploy`, `terraform apply`)
- P0 bug open: #170 — profile picture upload broken

## Integration Plan

### Roles that apply
- **tech-lead** — architecture oversight, monorepo coordination
- **backend-engineer** — SAM/Lambda/DynamoDB, domain logic, API handlers
- **frontend-engineer** — Next.js web app + React admin dashboard
- **security-auditor** — Cognito auth, user data, content moderation, WAF
- **platform-engineer** — CI pipeline, Terraform, SAM deployment
- **sre** — production deployment, monitoring (once deployed)

### Workflows that kick in
- [x] PR workflow (`.claude/rules/pr-workflow.md`) — every change goes through a PR
- [x] AgDR for technical decisions (already in heavy use — 15 existing AgDRs)
- [x] Code Reviewer agent on every PR
- [x] Security Reviewer agent on first pass and auth-related PRs
- [x] `/audit-deps` on adoption and monthly thereafter

### Hooks to enable
- [x] `block-git-add-all`
- [x] `block-main-push`
- [x] `validate-branch-name` (ticket_prefix: GH)
- [x] `validate-pr-create`
- [x] `pre-push-gate`
- [x] `check-secrets`

### CI templates to copy in
- CI already exists — evaluate against `golden-paths/pipelines/ci.yml` for gaps
- [ ] `golden-paths/pipelines/security.yml` — add Semgrep SAST + npm audit
- [ ] `golden-paths/pipelines/pr-title-check.yml`

### Registry entry

```yaml
- name: curios-dog
  repo: me2resh/curios-dog
  workspace: workspace/curios-dog
  docs: projects/curios-dog
  status: handover
  tier: P0
  roles:
    - tech-lead
    - backend-engineer
    - frontend-engineer
    - security-auditor
    - platform-engineer
    - sre
  tags:
    - web-app
    - customer-facing
    - aws
  ticket_prefix: GH
```

## Next Steps

1. **Fix P0 bug #170 — profile picture upload broken** before any new feature work
2. **Run `/audit-deps curios-dog`** — 7 backend deps + 4 web deps + 10 admin deps need vulnerability and license check
3. **Baseline backend test coverage** — run `cd backend && npm run test:coverage` and commit a threshold
4. **Add tests for admin dashboard** — currently 0 test files for a React app with auth, CRUD, and reporting
5. **Triage the 24 open issues** — P0 (#170), 7x P1, 2x P2, and unlabeled issues need prioritization
6. **Triage the 2 stale PRs** — #93 (E2E tests) and #111 (Twitter OAuth) need decision: merge, close, or rebase
7. **Fix AgDR numbering collisions** — duplicate IDs (0001, 0002, 0009, 0010) should be renumbered

## Post-Handover Checklist

- [ ] Clone into `workspace/curios-dog/` and verify local build
- [ ] Fix P0 #170 (profile picture upload) — close before the first feature PR
- [ ] Run `/audit-deps` — baseline dependency health
- [ ] Baseline backend test coverage — scheduled in the first 2 weeks
- [ ] Add admin dashboard tests — scheduled in the first 2 weeks
- [ ] Add `curios-dog` to the weekly `/stakeholder-update` rollup
- [ ] `/decide` on monitoring strategy (CloudWatch Alarms vs Datadog vs Sentry)
- [ ] Run `/audit-deps curios-dog` monthly for the next 3 months

## Open Questions
- What is the deployment status — is staging live? Is there a production environment yet?
- Is `atlas-apex` (78 commits) a separate Claude Code instance or another contributor?
- What's the timeline for public launch?
- Is the Twitter OAuth PR (#111) still desired?
