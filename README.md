# Amengka's Curated AI Tools

Handpicked AI tool recommendations and in-depth reviews. Powered by [PageGun](https://www.pagegun.com) for AI-generated content and SEO.

**Live site:** [amengka.com](https://amengka.com)

---

## How It Works

- A static landing page is hosted on **Vercel**
- **PageGun** generates and hosts article content (reviews, guides, comparisons)
- Vercel **rewrites** `/articles/*` requests to PageGun, so articles appear on `amengka.com/articles/...`
- Your site stays fast and simple; PageGun handles the content engine

---

## Setup

### 1. Prerequisites

- A [PageGun](https://www.pagegun.com) account and API key
- A [Vercel](https://vercel.com) account (free tier works)
- A [GitHub](https://github.com) account
- The `amengka.com` domain (or your own domain)
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

Vercel hosts your landing page and handles the reverse proxy to PageGun.

#### First-time Vercel setup

1. **Create a Vercel account** at [vercel.com](https://vercel.com) — sign up with your GitHub account (easiest).

2. **Import your repo:**
   - Go to [vercel.com/new](https://vercel.com/new)
   - Click **"Import Git Repository"**
   - Select the `amengka-ai-tools` repo from the list
   - Framework Preset: select **"Other"** (this is a plain HTML site)
   - Click **"Deploy"**
   - Vercel will deploy your site and give you a URL like `amengka-ai-tools.vercel.app`

3. **Verify the deploy** — visit the `.vercel.app` URL and confirm you see the landing page.

#### Connect your custom domain

1. In the Vercel dashboard, go to your project → **Settings** → **Domains**
2. Type `amengka.com` and click **Add**
3. Vercel will show you DNS records to add. Go to your domain registrar and add them:

   | Type | Name | Value |
   |------|------|-------|
   | A | `@` | `76.76.21.21` |
   | CNAME | `www` | `cname.vercel-dns.com` |

4. Wait for DNS propagation (usually 5–15 minutes, can take up to 48 hours)
5. Vercel will automatically provision an SSL certificate
6. Visit `https://amengka.com` to confirm it works

### 4. Run the PageGun setup script

This creates your PageGun project, configures the AI context, and creates an author.

```bash
export PAGEGUN_API_KEY="your-api-key-here"
bash setup.sh
```

The script will print your `PROJECT_ID` at the end.

### 5. Update vercel.json

Replace `YOUR_PROJECT_ID` in `vercel.json` with the actual project ID from the previous step:

```json
{
  "rewrites": [
    {
      "source": "/articles/:path*",
      "destination": "https://www.pagegun.com/p/abc12345/articles/:path*"
    }
  ]
}
```

Commit and push — Vercel will redeploy automatically.

```bash
git add vercel.json
git commit -m "Configure PageGun rewrite with project ID"
git push
```

### 6. Generate your first article

```bash
# Generate
curl -s -X POST "https://www.pagegun.com/api/articles/generate-markdown" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "keyword": "Cursor vs GitHub Copilot vs Claude Code 2026",
    "project_id": "YOUR_PROJECT_ID",
    "content_type": "review-analysis"
  }'

# Save the job_id from the response, then poll until completed:
curl -s "https://www.pagegun.com/api/articles/generate/JOB_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"
```

### 7. Publish the article

```bash
# Set the subroute
curl -s -X PUT "https://www.pagegun.com/api/pages/PAGE_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"subroute": "articles"}'

# Publish
curl -s -X POST "https://www.pagegun.com/api/pages/publish" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"pageId": "PAGE_ID"}'
```

Visit `https://amengka.com/articles/your-article-slug` to see it live.

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
├── index.html      # Landing page
├── vercel.json     # Vercel rewrites (reverse proxy to PageGun)
├── setup.sh        # One-time PageGun project setup script
├── .gitignore
└── README.md
```

---

## Useful Commands

```bash
# List all pages
curl -s "https://www.pagegun.com/api/pages?project_id=YOUR_PROJECT_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"

# List all authors
curl -s "https://www.pagegun.com/api/ext/authors?project_id=YOUR_PROJECT_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"

# Check generation job status
curl -s "https://www.pagegun.com/api/articles/generate/JOB_ID" \
  -H "Authorization: Bearer $PAGEGUN_API_KEY"
```
