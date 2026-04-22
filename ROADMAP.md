# Roadmap

Things to do on `amengka-ai-tools` after the current baseline (landing page live at amengka.com, one published article, Vercel rewrite in place for `/articles/*`).

## Done — 2026-04-21 (PR #2)

Shipped on `master` via [PR #2](https://github.com/Amengka/amengka-ai-tools/pull/2), merge commit `9bf0d10`.

- **#2 Category filtering** — quick path shipped: `data-category` on emoji cards + article cards, click-to-filter JS, active-state highlight on the selected card
- **#6 SEO basics** — `sitemap.xml` and `robots.txt` added
- **#7 Analytics** — Plausible snippet embedded in `index.html` (requires adding `amengka.com` to the Plausible dashboard to start collecting)
- **#10 `setup.sh` hardening** — new `http_call` helper; every request checks HTTP status and fails loud with the response body. No more `2>/dev/null || true`.
- **#11 README refresh** — top-level "What's deployed right now", batch/one-off generation flows documented, verification checklist added, first-time setup moved to an appendix

Scripted but not yet executed (needs `PAGEGUN_API_KEY`):

- **#1 / #8 Generate more articles + diversify content types** — `generate-articles.sh` batches 4 keywords covering `listicle-roundup`, `guide-how-to`, `case-study`, `opinion-perspective`. It polls each job, publishes, and prints paste-ready `<a class="article-card">` snippets. Run it, paste into `index.html`, and add slugs to `sitemap.xml`.

Verification still to run:

- **#9 OG / social previews** — checklist is in README; actual scraper run (opengraph.xyz / Twitter card validator / mobile preview) pending until new articles land.

---

## Near-term — works today, just needs doing

### 1. Generate more articles
> 🟡 **Scripted (2026-04-21, PR #2):** `generate-articles.sh` handles the batch end-to-end. Execution still pending (needs API key).

The "Latest Articles" section is one card. Aim for 5–10 to make the demo feel populated.

- Run the generation API with keywords from `README.md` (8 sample keywords already listed there)
- After each publish, add a matching `<a class="article-card">` block in `index.html`
- Commit + push; Vercel auto-deploys

Manual card-per-article doesn't scale past ~10, but for a demo it's fine.

> **PageGun update (2026-04-20):** PR #829 (`fix: sanitize generator drift in article markdown`) is now on `main`. New articles should come out cleaner; if earlier articles show drift artifacts (stray CTAs, broken section markers), regenerate them.

### 2. Category filtering
> ✅ **Done (2026-04-21, PR #2):** Quick path — plain-JS filter with `data-category` attributes — is live on master. Native PageGun-category path (below) is still open if the catalog outgrows manual cards.

The four emoji cards (`AI Writing Tools`, `AI Coding Tools`, …) are visual only. Make them filter the "Latest Articles" grid.

- Add `data-category` attributes on each article card
- On category click, hide cards whose category doesn't match
- Plain JS, no build step

Or skip this until the catalog is bigger.

> **PageGun update (2026-04-20):** PR #811 (`feat: subroute-scoped categories on rewrite mode`) shipped. PageGun now has native categories scoped to the `articles` subroute, so categories can live on the article records themselves instead of hard-coded `data-category` attributes. Options:
> - **Quick path (still valid):** plain-JS filter as described above — fine for a handful of cards.
> - **Native path:** assign a PageGun category per article at generation time, then fetch `GET /api/pages?project_id=...&subroute=articles&category=<slug>` to render filtered lists. Scales past ~10 articles and survives regeneration.

### 3. Extract real header/footer on PageGun-hosted pages
Currently PageGun-rendered articles (`/articles/<slug>`) show with a generic layout, not `amengka.com`'s header/footer. Fix requires:

- **Wait for PageGun PR #824 to merge** (`fix/auto-match-support-rewrite-mode`)
- Then run:
  ```bash
  curl -X PUT "https://www.pagegun.com/api/projects/PMpWZt3L" \
    -H "Authorization: Bearer $PAGEGUN_API_KEY" -H "Content-Type: application/json" \
    -d '{"root_url":"https://www.amengka.com"}'

  curl -X POST "https://www.pagegun.com/api/projects/PMpWZt3L/header-auto-match?extract=true&save=true" \
    -H "Authorization: Bearer $PAGEGUN_API_KEY"

  curl -X POST "https://www.pagegun.com/api/projects/PMpWZt3L/footer-auto-match?extract=true&save=true" \
    -H "Authorization: Bearer $PAGEGUN_API_KEY"
  ```
- Visit an article page; confirm nav matches the homepage

## Blocked on PageGun

### 4. Expose a browsable `/articles` index
Currently `amengka.com/articles` returns 404 because PageGun's listing page emits a trailing-slash 308 with a relative `Location` that escapes through the Vercel rewrite.

Two ways out, both require PageGun-side work or a workaround:
- **Wait for PageGun to fix the 308** — would light up `/articles` natively through the proxy with no extra work on this side
- **Build our own listing** — fetch `GET /api/pages?project_id=PMpWZt3L&subroute=articles` at build time (Vercel build hook or GitHub Action), render a static `articles/index.html`

If more than ~10 articles accumulate before PageGun ships the fix, do the build-time listing.

### 5. http-only root_url support (not currently needed)
If ever needed for dev/intranet origins, PageGun would need the canonical-helper refactor. Not a demo blocker.

## New on PageGun — worth adopting

### A. Use the Agents system instead of manual generation calls
PageGun PR #827 (`feat: agents system with Vertex Gemini + trigger.dev`) shipped a full agents surface: dispatch, runs, timeline, revert. Once the demo has a steady cadence, the per-article manual generation loop in item #1 can move to a dispatched agent.

- Define an agent template that generates an article from a keyword + content type
- Dispatch it from the PageGun dashboard or via `POST /api/projects/:id/agents/:agentId/dispatch`
- Runs are visible under `projects/:id/agents/:agentId`, with revert available per run

Only worth doing once manual generation starts feeling tedious — matches the trigger in item #12.

## Nice-to-have

### 6. SEO basics
> ✅ **Done (2026-04-21, PR #2):** `sitemap.xml` (homepage + current article) and `robots.txt` committed, served as static files by Vercel. New article slugs need to be appended to `sitemap.xml` manually (or automated when item #12 is taken on).

- Generate a `sitemap.xml` that includes both the homepage and article slugs
- Add a `robots.txt` pointing at the sitemap
- Vercel can serve both as static files

### 7. Analytics
> ✅ **Done (2026-04-21, PR #2):** Plausible `<script>` embedded in `index.html` head. **Still pending:** add `amengka.com` as a site in the Plausible dashboard — the snippet 404s silently until then.
>
> PageGun-hosted article pages still need their own snippet configured via the PageGun dashboard.

- Drop in Plausible or Google Analytics on `index.html`
- PageGun-hosted article pages need the snippet too (via its settings, not via our static site)

### 8. Diversify content types
> 🟡 **Scripted (2026-04-21, PR #2):** `generate-articles.sh` covers `listicle-roundup`, `guide-how-to`, `case-study`, `opinion-perspective` in one run. Execution pending.

PageGun supports 8 content types — right now we only have `review-analysis`. Generate one of each to demo breadth:
- `guide-how-to` — "How to run Stable Diffusion locally"
- `listicle-roundup` — "10 free AI tools worth trying in 2026"
- `case-study` — "How small teams use AI tools to cut costs"

Each goes into the same `articles` subroute unless we want sub-subroutes.

### 9. Open Graph / social previews
> 🟡 **Checklist added (2026-04-21, PR #2):** README "Verifying a Published Article" section lists the scraper checks. Actual verification run pending until more articles land.

Current `index.html` has basic `og:` meta, but no per-article previews control (PageGun generates those). Verify by pasting an article URL into a social media scraper.

## Housekeeping

### 10. Clean up `setup.sh`
> ✅ **Done (2026-04-21, PR #2):** `http_call` helper; every curl checks HTTP status and fails loud with the response body.

Current script wraps PageGun calls in `2>/dev/null || true` and prints `"done"` regardless. This masked the header/footer extraction failure during initial setup. Fix:

- Remove the error-swallowing redirects
- Check HTTP status on each call and fail loud
- Print which step ran and the result

Not blocking anything, but makes future re-runs debuggable.

### 11. Update `README.md`
> ✅ **Done (2026-04-21, PR #2):** Top-level "What's deployed right now", batch/one-off generation flows, post-publish verification checklist; first-time Vercel setup moved to an appendix. The `pagegun` skill split referenced below was not touched — the README talks about API calls directly, not the skill — leaving it for when we adopt the agent/skill path.

- Drop the "first-time Vercel setup" section if this is checked in as a reference project (setup is done)
- Add a "What's deployed right now" section pointing at current article inventory
- PageGun split the unified `pagegun` skill into `pagegun` / `pagegun-articles` / `pagegun-docs` (PR #825). Anywhere the README or `setup.sh` references the old unified skill for article workflows, point at `pagegun-articles` instead.

### 12. Consider a build step
If the manual card-per-article workflow gets tedious, swap `index.html` for a minimal SSG that fetches PageGun articles at build time. Options:
- Astro (closest to current "plain HTML" feel)
- Next.js static export
- A tiny Node script + template literals, committed output

Only worth doing if this project grows past a one-off demo.

## Deferred (won't do unless asked)

- Switching to PageGun Full-Host mode — would remove Vercel entirely; separate configuration effort, not better for the current demo shape
- Custom domain subroutes beyond `articles` (e.g. `/guides`, `/comparisons`) — kept out until the base `articles` subroute has enough content to be worth demoing
