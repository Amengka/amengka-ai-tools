#!/usr/bin/env bash
#
# PageGun project setup script for "Amengka's Curated AI Tools"
#
# Usage:
#   export PAGEGUN_API_KEY="your-api-key"
#   bash setup.sh
#
# This script will:
#   1. Create a PageGun project
#   2. Configure the project context (description, audience, writing style, etc.)
#   3. Create a default author
#   4. Extract header & footer from your live site
#
# Prerequisites:
#   - curl and jq installed
#   - PAGEGUN_API_KEY environment variable set
#   - Your site must be live on amengka.com (for header/footer extraction)

set -euo pipefail

API_BASE="https://www.pagegun.com/api"

# --- Preflight checks ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: sudo apt install jq (Linux) or brew install jq (Mac)"
  exit 1
fi

if [[ -z "${PAGEGUN_API_KEY:-}" ]]; then
  echo "Error: PAGEGUN_API_KEY is not set."
  echo "Run: export PAGEGUN_API_KEY=\"your-api-key\""
  exit 1
fi

auth_header="Authorization: Bearer $PAGEGUN_API_KEY"

echo "=== Amengka's Curated AI Tools — PageGun Setup ==="
echo ""

# --- Step 1: Create project ---

echo "[1/4] Creating project..."
project_response=$(curl -s -X POST "$API_BASE/projects" \
  -H "$auth_header" \
  -H "Content-Type: application/json" \
  -d '{"name": "Amengkas Curated AI Tools"}')

PROJECT_ID=$(echo "$project_response" | jq -r '.id // .data.id // empty')

if [[ -z "$PROJECT_ID" ]]; then
  echo "Error creating project. Response:"
  echo "$project_response" | jq .
  exit 1
fi

echo "  Project created: $PROJECT_ID"

# --- Step 2: Configure project context ---

echo "[2/4] Configuring project context..."
context_response=$(curl -s -X PUT "$API_BASE/projects/$PROJECT_ID" \
  -H "$auth_header" \
  -H "Content-Type: application/json" \
  -d '{
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
      "competitors": ["There is an AI for that", "Toolify.ai", "ProductHunt", "Ben Tossell (Ben's Bites)", "Matt Shumer"],
      "writingStyle": "Professional yet approachable. Explain technical concepts in plain language with real examples and screenshots. The tone should feel like a knowledgeable friend sharing their experience — not a dry product spec sheet. Use analogies and comparisons to make complex ideas accessible.",
      "specialInstructions": "Content in English. Keep AI tool names in their original form (ChatGPT, Cursor, etc.). When mentioning pricing, include USD amounts. Prioritize tools that offer free tiers or free trials. End articles with a clear recommendation or verdict. Include practical tips readers can act on immediately.",
      "categories": ["AI Writing Tools", "AI Coding Tools", "AI Design & Image", "AI Productivity Tools", "AI Data & Analytics", "AI Audio & Video", "AI Learning & Education", "Industry Trends"]
    }
  }')

echo "  Context configured."

# --- Step 3: Create author ---

echo "[3/4] Creating default author..."
author_response=$(curl -s -X POST "$API_BASE/ext/authors" \
  -H "$auth_header" \
  -H "Content-Type: application/json" \
  -d "{
    \"project_id\": \"$PROJECT_ID\",
    \"name\": \"Amengka\",
    \"bio\": \"AI tools enthusiast and independent developer. I love trying out new tools and evaluating AI products from a practical, hands-on perspective. Sharing honest experiences to help you find the best AI assistants.\",
    \"is_default\": true
  }")

AUTHOR_ID=$(echo "$author_response" | jq -r '.id // .data.id // empty')

if [[ -z "$AUTHOR_ID" ]]; then
  echo "  Warning: Could not extract author ID. Response:"
  echo "$author_response" | jq .
else
  echo "  Author created: $AUTHOR_ID"
fi

# --- Step 4: Extract header & footer ---

echo "[4/4] Extracting header & footer from live site..."
echo "  (This requires your site to be live on your domain)"

header_response=$(curl -s -X POST "$API_BASE/projects/$PROJECT_ID/header-auto-match?extract=true&save=true" \
  -H "$auth_header" \
  -H "Content-Type: application/json" 2>/dev/null) || true

footer_response=$(curl -s -X POST "$API_BASE/projects/$PROJECT_ID/footer-auto-match?extract=true&save=true" \
  -H "$auth_header" \
  -H "Content-Type: application/json" 2>/dev/null) || true

echo "  Header & footer extraction attempted."
echo "  (If your site isn't live yet, re-run this step later with: bash setup.sh --extract-only)"

# --- Done ---

echo ""
echo "=== Setup Complete ==="
echo ""
echo "  PROJECT_ID:  $PROJECT_ID"
echo "  AUTHOR_ID:   ${AUTHOR_ID:-unknown}"
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
