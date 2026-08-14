#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sync-end4-state.sh <export|import|status>

Export runtime end-4 settings into home/livara/end4-state.
Import tracked end-4 settings into the current user's configuration.
Status lists files that can be exported or imported.
EOF
}

if [ "$#" -ne 1 ] || [[ "$1" != "export" && "$1" != "import" && "$1" != "status" ]]; then
  usage >&2
  exit 2
fi

mode="$1"
repo_root="${NIX_CONF_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
if [ -z "$repo_root" ] || [ ! -d "$repo_root/.git" ]; then
  printf '%s\n' 'Error: run this command from the nix-conf checkout or set NIX_CONF_ROOT.' >&2
  exit 1
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_root="$repo_root/home/livara/end4-state"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/nix-conf/backups/end4-state"

define_file() {
  runtime="$1"
  tracked="$2"
  if [ -e "$runtime" ] || [ -L "$runtime" ]; then
    printf '%s\t%s\n' "$runtime" "$tracked"
  fi
}

mapfile -t files < <(
  define_file "$config_home/illogical-impulse/config.json" "illogical-impulse/config.json"
  define_file "$config_home/hypr/hyprland/shellOverrides/main.lua" "hypr/shellOverrides/main.lua"
  for name in env execs general keybinds rules variables; do
    define_file "$config_home/hypr/custom/$name.lua" "hypr/custom/$name.lua"
  done
)

actions_runtime="$config_home/illogical-impulse/actions"
actions_tracked="illogical-impulse/actions"

validate_json() {
  file="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$file" >/dev/null
  fi
}

if [ "$mode" = "status" ]; then
  printf 'Repository state: %s\n' "$state_root"
  printf 'Runtime files:\n'
  if [ "${#files[@]}" -eq 0 ] && [ ! -d "$actions_runtime" ]; then
    printf '%s\n' '  (none found)'
  else
    for entry in "${files[@]}"; do
      IFS=$'\t' read -r runtime tracked <<< "$entry"
      printf '  %s -> %s\n' "$runtime" "$tracked"
    done
    [ -d "$actions_runtime" ] && printf '  %s -> %s/\n' "$actions_runtime" "$actions_tracked"
  fi
  printf 'Tracked files:\n'
  if [ -d "$state_root" ]; then
    find "$state_root" -type f -print | sort | sed "s#^$state_root/##" | sed 's/^/  /'
  else
    printf '%s\n' '  (none)'
  fi
  exit 0
fi

if [ "$mode" = "export" ]; then
  mkdir -p "$state_root"
  for entry in "${files[@]}"; do
    IFS=$'\t' read -r runtime tracked <<< "$entry"
    if [ -L "$runtime" ]; then
      printf 'Error: refusing to export symlink: %s\n' "$runtime" >&2
      exit 1
    fi
    if [ "$tracked" = "illogical-impulse/config.json" ]; then
      validate_json "$runtime" || {
        printf 'Error: invalid JSON: %s\n' "$runtime" >&2
        exit 1
      }
    fi
    destination="$state_root/$tracked"
    mkdir -p "$(dirname "$destination")"
    cp -a "$runtime" "$destination"
    printf 'Exported %s\n' "$tracked"
  done
  if [ -d "$actions_runtime" ]; then
    rm -rf "$state_root/$actions_tracked"
    mkdir -p "$(dirname "$state_root/$actions_tracked")"
    cp -a "$actions_runtime" "$state_root/$actions_tracked"
    printf 'Exported %s/\n' "$actions_tracked"
  fi
  printf '%s\n' 'Generated Matugen files were intentionally not exported.'
  printf '%s\n' 'Review the diff before committing; config.json may contain personal settings.'
  exit 0
fi

if [ ! -d "$state_root" ]; then
  printf 'Error: no tracked end-4 state exists at %s\n' "$state_root" >&2
  printf '%s\n' 'Run the export command first or create the state files manually.' >&2
  exit 1
fi

backup="$backup_root/$(date +%Y%m%d%H%M%S)"
mkdir -p "$backup"
imported=0

while IFS= read -r -d '' tracked_file; do
  relative="${tracked_file#$state_root/}"
  runtime="$config_home/$relative"
  if [ "$relative" = "hypr/shellOverrides/main.lua" ]; then
    runtime="$config_home/hypr/hyprland/shellOverrides/main.lua"
  elif [[ "$relative" == hypr/custom/*.lua ]]; then
    runtime="$config_home/hypr/custom/${relative#hypr/custom/}"
  fi
  if [ "$relative" = "illogical-impulse/config.json" ]; then
    validate_json "$tracked_file" || {
      printf 'Error: invalid JSON in tracked state: %s\n' "$tracked_file" >&2
      exit 1
    }
  fi
  if [ -e "$runtime" ] || [ -L "$runtime" ]; then
    backup_target="$backup/$(basename "$runtime")"
    mkdir -p "$(dirname "$backup_target")"
    cp -a "$runtime" "$backup_target"
  fi
  mkdir -p "$(dirname "$runtime")"
  rm -rf "$runtime"
  cp -a "$tracked_file" "$runtime"
  printf 'Imported %s\n' "$relative"
  imported=$((imported + 1))
done < <(find "$state_root" -type f -not -name '.gitkeep' -print0 | sort -z)

if [ "$imported" -eq 0 ]; then
  rmdir "$backup" 2>/dev/null || true
  printf '%s\n' 'No tracked end-4 state files were found.'
else
  printf 'Backup: %s\n' "$backup"
  printf '%s\n' 'Reload Hyprland with: hyprctl reload'
  printf '%s\n' 'Restart QuickShell with: qs -c ii ipc call reloadGlobal'
fi
