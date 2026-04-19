#!/bin/bash
# ─────────────────────────────────────────────
#  publish.sh — Gr3ytrac3 / The OffSec Desk
#  Syncs Obsidian Published/ → Hugo content/posts/
#  then commits and pushes to GitHub
# ─────────────────────────────────────────────

VAULT_PUBLISHED="/home/gr3ytrac3/Documents/main/Published"
HUGO_POSTS="/home/gr3ytrac3/offsec-desk-site/content/posts"
HUGO_SITE="/home/gr3ytrac3/offsec-desk-site"
HUGO_STATIC_IMAGES="/home/gr3ytrac3/offsec-desk-site/static/images"

# ── Colors ────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${DIM}── The OffSec Desk Publisher ──────────────────${NC}"
echo ""

# ── Check Published folder exists ─────────────
if [ ! -d "$VAULT_PUBLISHED" ]; then
  echo -e "${RED}[error]${NC} Published folder not found: $VAULT_PUBLISHED"
  exit 1
fi

# ── Count files ───────────────────────────────
MD_FILES=$(find "$VAULT_PUBLISHED" -maxdepth 1 -name "*.md" | wc -l)
IMG_FILES=$(find "$VAULT_PUBLISHED" -maxdepth 1 \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" \) | wc -l)

if [ "$MD_FILES" -eq 0 ]; then
  echo -e "${YELLOW}[warn]${NC}  No markdown files found in Published/"
  echo -e "       Add notes to ~/Documents/main/Published/ first"
  echo ""
  exit 0
fi

echo -e "${DIM}[scan]${NC}  Found ${MD_FILES} post(s), ${IMG_FILES} image(s)"
echo ""

# ── Sync markdown files ───────────────────────
echo -e "${DIM}[sync]${NC}  Copying posts → content/posts/"
COPIED=0
SKIPPED=0

for f in "$VAULT_PUBLISHED"/*.md; do
  fname=$(basename "$f")
  dest="$HUGO_POSTS/$fname"

  # Check if file changed or is new
  if [ ! -f "$dest" ] || ! cmp -s "$f" "$dest"; then
    cp "$f" "$dest"
    echo -e "       ${GREEN}+${NC} $fname"
    COPIED=$((COPIED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo -e "       ${DIM}$COPIED updated, $SKIPPED unchanged${NC}"
echo ""

# ── Sync images ───────────────────────────────
if [ "$IMG_FILES" -gt 0 ]; then
  echo -e "${DIM}[img]${NC}   Copying images → static/images/"
  mkdir -p "$HUGO_STATIC_IMAGES"
  for img in "$VAULT_PUBLISHED"/*.png "$VAULT_PUBLISHED"/*.jpg "$VAULT_PUBLISHED"/*.jpeg "$VAULT_PUBLISHED"/*.gif "$VAULT_PUBLISHED"/*.webp; do
    [ -f "$img" ] || continue
    imgname=$(basename "$img")
    # Rename Obsidian pasted image names to url-safe
    safe=$(echo "$imgname" | tr ' ' '-')
    cp "$img" "$HUGO_STATIC_IMAGES/$safe"
    echo -e "       ${GREEN}+${NC} $safe"
  done
  echo ""
fi

# ── Validate frontmatter ──────────────────────
echo -e "${DIM}[check]${NC} Validating frontmatter..."
ERRORS=0

for f in "$VAULT_PUBLISHED"/*.md; do
  fname=$(basename "$f")

  # Check for required fields
  if ! grep -q "^title:" "$f"; then
    echo -e "       ${RED}✗${NC} $fname — missing 'title'"
    ERRORS=$((ERRORS + 1))
  fi
  if ! grep -q "^date:" "$f"; then
    echo -e "       ${RED}✗${NC} $fname — missing 'date'"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo -e "${RED}[error]${NC} Fix frontmatter errors before publishing"
  echo -e "       Required fields: title, date"
  echo ""
  exit 1
fi

echo -e "       ${GREEN}✓${NC} All posts valid"
echo ""

# ── Hugo build check ─────────────────────────
echo -e "${DIM}[build]${NC} Running Hugo build check..."
cd "$HUGO_SITE"

BUILD_OUTPUT=$(hugo --minify 2>&1)
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
  echo -e "${RED}[error]${NC} Hugo build failed:"
  echo "$BUILD_OUTPUT" | grep "ERROR" | sed 's/^/       /'
  echo ""
  echo -e "       Fix errors before pushing."
  exit 1
fi

echo -e "       ${GREEN}✓${NC} Build successful"
echo ""

# ── Git push ──────────────────────────────────
echo -e "${DIM}[git]${NC}   Committing and pushing..."

git add .

# Auto-generate commit message from changed files
CHANGED=$(git diff --cached --name-only | grep "content/posts" | sed 's|content/posts/||' | sed 's|.md||' | tr '\n' ', ' | sed 's/,$//')

if [ -z "$CHANGED" ]; then
  COMMIT_MSG="update: site content"
else
  COMMIT_MSG="post: $CHANGED"
fi

git commit -m "$COMMIT_MSG" --quiet

PUSH_OUTPUT=$(git push 2>&1)
PUSH_EXIT=$?

if [ $PUSH_EXIT -ne 0 ]; then
  echo -e "${RED}[error]${NC} Git push failed:"
  echo "$PUSH_OUTPUT" | sed 's/^/       /'
  exit 1
fi

echo -e "       ${GREEN}✓${NC} Pushed → GitHub Actions deploying"
echo ""
echo -e "${GREEN}── Done ───────────────────────────────────────${NC}"
echo -e "   Live in ~60s at https://gr3ytrac3.github.io"
echo ""
