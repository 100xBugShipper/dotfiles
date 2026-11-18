
#!/usr/bin/env bash

set -euo pipefail

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
LOCKFILE="$NVIM_CONFIG/lazy-lock.json"
BACKUP="$LOCKFILE.backup"
REMOTE_LOCK="/tmp/primeagen-lock.json"
MERGED_LOCK="/tmp/merged-lock.json"

REPO="https://raw.githubusercontent.com/ThePrimeagen/init.lua/master/lazy-lock.json"

echo "==> Checking Neovim configuration..."

if [[ ! -f "$LOCKFILE" ]]; then
    echo "Error: lazy-lock.json not found at $LOCKFILE"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required. Install it with: brew install jq"
    exit 1
fi

echo "==> Backing up your lockfile..."

cp "$LOCKFILE" "$BACKUP"

echo "==> Downloading ThePrimeagen's lockfile..."

curl -fsSL "$REPO" -o "$REMOTE_LOCK"

echo "==> Validating JSON..."

jq empty "$LOCKFILE"
jq empty "$REMOTE_LOCK"

echo "==> Merging plugin commits..."

# Your lockfile is the base.
# ThePrimeagen's commits override matching plugin entries.
jq -s '.[0] * .[1]' \
    "$LOCKFILE" \
    "$REMOTE_LOCK" > "$MERGED_LOCK"

echo "==> Showing changed plugin commits..."

jq -n \
    --slurpfile old "$LOCKFILE" \
    --slurpfile new "$MERGED_LOCK" \
    '($old[0] | keys) as $keys |
     [$keys[] |
       select($old[0][.] != $new[0][.]) |
       {
         plugin: .,
         old_commit: $old[0][.].commit,
         new_commit: $new[0][.].commit
       }]'

echo
echo "==> Applying merged lockfile..."

mv "$MERGED_LOCK" "$LOCKFILE"

echo
echo "Done!"
echo "Backup: $BACKUP"
echo
echo "Open Neovim and run:"
echo "  :Lazy restore"
echo
echo "To revert:"
echo "  cp \"$BACKUP\" \"$LOCKFILE\""

