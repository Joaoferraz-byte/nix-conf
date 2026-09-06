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
required_files=(settings.xml toolbar.ini)
optional_files=(palettes/tokyonight.gpl default_template.tex)

[[ -d "$repository_root" ]] || {
  printf '%s\n' "Xournal++ repository directory not found: $repository_root" >&2
  exit 1
}

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

escape_sed_pattern() {
  printf '%s' "$1" | sed 's/[.[\*^$\\|]/\\&/g'
}

copy_file() {
  local source="$1"
  local destination="$2"
  local direction="$3"
  local temporary native_root_escaped native_root_pattern
  [[ -f "$source" ]] || {
    printf '%s\n' "File not found: $source" >&2
    exit 1
  }
  if [[ "$source" == */settings.xml ]]; then
    temporary="$(mktemp)"
    if [[ "$direction" == "pull" ]]; then
      native_root_escaped="$(escape_sed_replacement "$native_root")"
      sed -e "s|@XOURNALPP_CONFIG_HOME@|$native_root_escaped|g" "$source" > "$temporary"
    else
      native_root_pattern="$(escape_sed_pattern "$native_root")"
      sed -e "s|$native_root_pattern|@XOURNALPP_CONFIG_HOME@|g" "$source" > "$temporary"
    fi
    install -Dm644 "$temporary" "$destination"
    rm -f "$temporary"
  else
    install -Dm644 "$source" "$destination"
  fi
}

if [[ "$mode" == "--push" ]]; then
  for file in "${required_files[@]}"; do
    copy_file "$native_root/$file" "$repository_root/$file" push
  done
  for file in "${optional_files[@]}"; do
    if [[ -f "$native_root/$file" ]]; then
      copy_file "$native_root/$file" "$repository_root/$file" push
    else
      printf '%s\n' "Optional native Xournal++ asset not found; preserving repository copy: $native_root/$file" >&2
    fi
  done
else
  for file in "${required_files[@]}" "${optional_files[@]}"; do
    copy_file "$repository_root/$file" "$native_root/$file" pull
  done
fi
