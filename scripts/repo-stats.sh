#!/bin/bash
# repo-stats.sh -- Quick repository statistics
# Usage: bash repo-stats.sh <repo-path>

REPO="${1:-.}"

if [ ! -d "$REPO" ]; then
    echo "ERROR: Directory not found: $REPO"
    exit 1
fi

cd "$REPO" || exit 1

echo "=== Repository Statistics ==="
echo "REPO_PATH: $(pwd)"

# Git info
if [ -d .git ]; then
    echo ""
    echo "=== Git Statistics ==="

    FIRST_COMMIT=$(git log --reverse --format='%ci' 2>/dev/null | head -1)
    LATEST_COMMIT=$(git log -1 --format='%ci' 2>/dev/null)
    TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 'unknown')
    CONTRIBUTORS=$(git shortlog -sn --no-merges 2>/dev/null | wc -l | tr -d ' ')
    BRANCHES=$(git branch -r 2>/dev/null | wc -l | tr -d ' ')
    TAGS=$(git tag 2>/dev/null | wc -l | tr -d ' ')

    echo "FIRST_COMMIT: ${FIRST_COMMIT:-unknown}"
    echo "LATEST_COMMIT: ${LATEST_COMMIT:-unknown}"
    echo "TOTAL_COMMITS: $TOTAL_COMMITS"
    echo "CONTRIBUTORS: $CONTRIBUTORS"
    echo "BRANCHES: $BRANCHES"
    echo "TAGS: $TAGS"

    # Recent velocity
    COMMITS_30D=$(git log --since='30 days ago' --oneline 2>/dev/null | wc -l | tr -d ' ')
    COMMITS_90D=$(git log --since='90 days ago' --oneline 2>/dev/null | wc -l | tr -d ' ')
    COMMITS_365D=$(git log --since='365 days ago' --oneline 2>/dev/null | wc -l | tr -d ' ')
    echo "COMMITS_LAST_30_DAYS: $COMMITS_30D"
    echo "COMMITS_LAST_90_DAYS: $COMMITS_90D"
    echo "COMMITS_LAST_365_DAYS: $COMMITS_365D"

    # Top contributors
    echo ""
    echo "=== Top Contributors ==="
    git shortlog -sn --no-merges 2>/dev/null | head -10

    # Most active files (last 90 days)
    echo ""
    echo "=== Most Changed Files (last 90 days) ==="
    git log --since='90 days ago' --name-only --format='' 2>/dev/null | \
        sort | uniq -c | sort -rn | head -15

    # Recent commit messages (last 20)
    echo ""
    echo "=== Recent Commits ==="
    git log --oneline -20 2>/dev/null
else
    echo "NOT_A_GIT_REPO: true"
fi

# File counts (excluding artifacts)
echo ""
echo "=== File Counts ==="
TOTAL_FILES=$(find . -type f \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    -not -path '*/vendor/*' \
    -not -path '*/target/*' \
    -not -path '*/__pycache__/*' \
    -not -path '*/dist/*' \
    -not -path '*/build/*' \
    -not -path '*/venv/*' \
    -not -path '*/.venv/*' \
    -not -path '*/site-packages/*' \
    -not -path '*/.next/*' \
    -not -path '*/.tox/*' \
    -not -path '*/coverage/*' \
    -not -path '*/.terraform/*' \
    2>/dev/null | wc -l | tr -d ' ')
echo "TOTAL_FILES: $TOTAL_FILES"

# Line counts by common language extensions
echo ""
echo "=== Line Counts by Language ==="
for ext in py js ts jsx tsx go rs java kt rb php cs swift c cpp h hpp lua ex exs sh bash; do
    COUNT=$(find . -type f -name "*.$ext" \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/vendor/*' \
        -not -path '*/target/*' \
        -not -path '*/__pycache__/*' \
        -not -path '*/dist/*' \
        -not -path '*/build/*' \
        -not -path '*/venv/*' \
        -not -path '*/.venv/*' \
        2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] 2>/dev/null; then
        echo "LINES_$ext: $COUNT"
    fi
done

# Markdown file count (for documentation repos)
MD_COUNT=$(find . -type f -name "*.md" \
    -not -path '*/.git/*' \
    -not -path '*/node_modules/*' \
    2>/dev/null | wc -l | tr -d ' ')
echo "MARKDOWN_FILES: $MD_COUNT"

echo ""
echo "=== Stats Complete ==="
