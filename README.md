# Amengka's Curated AI Tools

Handpicked AI tool recommendations and in-depth reviews. Powered by [PageGun](https://www.pagegun.com) for AI-generated content and SEO.

**Live site:** [amengka.com](https://amengka.com)

---

## What's Deployed Right Now

- **Landing page** — `index.html`, hosted on Vercel at amengka.com
- **PageGun project** — `PMpWZt3L` (rewrite mode)
- **Articles live (5):**
  - `/articles/cursor-vs-github-copilot-vs-claude-code-2026` — Review (coding)
  - `/articles/10-free-ai-tools-worth-trying-in-2026` — Roundup (productivity)
  - `/articles/how-to-run-stable-diffusion-locally-complete-setup-guide` — Guide (design)
  - `/articles/how-small-teams-use-ai-tools-to-cut-costs-real-examples` — Case study (productivity)
  - `/articles/will-ai-coding-tools-replace-developers` — Opinion (coding)

Run `bash generate-articles.sh` to add more (customize the `articles` array inside the script first).

---

## How It Works

- A static landing page is hosted on **Vercel**
- **PageGun** generates and hosts article content (reviews, guides, comparisons)
- Vercel **rewrites** `/articles/*` requests to PageGun, so articles appear on `amengka.com/articles/...`
- Your site stays fast and simple; PageGun handles the content engine

---

## Generating Articles

### Batch

`generate-articles.sh` queues 4 pre-picked keywords (listicle, guide-how-to, case-study, opinion-perspective), polls each job to completion, publishes, and prints the slug + a ready-to-paste `<a class="article-card">` block for `index.html`.

```bash
export PAGEGUN_API_KEY="your-api-key"
bash generate-articles.sh
```

Override the target project with `PROJECT_ID=xxxxxxxx` if you're not using `PMpWZt3L`. Poll cadence and timeout are tunable via `POLL_INTERVAL` and `POLL_MAX_TRIES`.

After it finishes, paste each printed `<a>` block into the `.articles` grid in `index.html` and add the slug to `sitemap.xml`. Commit and push — Vercel auto-deploys.

### One-off

```bash
# Generate
curl -s -X POST "https://www.pagegun.com/api/articles/generate-markdown" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "Cursor vs GitHub Copilot vs Claude Code 2026",
    "project_id": "PMpWZt3L",
    "content_type": "review-analysis"
  }'

# Poll the returned job_id until status == "completed", grab result_page_id, then:
curl -s -X PUT "https://www.pagegun.com/api/pages/PAGE_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"subroute": "articles"}'

curl -s -X POST "https://www.pagegun.com/api/pages/publish" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"pageId": "PAGE_ID"}'
```

---

## Verifying a Published Article

1. **Loads via the proxy:** `curl -I https://amengka.com/articles/<slug>` returns `200`
2. **OG/Twitter preview:** paste the URL into <https://www.opengraph.xyz> or the Twitter card validator — confirm title, description, and og:image render
3. **Mobile render:** open in DevTools responsive mode or a real device
4. **Nav matches homepage:** header/footer should use the site chrome (gated on PageGun PR #824 landing — until then, expect the default PageGun layout)

---

## Content Ideas

| Keyword | Content Type |
|---------|-------------|
| Cursor vs GitHub Copilot vs Claude Code 2026 | `review-analysis` |
| ChatGPT vs Claude — which is better for everyday use | `review-analysis` |
| Midjourney beginner guide — generate AI images from scratch | `guide-how-to` |
| 10 free AI tools worth trying in 2026 | `listicle-roundup` |
| Notion AI tips to 10x your note-taking productivity | `guide-how-to` |
| Will AI coding tools replace developers | `opinion-perspective` |
| Perplexity AI vs Google Search — AI search engine review | `review-analysis` |
| How to run Stable Diffusion locally — complete setup guide | `guide-how-to` |
| How small teams use AI tools to cut costs — real examples | `case-study` |

**Content types:** `guide-how-to`, `listicle-roundup`, `news-announcement`, `opinion-perspective`, `trend-analysis`, `review-analysis`, `case-study`, `interview-qa`

---

## Project Structure

```
amengka-ai-tools/
├── index.html              # Landing page (Plausible + category filter)
├── vercel.json             # Vercel rewrite → PageGun
├── sitemap.xml             # SEO: homepage + article URLs
├── robots.txt              # SEO: allow all, points at sitemap
├── setup.sh                # One-time PageGun project setup
├── generate-articles.sh    # Batch-generate + publish new articles
├── ROADMAP.md              # Near-term, blocked, and deferred work
├── .gitignore
└── README.md
```

---

## Useful Commands

```bash
# List all pages in the project
curl -s "https://www.pagegun.com/api/pages?project_id=PMpWZt3L" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"

# List all authors
curl -s "https://www.pagegun.com/api/ext/authors?project_id=PMpWZt3L" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"

# Check generation job status
curl -s "https://www.pagegun.com/api/articles/generate/JOB_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"
```

---

## Appendix: First-time Setup

Only needed if you're bootstrapping a fresh copy — the live site is already set up.

### 1. Prerequisites

- A [PageGun](https://www.pagegun.com) account and API key
- A [Vercel](https://vercel.com) account (free tier works)
- A [GitHub](https://github.com) account
- The `amengka.com` domain (or your own)
- `curl` and `jq` installed locally

### 2. Push this repo to GitHub

```bash
cd amengka-ai-tools
git init
git add .
git commit -m "Initial commit"
gh repo create amengka-ai-tools --public --source=. --push
```

### 3. Deploy to Vercel

1. Sign in at [vercel.com](https://vercel.com) with GitHub
2. At [vercel.com/new](https://vercel.com/new), import the `amengka-ai-tools` repo, framework preset **Other**, click **Deploy**
3. Verify the `.vercel.app` URL loads the landing page

### 4. Connect your custom domain

In the Vercel project → **Settings** → **Domains**, add `amengka.com`, then configure DNS at your registrar:

| Type | Name | Value |
|------|------|-------|
| A | `@` | `76.76.21.21` |
| CNAME | `www` | `cname.vercel-dns.com` |

Wait for propagation (5–15 min typical). Vercel auto-provisions SSL.

### 5. Create the PageGun project

```bash
export PAGEGUN_API_KEY="your-api-key"
bash setup.sh
```

`setup.sh` fails loud on any non-2xx API response — if step 4 (header/footer extraction) errors, the live site probably isn't reachable yet.

Copy the printed `PROJECT_ID`.

### 6. Wire up the Vercel rewrite

Replace the project id in `vercel.json`:

```json
{
  "rewrites": [
    {
      "source": "/articles/:path*",
      "destination": "https://www.pagegun.com/p/YOUR_PROJECT_ID/articles/:path*"
    }
  ]
}
```

Commit + push; Vercel redeploys automatically.

### 7. Generate your first article

See the "One-off" flow above, or run `bash generate-articles.sh` for a batch of four.
