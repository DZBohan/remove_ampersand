# remove_ampersand.sh
 
A small, safe bash utility for recursively removing `&` characters from file
and directory names without touching anything else in the name.
 
Example: `abc_H&E_def` → `abc_HE_def`
 
## Why
 
The `&` character has special meaning in shells (it backgrounds a command),
so paths containing it are easy to mishandle in scripts (`cd abc_H&E_def`
will actually try to run `cd abc_H` in the background and then run `E_def`
as a separate command). This script removes `&` from names in bulk so the
resulting paths are safe to use unquoted.
 
## Features
 
- **Dry run by default.** Nothing is renamed unless you pass `--apply`.
- **Deepest-first traversal** (`find -depth`), so renaming a parent
  directory never breaks the path to files/directories still waiting to
  be processed inside it.
- **Collision-safe.** If the target name already exists, that item is
  skipped and reported instead of being silently overwritten.
- **NUL-delimited processing**, so names with spaces or other special
  characters are handled correctly.
- Only removes `&` — every other character in the name is left exactly
  as it was.
## Usage
 
```bash
# Dry run — prints what would be renamed, changes nothing
./remove_ampersand.sh /path/to/root
 
# Apply — actually performs the renames
./remove_ampersand.sh /path/to/root --apply
```
 
### Example output
 
```
== DRY RUN mode (no changes will be made) ==
== Re-run with --apply to actually rename ==
Root: /data/project
 
RENAME: '/data/project/BRN003-41_H&E' -> '/data/project/BRN003-41_HE'
RENAME: '/data/project/BRN003-41_H&E/scan_H&E_20260625.tif' -> '/data/project/BRN003-41_H&E/scan_HE_20260625.tif'
 
Done. Matched: 2, Skipped (name collision): 0
This was a dry run. Re-run as:  ./remove_ampersand.sh "/data/project" --apply
```
 
## How it works
 
1. `find "$ROOT" -depth -name '*&*' -print0` finds every file and directory
   under the root whose name contains `&`, NUL-delimited, deepest entries
   first.
2. For each match, the `&` characters are stripped from the basename only
   (the parent path is untouched).
3. If the resulting name doesn't already exist, the item is renamed with
   `mv -n`. If it does exist, the rename is skipped and reported so nothing
   is overwritten.
4. A summary of matched/renamed and skipped items is printed at the end.
## Requirements
 
- `bash` 4+ (uses `set -euo pipefail`, process substitution)
- GNU `find` and `mv` (standard on Linux)
## Notes
 
- Always review the dry-run output before running with `--apply`.
- The script only strips `&`; it does not touch spaces, parentheses, or
  other special characters. Extend the `${base//&/}` substitution if you
  need to strip additional characters.
- Run with `--apply` only when you have write access to the entire tree —
  a partial failure partway through is safe (already-renamed items stay
  renamed) but you may need to re-run to finish the rest if it's
  interrupted.