#!/usr/bin/env bash
# Generate a structured CHANGELOG.md from git history
# Reads commits since the last git tag and categorizes them

set -eo pipefail

# Configuration
OUTPUT_FILE="CHANGELOG.md"
TAG_PATTERN="v*"  # Pattern to identify release tags

# Get the latest git tag
LATEST_TAG=$(git describe --tags --abbrev=0 --match "$TAG_PATTERN" 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
  echo "No git tags found matching pattern '$TAG_PATTERN'. Showing all commits."
  COMMIT_RANGE=""
else
  echo "Latest tag: $LATEST_TAG"
  COMMIT_RANGE="$LATEST_TAG..HEAD"
fi

# Fetch commits in the range
git log --pretty=format:"%s" $COMMIT_RANGE > /tmp/commits_raw.txt

# If no commits since tag
if [ ! -s /tmp/commits_raw.txt ]; then
  echo "No commits found in range $COMMIT_RANGE"
  exit 0
fi

# Initialize arrays
declare -a added fixed changed removed other

# Categorization: conventional commits
while IFS= read -r commit; do
  [ -z "$commit" ] && continue
  lower_commit=$(echo "$commit" | tr '[:upper:]' '[:lower:]')
  case "$lower_commit" in
    add*|feat*|new*|introduce*|implement*|support*|create*)
      added+=("- $commit")
      ;;
    fix*|bug*|hotfix*|patch*|correct*|resolve*|repair*)
      fixed+=("- $commit")
      ;;
    change*|update*|refactor*|improve*|modify*|enhance*|adjust*|optimize*|upgrade*|\
    doc*|readme*|comment*|test*|spec*|build*|ci*|chore*|release*|bump*)
      changed+=("- $commit")
      ;;
    remove*|delete*|drop*|discard*|eliminate*|deprecate*)
      removed+=("- $commit")
      ;;
    *)
      other+=("- $commit")
      ;;
  esac
done < /tmp/commits_raw.txt

# Build sections (if array non-empty, join with newlines)
ADDED_SECTION=""
[ ${#added[@]} -gt 0 ] && printf -v ADDED_SECTION "%s\n" "${added[@]}"

FIXED_SECTION=""
[ ${#fixed[@]} -gt 0 ] && printf -v FIXED_SECTION "%s\n" "${fixed[@]}"

CHANGED_SECTION=""
[ ${#changed[@]} -gt 0 ] && printf -v CHANGED_SECTION "%s\n" "${changed[@]}"

REMOVED_SECTION=""
[ ${#removed[@]} -gt 0 ] && printf -v REMOVED_SECTION "%s\n" "${removed[@]}"

OTHER_SECTION=""
[ ${#other[@]} -gt 0 ] && printf -v OTHER_SECTION "%s\n" "${other[@]}"

# Generate date range for title
if [ -n "$COMMIT_RANGE" ]; then
  START_DATE=$(git log -1 --format=%ad --date=short $LATEST_TAG)
  END_DATE=$(git log -1 --format=%ad --date=short)
  DATE_RANGE="$START_DATE to $END_DATE"
else
  DATE_RANGE="All history"
fi

# Build output
cat > "$OUTPUT_FILE" <<EOF
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
$ADDED_SECTION

### Fixed
$FIXED_SECTION

### Changed
$CHANGED_SECTION

### Removed
$REMOVED_SECTION
EOF

# Append Other if any
if [ -n "$OTHER_SECTION" ]; then
  echo "" >> "$OUTPUT_FILE"
  echo "### Other" >> "$OUTPUT_FILE"
  echo "$OTHER_SECTION" >> "$OUTPUT_FILE"
fi

# Add footer with commit count
TOTAL_COMMITS=$(wc -l < /tmp/commits_raw.txt)
echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "Total commits: $TOTAL_COMMITS" >> "$OUTPUT_FILE"

echo "✓ Generated $OUTPUT_FILE"
echo "  Range: $DATE_RANGE"
echo "  Commits processed: $TOTAL_COMMITS"
