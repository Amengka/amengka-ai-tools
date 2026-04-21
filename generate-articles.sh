#!/usr/bin/env bash
#
# Batch-generate + publish articles for the Amengkas Curated AI Tools project.
#
# Usage:
#   export PAGEGUN_API_KEY="your-api-key"
#   export PROJECT_ID="PMpWZt3L"        # optional, defaults to PMpWZt3L
#   bash generate-articles.sh
#
# For each keyword below the script:
#   1. Submits a markdown-generation job
#   2. Polls /api/articles/generate/:job_id until status=completed
#   3. Sets the page subroute to "articles" and publishes it
#   4. Prints the slug + a ready-to-paste <a class="article-card"> block
#
# If one article fails, the script logs the error and continues with the next.

set -euo pipefail

API_BASE="https://www.pagegun.com/api"
PROJECT_ID="${PROJECT_ID:-PMpWZt3L}"
POLL_INTERVAL="${POLL_INTERVAL:-10}"
POLL_MAX_TRIES="${POLL_MAX_TRIES:-60}"   # 60 * 10s = 10 min

command -v jq >/dev/null || { echo "Error: jq required (sudo apt install jq / brew install jq)"; exit 1; }
[[ -n "${PAGEGUN_API_KEY:-}" ]] || { echo "Error: PAGEGUN_API_KEY not set"; exit 1; }

auth_header="Authorization: Bearer $PAGEGUN_API_KEY"

# keyword|content_type|category
articles=(
  "10 free AI tools worth trying in 2026|listicle-roundup|productivity"
  "How to run Stable Diffusion locally — complete setup guide|guide-how-to|design"
  "How small teams use AI tools to cut costs — real examples|case-study|productivity"
  "Will AI coding tools replace developers|opinion-perspective|coding"
)

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
    echo "   [FAIL] $method $url -> HTTP $status" >&2
    jq . < "$tmp" >&2 2>/dev/null || cat "$tmp" >&2
    rm -f "$tmp"
    return 1
  fi
  cat "$tmp"
  rm -f "$tmp"
}

generate_one() {
  local keyword=$1 content_type=$2 category=$3

  echo "→ \"$keyword\" ($content_type, category=$category)"

  local payload job_response job_id
  payload=$(jq -n \
    --arg k "$keyword" \
    --arg pid "$PROJECT_ID" \
    --arg ct "$content_type" \
    '{keyword:$k, project_id:$pid, content_type:$ct}')

  job_response=$(http_call POST "$API_BASE/articles/generate-markdown" "$payload") || return 1
  job_id=$(echo "$job_response" | jq -r '.job_id // empty')
  if [[ -z "$job_id" ]]; then
    echo "   [FAIL] no job_id in response"
    echo "$job_response" | jq .
    return 1
  fi
  echo "   job_id: $job_id — polling every ${POLL_INTERVAL}s..."

  local tries=0 poll status page_id
  while (( tries < POLL_MAX_TRIES )); do
    poll=$(http_call GET "$API_BASE/articles/generate/$job_id") || return 1
    status=$(echo "$poll" | jq -r '.status // empty')
    case "$status" in
      completed) page_id=$(echo "$poll" | jq -r '.result_page_id // empty'); break ;;
      failed|error)
        echo "   [FAIL] job failed:"
        echo "$poll" | jq .
        return 1
        ;;
    esac
    sleep "$POLL_INTERVAL"
    tries=$((tries + 1))
  done

  if [[ "$status" != "completed" ]]; then
    echo "   [FAIL] timed out after $((POLL_MAX_TRIES * POLL_INTERVAL))s (last status: $status)"
    return 1
  fi
  if [[ -z "$page_id" ]]; then
    echo "   [FAIL] no result_page_id in completed job"
    return 1
  fi

  # Set subroute + publish
  http_call PUT "$API_BASE/pages/$page_id" '{"subroute": "articles"}' > /dev/null
  http_call POST "$API_BASE/pages/publish" "{\"pageId\": \"$page_id\"}" > /dev/null

  local page_info slug title
  page_info=$(http_call GET "$API_BASE/pages/$page_id") || return 1
  slug=$(echo "$page_info" | jq -r '.slug // empty')
  title=$(echo "$page_info" | jq -r '.title // .page_name // empty')

  echo "   OK  /articles/$slug"
  echo ""
  echo "   Paste into index.html .articles grid:"
  echo "   <a class=\"article-card\" href=\"/articles/$slug\" data-category=\"$category\">"
  echo "     <span class=\"tag\">$(tag_for_type "$content_type")</span>"
  echo "     <h3>${title:-$keyword}</h3>"
  echo "     <p>TODO: short description</p>"
  echo "   </a>"
  echo ""
}

tag_for_type() {
  case "$1" in
    review-analysis) echo "Review" ;;
    guide-how-to) echo "Guide" ;;
    listicle-roundup) echo "Roundup" ;;
    case-study) echo "Case study" ;;
    opinion-perspective) echo "Opinion" ;;
    news-announcement) echo "News" ;;
    trend-analysis) echo "Trend" ;;
    interview-qa) echo "Interview" ;;
    *) echo "Article" ;;
  esac
}

echo "=== Batch-generating ${#articles[@]} articles (project=$PROJECT_ID) ==="
echo ""

ok=0; fail=0
for entry in "${articles[@]}"; do
  IFS='|' read -r keyword content_type category <<< "$entry"
  if generate_one "$keyword" "$content_type" "$category"; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
    echo "   (continuing with next article)"
    echo ""
  fi
done

echo "=== Done — $ok succeeded, $fail failed ==="
echo ""
echo "Next: paste the printed <a> blocks into index.html and also add each slug to sitemap.xml."
