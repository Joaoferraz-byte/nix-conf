#!/usr/bin/env bash
set -euo pipefail

mode="push"
if [[ "${1:-}" == "--pull" || "${1:-}" == "--push" ]]; then
  mode="${1#--}"
  shift
fi

local_dir="${XOURNALPP_LOCAL_CONFIG:-$HOME/.config/nixos/xournalpp}"
repo_dir="${1:-${XOURNALPP_REPO:-$HOME/Projects/xournal-conf}}"

if [[ ! -d "$repo_dir/.git" ]]; then
  printf 'xournal-conf Git checkout not found: %s\n' "$repo_dir" >&2
  printf 'Usage: %s [--push|--pull] /path/to/xournal-conf\n' "$0" >&2
  exit 1
fi

if [[ "$mode" == "push" && ! -d "$local_dir" ]]; then
  printf 'Active Xournal++ directory not found: %s\n' "$local_dir" >&2
  printf 'Run a Home Manager activation first.\n' >&2
  exit 1
fi

if [[ "$mode" == "pull" ]]; then
  mkdir -p "$local_dir"
fi

for file in settings.xml toolbar.ini; do
  if [[ "$mode" == "push" ]]; then
    source="$local_dir/$file"
    destination="$repo_dir/xournalpp/$file"
  else
    source="$repo_dir/xournalpp/$file"
    destination="$local_dir/$file"
  fi

  if [[ ! -f "$source" ]]; then
    printf 'File not found: %s\n' "$source" >&2
    exit 1
  fi

  install -m 0644 "$source" "$destination"
  printf '%s: %s -> %s\n' "$mode" "$source" "$destination"
done

if [[ "$mode" == "push" ]]; then
  printf '\nReview the changes before publishing:\n'
  git -C "$repo_dir" diff -- xournalpp/settings.xml xournalpp/toolbar.ini
  git -C "$repo_dir" status --short
  printf '\nPublish after review:\n'
  printf '  git add xournalpp/settings.xml xournalpp/toolbar.ini\n'
  printf '  git commit -m "xournalpp: update user configuration"\n'
  printf '  git push origin main\n'
else
  printf '\nRestart Xournal++ to load the pulled configuration.\n'
fi
