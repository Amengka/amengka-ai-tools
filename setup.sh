#!/usr/bin/env bash
#
# PageGun project setup script for "Amengka's Curated AI Tools"
#
# Usage:
#   export PAGEGUN_API_KEY="your-api-key"
#   bash setup.sh
#
# What this does:
#   1. Create a PageGun project
#   2. Configure the project context (description, audience, writing style, etc.)
#   3. Create a default author
#   4. Extract header & footer from the live site
#
# Prereqs:
#   - curl, jq installed
#   - PAGEGUN_API_KEY environment variable set
#   - For step 4: amengka.com must be live and reachable
#
# Every API call is checked: a non-2xx response aborts the script with the
# failing body printed, so re-runs are debuggable.

set -euo pipefail

API_BASE="https://www.pagegun.com/api"

# --- Preflight ---

command -v jq >/dev/null || { echo "Error: jq required (sudo apt install jq / brew install jq)"; exit 1; }
[[ -n "${PAGEGUN_API_KEY:-}" ]] || { echo "Error: PAGEGUN_API_KEY not set. Run: export PAGEGUN_API_KEY=\"your-api-key\""; exit 1; }

auth_header="Authorization: Bearer $PAGEGUN_API_KEY"

# http_call METHOD URL [JSON_BODY] — prints body on success, fails loud on HTTP >= 400.
http_call() {
  local method=$1 url=$2 data=${3:-}
  local tmp status
  tmp=$(mktemp)
  if [[ -n "$data" ]]; then
    status=$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
      -H "$auth_header" -H "Content-Type: application/json" -d "$data")
  else
    status=$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "$url" \
      -H "$auth_header" -H "Content-Type: application/json")
  fi
  if [[ "$status" -ge 400 ]]; then
    echo "  [FAIL] $method $url -> HTTP $status" >&2
    jq . < "$tmp" >&2 2>/dev/null || cat "$tmp" >&2
    rm -f "$tmp"
    return 1
  fi
  cat "$tmp"
  rm -f "$tmp"
}

echo "=== Amengka's Curated AI Tools — PageGun Setup ==="
echo ""

# --- Step 1: create project ---

echo "[1/4] Creating project..."
project_response=$(http_call POST "$API_BASE/projects" '{"name": "Amengkas Curated AI Tools"}')
PROJECT_ID=$(echo "$project_response" | jq -r '.id // .data.id // empty')
if [[ -z "$PROJECT_ID" ]]; then
  echo "  [FAIL] could not extract project id from response:" >&2
  echo "$project_response" | jq . >&2
  exit 1
fi
echo "  OK   project id: $PROJECT_ID"

# --- Step 2: configure context ---

echo "[2/4] Configuring project context..."
http_call PUT "$API_BASE/projects/$PROJECT_ID" '{
  "context": {
    "name": "Amengkas Curated AI Tools",
    "description": "Handpicked AI tool recommendations and in-depth reviews to help you find the perfect AI assistant",
    "businessDescription": "Amengkas Curated AI Tools is an independent AI tool review and recommendation platform. We personally test every tool we recommend, evaluating them from real-world use cases. Covering AI writing, coding, design, data analysis, productivity, and more — helping users cut through the noise to find tools that actually work. No sponsored content, no ads — just honest recommendations.",
    "targetAudience": "Developers, designers, content creators, product managers, freelancers, and professionals looking to boost productivity with AI tools",
    "topFeatures": [
      "In-depth reviews — every tool is personally tested with real-world usage reports",
      "Head-to-head comparisons — features, pricing, pros and cons at a glance",
      "Practical guides — from beginner to advanced tutorials and best practices",
      "Timely updates — keeping up with the latest AI tool releases and updates"
    ],
    "competitors": ["There is an AI for that", "Toolify.ai", "ProductHunt", "Ben Tossell (Bens Bites)", "Matt Shumer"],
    "writingStyle": "Professional yet approachable. Explain technical concepts in plain language with real examples and screenshots. The tone should feel like a knowledgeable friend sharing their experience — not a dry product spec sheet. Use analogies and comparisons to make complex ideas accessible.",
    "specialInstructions": "Content in English. Keep AI tool names in their original form (ChatGPT, Cursor, etc.). When mentioning pricing, include USD amounts. Prioritize tools that offer free tiers or free trials. End articles with a clear recommendation or verdict. Include practical tips readers can act on immediately.",
    "categories": ["AI Writing Tools", "AI Coding Tools", "AI Design & Image", "AI Productivity Tools", "AI Data & Analytics", "AI Audio & Video", "AI Learning & Education", "Industry Trends"]
  }
}' > /dev/null
echo "  OK   context configured"

# --- Step 3: create author ---

echo "[3/4] Creating default author..."
author_payload=$(jq -n \
  --arg pid "$PROJECT_ID" \
  --arg name "Amengka" \
  --arg bio "AI tools enthusiast and independent developer. I love trying out new tools and evaluating AI products from a practical, hands-on perspective. Sharing honest experiences to help you find the best AI assistants." \
  '{project_id:$pid, name:$name, bio:$bio, is_default:true}')
author_response=$(http_call POST "$API_BASE/ext/authors" "$author_payload")
AUTHOR_ID=$(echo "$author_response" | jq -r '.id // .data.id // empty')
if [[ -n "$AUTHOR_ID" ]]; then
  echo "  OK   author id: $AUTHOR_ID"
else
  echo "  WARN no author id in response:" >&2
  echo "$author_response" | jq . >&2
fi

# --- Step 4: extract header & footer ---

echo "[4/4] Extracting header & footer from live site..."
echo "  (Requires amengka.com to be live and pointing at Vercel)"
http_call POST "$API_BASE/projects/$PROJECT_ID/header-auto-match?extract=true&save=true" > /dev/null
echo "  OK   header extracted"
http_call POST "$API_BASE/projects/$PROJECT_ID/footer-auto-match?extract=true&save=true" > /dev/null
echo "  OK   footer extracted"

# --- Done ---

echo ""
echo "=== Setup Complete ==="
echo "  PROJECT_ID: $PROJECT_ID"
echo "  AUTHOR_ID:  ${AUTHOR_ID:-unknown}"
echo ""
echo "Next steps:"
echo "  1. Update vercel.json — replace YOUR_PROJECT_ID with: $PROJECT_ID"
echo "  2. Deploy to Vercel (see README.md)"
echo "  3. Generate your first article:"
echo ""
echo "     curl -s -X POST \"$API_BASE/articles/generate-markdown\" \\"
echo "       -H \"Authorization: Bearer \$PAGEGUN_API_KEY\" \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"keyword\": \"Cursor vs GitHub Copilot vs Claude Code 2026\", \"project_id\": \"$PROJECT_ID\", \"content_type\": \"review-analysis\"}'"
echo ""
echo "  (Or batch-generate 4 more: bash generate-articles.sh)"
