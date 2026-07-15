#!/usr/bin/env bash
#
# remove_ampersand.sh
#
# Recursively removes all '&' characters from file and directory names
# under a given root directory, leaving everything else unchanged.
#
# Example: "abc_H&E_def" -> "abc_HE_def"
#
# Usage:
#   ./remove_ampersand.sh /path/to/root          # dry run (default, safe)
#   ./remove_ampersand.sh /path/to/root --apply  # actually rename
#
# Notes:
# - Dry run by default: only prints what WOULD be renamed.
# - Processes deepest paths first (find ... -depth) so renaming a parent
#   directory never invalidates the paths of its not-yet-processed children.
# - Uses NUL-separated find output to safely handle spaces/special chars.
# - If the target name already exists, that item is skipped and reported,
#   so nothing is ever silently overwritten.

set -euo pipefail

ROOT="${1:-}"
APPLY="${2:-}"

if [[ -z "$ROOT" ]]; then
    echo "Usage: $0 <root_directory> [--apply]"
    exit 1
fi

if [[ ! -d "$ROOT" ]]; then
    echo "Error: '$ROOT' is not a directory."
    exit 1
fi

DRY_RUN=true
if [[ "$APPLY" == "--apply" ]]; then
    DRY_RUN=false
fi

if $DRY_RUN; then
    echo "== DRY RUN mode (no changes will be made) =="
    echo "== Re-run with --apply to actually rename =="
else
    echo "== APPLY mode: files/directories will be renamed =="
fi
echo "Root: $ROOT"
echo

count=0
skipped=0

# -depth: process contents of a directory before the directory itself
# (deepest first), so renaming a directory doesn't break paths to its
# not-yet-visited children.
while IFS= read -r -d '' path; do
    dir=$(dirname -- "$path")
    base=$(basename -- "$path")

    # Only touch names that actually contain '&'
    if [[ "$base" == *"&"* ]]; then
        newbase="${base//&/}"
        newpath="$dir/$newbase"

        if [[ -e "$newpath" ]]; then
            echo "SKIP (target exists): '$path' -> '$newpath'"
            skipped=$((skipped+1))
            continue
        fi

        echo "RENAME: '$path' -> '$newpath'"
        if ! $DRY_RUN; then
            mv -n -- "$path" "$newpath"
        fi
        count=$((count+1))
    fi
done < <(find "$ROOT" -depth -name '*&*' -print0)

echo
echo "Done. Matched: $count, Skipped (name collision): $skipped"
if $DRY_RUN; then
    echo "This was a dry run. Re-run as:  $0 \"$ROOT\" --apply"
fi
