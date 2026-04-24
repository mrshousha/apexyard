# Ravely

> A single SEO-optimised home for every EDM event, starting in Spain and expanding globally.

**Status**: active · **Tier**: P0 · **Owner**: Mohamed Shousha (solo) · **Source idea**: [IDEA-001](../ideas-backlog.md)

---

## What Ravely is

Ravely is an EDM events aggregator. It surfaces every EDM event in Spain — in Barcelona, Madrid, Ibiza, Valencia, Seville and Bilbao — with links to every known ticket seller for each event, plus enriched profiles of the DJs playing (photo, short bio, DJ Mag rank where applicable, Resident Advisor profile link, Spotify). The target audience is EDM fans who today hop between 5+ platforms (Resident Advisor, DICE, Ticketmaster, Fever, Xceed, promoter Instagram accounts) to find a single event and buy a ticket.

Ravely's wedge is **aggregation + enrichment + SEO**. Competing aggregators (Xceed, Fever, DICE) are app-first and cede the SEO surface; Ravely is web-first and searchable from day one.

## Current phase

**Tech Design** — PRD approved (v1, dated 2026-04-23), Next.js scaffold pushed. Next steps:

1. AgDRs for the key technical decisions (scrape-first strategy, ingest pipeline architecture, rendering strategy, dedup algorithm, DJ slugs)
2. Wireframes + component library
3. First ingest adapters (Ticketmaster API, Eventbrite API, 5 venue scrapers)

## Key docs

| Doc | Purpose |
|-----|---------|
| [`prd-v1.md`](prd-v1.md) | v1 Product Requirements Document — the source of truth for scope, users, metrics, and timeline |
| (coming) `architecture/ravely-context.md` | C4 Level 1 — system context + external actors |
| (coming) `architecture/ravely-container.md` | C4 Level 2 — deployable units |
| (coming) `roadmap.md` | Longer-horizon roadmap beyond v1 launch |

## Key links

| Resource | Where |
|----------|-------|
| Code | [mrshousha/ravely](https://github.com/mrshousha/ravely) (private) |
| Local clone | `workspace/ravely/` (gitignored in this ops fork) |
| Issue tracker | GitHub Issues on `mrshousha/ravely` (prefix: `GH`) |
| Hosting | Vercel (TBD — domain not yet chosen) |
| Database | Postgres (Vercel Postgres or Neon, TBD at Tech Design) |

## v1 scope at a glance

| | |
|---|---|
| **Geography** | Spain only (flagship cities: Barcelona, Madrid, Ibiza, Valencia, Seville, Bilbao) |
| **Language** | English only; Spanish + others deferred to v1.1 |
| **Data sources** | Ticketmaster API + Eventbrite API + SeatGeek API + direct scraping of flagship venue calendars (Ibiza superclubs + BCN/Madrid clubs) |
| **Explicitly not scraped** | Resident Advisor, DICE, Fever, Xceed — partnership track only |
| **Not in v1** | User accounts, on-site ticketing, reviews, mobile app, festival grouping, non-EDM genres, countries outside Spain |
| **Monetisation** | Deferred to post-launch; AdSense once traffic justifies it |
| **Launch windows** | Soft launch 2026-07-30 · public launch 2026-09-10 |

## v1 success metrics

- **Coverage**: ≥ 70% of advertised EDM events in Spain for next 90 days at launch
- **Indexed pages**: ≥ 10k pages in Google within 4 weeks of soft launch
- **Organic sessions**: 10k/mo at month 3, 50k/mo at month 6
- **Core Web Vitals (75p)**: LCP < 2.5s, CLS < 0.1, INP < 200ms
- **Lighthouse SEO**: ≥ 95 on event, DJ, city index pages
- **Structured data**: 100% of event pages with valid schema.org `Event`

## Stack

Next.js (App Router) + TypeScript + React · Tailwind CSS · Prisma + PostgreSQL · Vercel hosting · Vitest + Playwright · Sentry · Vercel Analytics. Matches the defaults in the ApexYard fork's [`onboarding.yaml`](../../onboarding.yaml).

## Activated roles

Mohamed wears every hat contextually via [ApexYard role-triggers](../../.claude/rules/role-triggers.md). For Ravely specifically, the most frequently activated roles are:

- **Product Manager** — PRD evolution, acceptance criteria, metric reviews
- **Tech Lead** — technical design, AgDRs, code-review approval
- **Backend Engineer** — ingest pipeline, data model, API routes
- **Frontend Engineer** — Next.js pages, SEO wiring, Tailwind components
- **UI Designer** / **UX Designer** — wireframes, component library
- **QA Engineer** — acceptance-criteria verification post-merge
