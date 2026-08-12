#!/usr/bin/env bash
set -euo pipefail

local_dir="${XOURNALPP_LOCAL_CONFIG:-$HOME/.config/nixos/xournalpp}"
repo_dir="${1:-${XOURNALPP_REPO:-$HOME/.config/nixos/xournal-conf}}"

if [[ ! -d "$local_dir" ]]; then
  printf 'Local directory not found: %s\n' "$local_dir" >&2
  printf 'Run a Home Manager or NixOS activation first.\n' >&2
  exit 1
fi
if [[ ! -d "$repo_dir/.git" ]]; then
  printf 'xournal-conf Git checkout not found: %s\n' "$repo_dir" >&2
  printf 'Usage: %s /path/to/xournal-conf\n' "$0" >&2
  exit 1
fi

for file in settings.xml toolbar.ini; do
  source="$local_dir/$file"
  destination="$repo_dir/xournalpp/$file"
  if [[ ! -f "$source" ]]; then
    printf 'Local file not found: %s\n' "$source" >&2
    exit 1
  fi
  install -m 0644 "$source" "$destination"
  printf 'Synchronized: %s -> %s\n' "$source" "$destination"
done

printf '\nReview the changes before publishing:\n'
git -C "$repo_dir" diff -- xournalpp/settings.xml xournalpp/toolbar.ini
git -C "$repo_dir" status --short
printf '\nAfter review, run in the checkout:\n'
printf '  git add xournalpp/settings.xml xournalpp/toolbar.ini\n'
printf '  git commit -m "xournalpp: update user configuration"\n'
printf '  git push origin main\n'
