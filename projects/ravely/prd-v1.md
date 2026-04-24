# PRD: Ravely — EDM Events Aggregator (v1 MVP)

**Status**: Draft
**Author**: Mohamed Shousha (acting as Product Manager)
**Created**: 2026-04-23
**Last Updated**: 2026-04-23
**Source idea**: IDEA-001 (see `projects/ideas-backlog.md`)

---

## Overview

### Problem Statement

If you're an EDM fan today, finding a ticket for an event you care about requires a manual scavenger hunt across **5+ disconnected platforms**: Resident Advisor for clubs, DICE for curated picks, Ticketmaster / See Tickets / Skiddle for larger events, Eventbrite for promoter-run parties, Fatsoma for UK nights, and the artist's own Instagram or mailing list for lineup confirmation. Each platform has partial coverage. None of them give you a clean view of "what's on in Berlin this weekend for techno fans, across every ticket seller, with who's playing and whether I've heard of them."

The fan's real question is **"what events match my taste, where, and when — and where do I buy the ticket?"** — not "which of seven websites should I check first." Ravely answers that question in one place.

### Target User

**Primary — EDM fans (aged ~18-35) actively looking for events to attend**. Sub-segments:

- **Casual ravers**: follow 2-3 favourite DJs, want to know when they play nearby
- **Festival-goers**: plan multi-day trips across Europe (Awakenings, Tomorrowland, Dekmantel, etc.)
- **Club regulars**: care about weekly line-ups in their home city (Barcelona, Madrid, Valencia, Seville)
- **Travelling ravers**: visit a Spanish city (especially **Ibiza** in summer) and want to know what's on that weekend

**Secondary — DJ followers** arriving via search ("DJ [name] tour dates") — they land on a DJ profile, discover the DJ's upcoming gigs, click out to the ticket seller.

**Not yet in scope**: promoters (listing management), venues (venue claims), industry pros (booking contacts).

### Goals

1. **Coverage** — by v1 launch, index ≥ 70% of advertised EDM events in **Spain** (flagship cities: Barcelona, Madrid, Ibiza, Valencia, Seville, Bilbao) for the next 90 days. Spain-first is deliberate: tighter scope, better depth, cleaner SEO story, and the right ramp before expanding to neighbouring countries.
2. **Discoverability** — rank on Google page 1 within 6 months for long-tail queries like `"techno events barcelona this weekend"`, `"ibiza club calendar [month]"`, `"[DJ name] tour dates 2026"`, and `"[venue name] próximos eventos"`.
3. **Aggregation** — every event page links out to **every known ticket source** for that event, not just one. The user never has to keep searching after landing on Ravely.
4. **Enrichment** — every DJ on a lineup links to a Ravely DJ profile with photo, short bio, DJ Mag rank (if top 100), Resident Advisor profile link, Spotify / SoundCloud links, and upcoming gigs.
5. **Performance / SEO** — Core Web Vitals all green (LCP < 2.5s, CLS < 0.1, INP < 200ms); Lighthouse SEO ≥ 95; all event pages have valid schema.org `Event` structured data.

### Non-Goals (Out of Scope for v1)

- **User accounts / login / saved events** — deferred to v2. v1 uses localStorage for any personalisation (recently viewed, favourites).
- **Direct ticket purchase on Ravely** — v1 always links out to the ticket seller. No payment integration, no affiliate checkout flows on-site.
- **Review / rating submission by users** — ratings come from third-party sources (DJ Mag) in v1, not from Ravely users.
- **Promoter / venue self-serve listing dashboard** — v1 events are ingested from APIs + curated. No promoter-facing CMS.
- **Mobile app** — v1 is a responsive web app. Native apps are v3+.
- **Social features** (friends, attending lists, chat) — deferred.
- **Genres outside EDM** — techno, house, trance, DnB, hardstyle, psytrance, dubstep, UK garage, drum & bass, bass music, minimal, progressive. Not hip-hop, not rock, not pop.
- **Countries outside Spain** — globally extendable by design, but v1 scope is Spain only. First expansion target (v1.1, ~3 months post-launch): Portugal + Germany (based on tourist flows into Ibiza and Berlin's gravity in the scene).

### Success Metrics

| Metric | Target | Measured by | Horizon |
|--------|--------|-------------|---------|
| **Event coverage** | ≥ 70% of advertised EDM events in Spain for next 90 days | Weekly manual spot-check against RA + DICE + Xceed for 6 flagship cities | v1 launch |
| **Indexed pages** | ≥ 10k pages indexed in Google | Google Search Console | +4 weeks post-launch |
| **Organic sessions / month** | 10k (month 3), 50k (month 6) | Vercel Analytics / GA4 | +3 / +6 months |
| **Outbound CTR to ticket seller** | ≥ 15% of event-page sessions click a ticket link | Event-listener tracking → analytics | +1 month post-launch |
| **Core Web Vitals (75th percentile)** | LCP < 2.5s, CLS < 0.1, INP < 200ms | Vercel Speed Insights | continuous |
| **Lighthouse SEO score** | ≥ 95 on event, DJ, city index pages | CI-run Lighthouse on representative URLs | per-deploy |
| **Structured data coverage** | 100% of event pages have valid schema.org `Event` | Google Rich Results Test in CI | per-deploy |
| **DJ profile completeness** | ≥ 80% of DJs on lineups have a Ravely profile page with photo + 1+ external link | Data pipeline report | +2 months post-launch |

**Leading indicators** (weeks 1-4 post-launch): indexed page count, crawl rate, bounce rate, pages per session, outbound CTR.
**Lagging indicators** (months 3-6): organic sessions, backlink count, ranking positions for target queries.

---

## User Stories

### US-1: Find events in my city this weekend

> As a **club regular**, I want to **see every EDM event in my city this Friday-Sunday** across every ticket platform, so that **I can pick one without opening five tabs**.

**Acceptance Criteria**:

- [ ] Landing on `/events/[city]` shows an upcoming-events list, ordered by date ascending
- [ ] Each event card shows: date, time, headliners, venue, genre tags, price-from, "tickets from N sellers" count
- [ ] Filters for date range (weekend / week / month / custom), genre, venue, price range
- [ ] Empty states if no events, with nearby-city suggestions
- [ ] URL reflects filters (shareable, SEO-friendly): `/events/barcelona?from=2026-05-01&genre=techno`

### US-2: Follow a DJ's tour

> As a **casual raver**, I want to **search a DJ's name and see their upcoming gigs in Spain**, so that **I can catch them live next time they play somewhere I can travel to**. (Gigs outside Spain may appear as a secondary "outside coverage area" list in v1.1.)

**Acceptance Criteria**:

- [ ] DJ search autocompletes from typed name
- [ ] `/djs/[slug]` shows photo, 1-2 sentence bio, DJ Mag rank (if applicable), external links (RA, SoundCloud, Spotify, Instagram)
- [ ] "Upcoming gigs" section lists next ≥ 6 months of bookings, grouped by month
- [ ] Each gig links to the event page on Ravely
- [ ] Graceful fallback if we only have partial data (e.g. unknown rank → hide the field, not "N/A")

### US-3: Decide whether an event is worth going to

> As a **travelling raver**, I want to **see the full lineup of an event with links to each DJ's profile**, so that **I can gauge whether I'll enjoy it before committing to buy**.

**Acceptance Criteria**:

- [ ] Event page shows headliners prominently, full lineup below
- [ ] Every DJ in the lineup is clickable (if DJ exists in our DB) or shown as plain text (if not)
- [ ] Venue section shows name, address, map pin (linking to Google Maps), capacity if known
- [ ] "Buy tickets" section lists every known ticket seller with deep-links and price-from per seller
- [ ] Schema.org `Event` structured data matches on-page content (for Google rich result eligibility)

### US-4: Arrive via Google search

> As a **first-time visitor**, I want to **land on Ravely from a Google search like "techno berlin this weekend" and get an answer immediately**, so that **I bookmark the site and come back**.

**Acceptance Criteria**:

- [ ] Landing page renders the list server-side (no skeleton screens, no JS-required content)
- [ ] Page `<title>`, `<meta description>`, OpenGraph, Twitter Card all present and match query intent
- [ ] Page loads < 2.5s on a mid-range mobile (throttled 4G in Lighthouse CI)
- [ ] Breadcrumb schema present and rendered visibly
- [ ] Canonical URL is the filter-free version to avoid duplicate-content penalties

### US-5: Find a venue and see what's on

> As any user, I want to **search by venue name and see upcoming events there**, so that **I can follow my favourite clubs**.

**Acceptance Criteria**:

- [ ] `/venues/[slug]` shows venue name, city, address, map, capacity
- [ ] Upcoming events list, same card format as US-1
- [ ] "Past events (last 30 days)" collapsed section with simple titles (SEO helper)

### Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Event cancelled after ingestion | Show "Cancelled" badge; keep page up (SEO preservation) with cancellation note; no ticket links |
| Event sold out | Show "Sold out" badge on ticket-seller rows; keep non-sold-out sellers clickable |
| Lineup changes after ingestion | Page re-generated on next revalidation; old lineup never surfaced; no page-version history in v1 |
| Duplicate events across sources | Dedupe key = `(venue_slug, start_datetime, headliner_slug)`; canonical event = earliest-ingested; other sources merged as additional ticket links |
| DJ with only one gig | DJ page still renders with single gig; "tour" language avoided in UI if count ≤ 1 |
| City with no upcoming events | "No events in [City] right now. Nearby: [Nearby city, N events]" with 2-3 nearest-by-distance suggestions |
| Unparseable DJ name in source data | Ingested as free-text lineup entry, not linked; flagged for manual review |
| Same-day event added | Appears within 1 hour of next scheduled ingest run; not real-time |
| Recurring weekly night (e.g. "Berghain every Saturday") | Each date is a separate event page; series grouping deferred to v2 |
| Genre ambiguity (event tagged "house" but actually techno) | v1 trusts source tags; v2 adds manual curation layer |

---

## Requirements

### Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | Event list page per city with filters (date, genre, venue, price) | Must | `/events/[city]` + query params |
| FR-2 | Event detail page with full lineup, venue, multiple ticket-seller links | Must | `/events/[city]/[slug]` |
| FR-3 | DJ profile page with photo, bio, external links, upcoming gigs | Must | `/djs/[slug]` |
| FR-4 | Venue profile page with address + upcoming events | Must | `/venues/[slug]` |
| FR-5 | Global search (events, DJs, venues, cities) | Must | Debounced autocomplete |
| FR-6 | Data pipeline ingesting from ≥ 2 ticket platform APIs | Must | See Technical Notes |
| FR-7 | Deduplication of cross-platform events | Must | Key: venue + start time + headliner |
| FR-8 | Schema.org `Event`, `Place`, `MusicEvent`, `BreadcrumbList` structured data | Must | Google rich-result eligibility |
| FR-9 | Dynamic sitemap generation (per-city, per-DJ, per-venue) | Must | `sitemap.xml` + paginated children |
| FR-10 | SEO meta tags (title, description, OG, Twitter Card) per page | Must | Generated from page data |
| FR-11 | Admin-only data-quality dashboard (unparsed lineups, duplicate suspects) | Should | Simple internal page behind basic-auth |
| FR-12 | DJ Mag Top 100 integration (rank + year) | Should | Annual import; manual for first run |
| FR-13 | Resident Advisor profile links for DJs + venues | Should | URL mapping; scraping deferred |
| FR-14 | Google AdSense integration on event + DJ pages | Should | Only if doesn't tank Core Web Vitals |
| FR-15 | "Save for later" via localStorage (no login needed) | Could | Heart icon, stored client-side |
| FR-16 | Map view of events in a city | Could | Leaflet + OpenStreetMap, progressive enhancement |
| FR-17 | RSS feed per city + per DJ | Could | Power-user feature, SEO side-benefit |
| FR-18 | Email newsletter signup | Could | Monthly digest; integrates with v2 accounts |
| FR-19 | Festival aggregation (group multi-day events) | Won't (v1) | Deferred to v2 |
| FR-20 | User accounts | Won't (v1) | Deferred to v2 |

**Priority Key**: Must (required for launch) · Should (important, fall-back acceptable) · Could (nice to have) · Won't (explicitly out)

### Non-Functional Requirements

| Category | Requirement | Target |
|----------|-------------|--------|
| Performance | LCP (75th percentile, mobile) | < 2.5s |
| Performance | CLS (75th percentile) | < 0.1 |
| Performance | INP (75th percentile) | < 200ms |
| Performance | First Contentful Paint | < 1.8s |
| SEO | Lighthouse SEO score (event / DJ / city index) | ≥ 95 |
| SEO | Indexable pages (no `noindex` on content pages) | 100% |
| SEO | Duplicate-content handling | Canonical URLs; filters param-based, canonical = filter-free |
| Accessibility | WCAG | Level AA |
| Accessibility | Keyboard navigation | All interactive elements reachable + focus-visible |
| Security | Transport | HTTPS-only, HSTS preload eligible |
| Security | Content Security Policy | Strict CSP; allowlist analytics + ad domains only |
| Security | No user accounts | → no auth attack surface in v1 |
| Privacy | Analytics | Cookieless by default (Vercel Analytics or Plausible); GDPR/ePrivacy-compliant |
| Privacy | Cookie banner | Only if ads require it (AdSense = yes); Klaro or similar |
| Availability | Uptime | 99.5% (Vercel baseline) |
| Availability | Data freshness | Ingest every 2 hours; stale data banner if > 24h |
| Compliance | GDPR | No personal data collected (no accounts); analytics anonymised |
| Observability | Error tracking | Sentry (free tier) |
| Observability | Analytics | Vercel Analytics (page views, Core Web Vitals) + GA4 (optional) |

---

## Design

### Primary User Flows

**Flow A: Discovery from Google**

```
Google search "techno barcelona saturday"
      |
      v
/events/barcelona?from=<saturday>&genre=techno   [SSR, first-paint ≤ 1.8s]
      |
      v
Event card --> /events/berlin/[slug]          [event detail]
      |
      v
"Buy tickets" deep-link to seller              [outbound click, tracked]
      |
      +--> (user returns via back) --> another event card
      |
      +--> DJ on lineup --> /djs/[slug] --> their upcoming gigs
```

**Flow B: Following a DJ**

```
Search "solomun tour dates"
      |
      v
/djs/solomun                                  [SSR, DJ profile]
      |
      v
Upcoming gigs list --> click a gig --> /events/[city]/[slug]
      |
      v
Buy tickets --> external seller
```

**Flow C: Planning a weekend trip**

```
/events/ibiza?from=2026-06-05&to=2026-06-08
      |
      v
Filtered list across 3 days, sortable by DJ-mag-rank-of-headliner
      |
      v
Save 3 events to localStorage (heart icon)
      |
      v
Return next day, hearts persist on device
```

### Page Inventory

| Page | Route | Rendering | Priority |
|------|-------|-----------|----------|
| Home | `/` | SSG + ISR | Must |
| City index | `/events/[city]` | SSR + ISR (1h) | Must |
| Event detail | `/events/[city]/[slug]` | SSG + on-demand ISR | Must |
| DJ profile | `/djs/[slug]` | SSR + ISR (6h) | Must |
| Venue profile | `/venues/[slug]` | SSR + ISR (24h) | Must |
| Genre index | `/genres/[genre]` | SSR + ISR (6h) | Should |
| Country index | `/events/spain` (single country in v1) | SSR + ISR (1h) | Should |
| Region index (Balearics / Catalonia / Madrid / etc.) | `/events/[region]` | SSR + ISR (6h) | Could |
| Search results | `/search?q=...` | CSR | Must |
| About / Privacy / Terms | `/about`, `/privacy`, `/terms` | Static | Must |
| Admin data-quality | `/admin/...` (basic-auth) | SSR | Should |

### Wireframes

Not attached — designer role will produce wireframes at the Design phase (post-PRD approval). Figma file to be linked here when ready.

---

## Technical Notes

### Stack (per `onboarding.yaml`)

- **Framework**: Next.js (App Router) + React + TypeScript
- **Database**: PostgreSQL + Prisma
- **Hosting**: Vercel
- **Styling**: Tailwind CSS
- **Testing**: Vitest (unit) + Playwright (E2E)
- **Analytics**: Vercel Analytics (Core Web Vitals + page views) + GA4 (optional)
- **Error tracking**: Sentry

### Data Sources (v1 ingest pipeline, Spain-focused)

**Strategy**: scrape-first from **direct venue sites** in parallel with API integrations, with a partnership track running alongside (not gating). The logic: ship with evidence of traffic and value, then approach aggregators for partnership from a position of strength. This is a deliberate trade-off — see legal risks below — and will be recorded as an AgDR at Tech Design time.

| Source | Access | Spain coverage | Notes |
|--------|--------|----------------|-------|
| **Ticketmaster Discovery API** | Official, free tier | Strong — Spain market served | Larger events, festivals, some club nights |
| **Eventbrite API** | Official, free tier | Medium — promoter-run events | Long tail; noise filtering required |
| **SeatGeek API** | Official, free tier | Light Spain coverage | Backup source |
| **Direct venue scraping — Ibiza superclubs** | Politely scraped public event pages; respect `robots.txt`; 1 req / 10s; 24h cache; identified `User-Agent` | High — Pacha, Hï, Ushuaïa, DC10, Amnesia, Privilege, Eden, Octan | ~10 clubs carry 80% of Ibiza summer traffic; own-site scraping is lower legal risk than aggregator scraping |
| **Direct venue scraping — flagship Spanish clubs** | Same approach | Medium — Razzmatazz (BCN), Apolo (BCN), Moog (BCN), Fabrik (Madrid), Mondo Disko (Madrid) | Tight venue list; each runs own calendar |

**Not scraped (partnership targets, protect the relationship)**: Resident Advisor, DICE, Fever, **Xceed**. These are aggregators in the same space we want to partner with — scraping them poisons those conversations. Approach each through formal partnership in months 2-3, before public launch if possible.

### Legal risk and mitigations (scrape-first strategy)

The EU Database Directive 96/9/EC grants a sui generis right that prohibits substantial extraction or reuse of a database's contents, independent of copyright. Venue event calendars qualify as protected databases. Scraping them creates legal exposure that must be mitigated:

| Risk | Mitigation in v1 |
|------|------------------|
| EU Database Directive claim from a venue / aggregator | Scrape only **publicly visible detail pages**, not bulk calendar extracts; identified `User-Agent` with contact email; modest extraction volume per source; 24h+ cache; honour takedown requests within 24h; AgDR documenting the decision |
| `robots.txt` violations | Every scraper respects `robots.txt` by default; any path-level `Disallow` is honoured; adapter framework blocks disallowed paths at the library layer |
| ToS violations | Per-source ToS check logged before first scrape; "risky sources" list maintained; hard-ban list for any source that explicitly prohibits scraping |
| Rate limiting / IP bans | Polite scraping: minimum 10s between requests per domain; exponential backoff on 429/503; cache-first (re-scrape no sooner than 24h) |
| Partnership poisoning | **No scraping of Xceed / DICE / Fever / RA** — only direct venue sites. Aggregators = partnership targets only |
| Layout changes breaking adapters | Each scraper is a thin isolated adapter; failure budget: 1-2 adapter rewrites/month baked into plan |
| "Thin content" Google spam penalty | Scraped event data is enriched with Ravely-original content: DJ profiles, ticket-seller aggregation, structured data, editorial copy per city. No zombie aggregator pages. |

**Exit strategy**: any source that asks us to stop, gets stopped within 24h. Any source that offers an API or partnership, we switch to that. Scraping is not the destination — it's the bootstrap.

**Spain-specific data-source strategy**: because the major Spain aggregators (Fever, Xceed, DICE, RA) have no APIs and are partnership-track, v1 depth comes from **direct venue scraping + APIs**. Spain's scene is venue-concentrated (~25 venues carry most of the relevant events), which makes a venue-calendar adapter pattern tractable. The ingest pipeline is built as **a single adapter interface with multiple implementations** (REST API adapter, HTML scraper adapter, RSS adapter, iCal adapter) so new sources plug in without pipeline-level changes.

### DJ enrichment pipeline

| Source | Data | Access |
|--------|------|--------|
| **Spotify Web API** | Artist photo, genres, popularity | Free, OAuth client credentials |
| **MusicBrainz API** | Artist metadata, disambiguation, cross-links | Free, no auth |
| **DJ Mag Top 100** | Annual rank | Manual one-time import per year; list is published on DJ Mag website |
| **SoundCloud API** | Follower count, track embeds | Deprecated for new apps; use `oembed` only |

### Dependencies

| Dependency | Type | Status | Owner |
|------------|------|--------|-------|
| Ticketmaster Developer account | External | To be registered | Mohamed |
| Eventbrite Developer account | External | To be registered | Mohamed |
| SeatGeek Developer account | External | To be registered | Mohamed |
| Ibiza venue scraping targets (≥ 8 clubs) | External | `robots.txt` + ToS review per target | Mohamed |
| Flagship Spain venue scraping targets (Razzmatazz, Fabrik, etc.) | External | `robots.txt` + ToS review per target | Mohamed |
| Partnership outreach — Xceed, DICE, Fever, RA | External | Parallel track, months 2-3 | Mohamed |
| Spotify Developer app | External | To be registered | Mohamed |
| Vercel project + Postgres | External | To be provisioned | Mohamed |
| Sentry project | External | To be provisioned | Mohamed |
| AdSense application (if pursued) | External | Post-launch (need traffic first) | Mohamed |

### Technical Constraints

- **Solo dev, 3+ months, Spain-only v1** — MVP must be ruthlessly scoped. Cut FR-11 (admin dashboard), FR-15 (save-for-later), FR-16 (map), FR-17 (RSS) to "Should" / "Could" and defer if timeline slips.
- **No paid APIs in v1** — every data source must be free-tier to avoid runway burn.
- **Vercel free tier limits** — 100GB bandwidth, 100k serverless function invocations/day. ISR means most traffic is static, so this is fine until 100k+ monthly users.
- **Scraping is scrape-first, partnership-parallel** — direct venue sites are scraped politely (respects `robots.txt`, rate-limited, cached, identified user-agent). Aggregators (DICE, Fever, Xceed, RA) are not scraped — partnership-only. Full risk matrix in Data Sources section.
- **EDM genre taxonomy** is fuzzy — start with a flat genre list (techno / house / trance / DnB / hardstyle / psytrance / dubstep / garage / bass / minimal / progressive) and evolve post-launch.
- **English-only v1** — localisation (Spanish, then others) deferred to v1.1 / v2. Decision: prioritise international / tourist traffic and Ibiza's English-speaking market for v1; Spanish-native SEO is a v1.1 expansion target.

### Technical Decisions Requiring AgDRs

Per `.claude/rules/agdr-decisions.md`, the following need AgDRs written at Tech Design time. AgDRs live in the Ravely product repo (`mrshousha/ravely`) at `docs/agdr/`, because they bind to implementation decisions and should ship with the code.

1. ✅ [**AgDR-0001 — Scrape-first data-source strategy**](https://github.com/mrshousha/ravely/blob/main/docs/agdr/AgDR-0001-scrape-first-data-strategy.md) (accepted 2026-04-24) — trade-off vs. API-only / partnership-first; EU Database Directive mitigations; 24h takedown SLO; permanent no-scrape list.
2. ✅ [**AgDR-0002 — Data pipeline architecture**](https://github.com/mrshousha/ravely/blob/main/docs/agdr/AgDR-0002-data-pipeline-architecture.md) (accepted 2026-04-24) — GitHub Actions scheduled workflows → Vercel Postgres via a shared ingest package. Free-tier; 2-hour cadence.
3. ✅ [**AgDR-0003 — Scraper adapter interface**](https://github.com/mrshousha/ravely/blob/main/docs/agdr/AgDR-0003-scraper-adapter-interface.md) (accepted 2026-04-24) — single `EventSourceAdapter` + `runAdapter` runner. Runner owns every AgDR-0001 mitigation; adapters are plain objects with `listUrls` + `parse`; blocklist enforced mechanically.
4. ⏳ **AgDR-0004 — Event dedup algorithm** (pending) — exact match vs. fuzzy venue + time tolerance.
5. ⏳ **AgDR-0005 — DJ slug generation** (pending) — handling name collisions, special characters, multiple aliases.
6. ⏳ **AgDR-0006 — Rendering strategy per page type** (pending) — SSG vs. SSR vs. ISR trade-offs across event / DJ / venue / city / genre routes.
7. ⏳ **AgDR-0007 — Ad integration decision** (deferred until post-launch traffic) — AdSense vs. Ezoic vs. direct; gated on reaching ~1k visitors/month.

---

## Launch Plan

### Rollout Strategy

- [x] **Soft launch, silent** — deploy to `ravely.com` (or `.app` / `.io` — domain TBD), wait for Google to index, no marketing push for first 4 weeks
- [ ] **SEO runway** — 4-6 weeks of passive indexing and organic discovery, monitor Search Console
- [ ] **Public launch** — HN / Product Hunt / Reddit (r/electronicmusic, r/techno, r/aves) after Core Web Vitals + coverage targets confirmed
- [ ] **Phased country expansion** — add Portugal + Germany as first expansion targets 3 months post-launch if Spain metrics are green; Italy + Netherlands after that

**Not** a beta program, **not** an invite flow — the site's value is discovery via Google, which requires a public, crawlable surface from day one.

### Pre-launch checklist

- [ ] `robots.txt` + `sitemap.xml` served correctly
- [ ] All event / DJ / venue pages return 200 for valid slugs, 404 for invalid
- [ ] Canonical URLs set on every page
- [ ] Google Search Console verified, sitemap submitted
- [ ] Lighthouse CI passing ≥ 95 SEO, ≥ 90 Performance on representative URLs
- [ ] Structured data validated via Google Rich Results Test (automated in CI)
- [ ] Privacy policy + Terms + Cookie banner (if ads live) published
- [ ] Sentry capturing errors
- [ ] GA4 or Vercel Analytics firing
- [ ] `/launch-check` audit run + all Critical + High issues resolved

---

## Open Questions

| Question | Owner | Status | Resolution |
|----------|-------|--------|------------|
| What domain do we use? (`ravely.com`, `.app`, `.io`, `.fm`, etc.) | Mohamed | Open | Check availability before tech design |
| Do we pursue AdSense from day 1 or wait for traffic? | Mohamed (as PM) | Open | AdSense requires ≥ 1k visitors/month typically — defer to post-launch |
| Partner negotiations with RA / DICE: attempt from day 1 or post-launch? | Mohamed | Open | Post-launch — partnership asks are easier with evidence of traffic |
| Cookie consent: full Klaro-style banner or go cookie-free? | Mohamed | Open | Cookie-free by default; revisit if AdSense goes live |
| Do we accept user-submitted events in v1 or v2? | Mohamed | Closed — v2 | Moderation cost too high for solo dev |
| What's the brand tone? Clubby, editorial, minimal? | Mohamed (with designer) | Open | Resolve at Design phase |
| How do we handle DJs with the same name (e.g. "David Morales" × 2)? | Tech Lead | Open | Disambiguation slug via Spotify / MusicBrainz ID |
| Language support — English only, Spanish only, or bilingual v1? | Mohamed | Closed — English only | V1 targets international / tourist traffic (especially Ibiza); Spanish localisation is v1.1 expansion. |
| Which Ibiza + BCN + Madrid venues are first for scrape-adapter development? | Mohamed (with Tech Lead) | Open | Prioritise by (expected event volume) × (robots.txt permissive) × (layout stability). Resolve at Tech Design. |
| Partnership outreach order (Xceed, DICE, Fever, RA) | Mohamed | Open | Start with Xceed (most aligned, Barcelona-based); others sequenced by traffic evidence. |
| Legal review for API ToS + data redistribution | External | Open | Should happen before first data ingest |

---

## Timeline

Solo-dev estimates, 3-month horizon. All dates 2026.

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| PRD approved | 2026-04-30 | Draft (this doc) |
| Tech Design + AgDRs complete | 2026-05-14 | Pending |
| Design (wireframes + component library) | 2026-05-21 | Pending |
| Data ingest pipeline live (Ticketmaster + Eventbrite APIs + first 5 venue scrapers) | 2026-06-04 | Pending |
| Core pages (event / DJ / venue / city) rendering from DB | 2026-06-25 | Pending |
| SEO polish (schema.org, sitemap, canonical, meta) | 2026-07-02 | Pending |
| Additional venue scrapers + DJ enrichment (Spotify + DJ Mag import) + partnership outreach started | 2026-07-16 | Pending |
| Pre-launch audit (`/launch-check`) + fixes | 2026-07-23 | Pending |
| Soft launch | 2026-07-30 | Pending |
| SEO runway + metric watch | 2026-07-30 → 2026-09-10 | Pending |
| Public launch | 2026-09-10 | Pending |

---

## Approvals

| Role | Name | Date | Status |
|------|------|------|--------|
| Product Manager | Mohamed Shousha | 2026-04-23 | Author |
| Head of Product | Mohamed Shousha | | Pending |
| Tech Lead | Mohamed Shousha | | Pending |
| Head of Design | Mohamed Shousha | | Pending |

---

## Appendix: Competitive landscape

| Competitor | Strength | Weakness | Ravely's answer |
|------------|----------|----------|-----------------|
| Resident Advisor | Curation, underground depth, editorial | No aggregation across platforms; no rich DJ profiles; no price transparency | Aggregate their events + others in one place; link to RA profile |
| DICE | Clean UX, curated picks | App-first (weak SEO); invitation-model feel | Broader coverage; web-first; SEO-discoverable |
| Ticketmaster | Scale, large-event coverage | Poor UX for underground; genre discovery is weak | Focus on EDM, genre-first discovery, aggregate their listings |
| **Xceed** | **Barcelona-based, Spain-focused EDM app; strong club partnerships** | **App-first; limited non-app discovery; narrow outside major cities** | **Web-first, SEO-discoverable, broader venue coverage; potential partner rather than competitor** |
| **Fever** | Broad event discovery in Spain, strong brand | Not EDM-specific; editorialised, not aggregated; no DJ depth | EDM-specialist focus; rich DJ profiles |
| Songkick | Historical artist-tracking strength | No longer actively developed; quality declined | Freshness + real ticket links |
| Bandsintown | Artist-first tour dates | Weak EDM taste; rock/pop focus | EDM-first; DJ Mag rank + RA link integrations |

**Ravely's position (v1, Spain)**: the aggregation + enrichment layer for EDM in Spain. Not trying to out-curate RA or out-scale Ticketmaster or out-app Xceed. The value is **"every EDM event in Spain, every ticket source, every DJ profile, one web-first place, searchable, SEO-discoverable."** App-first competitors cede the SEO surface — that's the opening.
