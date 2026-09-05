#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf '%s\n' 'Usage: sync-xournalpp-config.sh --push|--pull REPOSITORY' >&2
  exit 2
}

mode="${1:-}"
repository="${2:-}"
[[ "$mode" == "--push" || "$mode" == "--pull" ]] || usage
[[ -n "$repository" ]] || usage

repository="$(cd -- "$repository" && pwd)"
native_root="${XDG_CONFIG_HOME:-$HOME/.config}/xournalpp"
repository_root="$repository/xournalpp"
files=(settings.xml toolbar.ini)

[[ -d "$repository_root" ]] || {
  printf '%s\n' "Xournal++ repository directory not found: $repository_root" >&2
  exit 1
}

if [[ "$mode" == "--push" ]]; then
  for file in "${files[@]}"; do
    source="$native_root/$file"
    destination="$repository_root/$file"
    [[ -f "$source" ]] || {
      printf '%s\n' "Native Xournal++ file not found: $source" >&2
      exit 1
    }
    install -Dm644 "$source" "$destination"
  done
else
  for file in "${files[@]}"; do
    source="$repository_root/$file"
    destination="$native_root/$file"
    [[ -f "$source" ]] || {
      printf '%s\n' "Repository Xournal++ file not found: $source" >&2
      exit 1
    }
    install -Dm644 "$source" "$destination"
  done
fi
