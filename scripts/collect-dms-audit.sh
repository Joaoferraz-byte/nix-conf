#!/usr/bin/env bash
set -Eeuo pipefail

# This collector is intentionally passive: it reads user/system state, never
# changes settings, restarts services, posts data, or runs a wallpaper file.
# Usage: ./scripts/collect-dms-audit.sh [output-directory]

out_dir="${1:-$HOME/dms-audit-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$out_dir"

run() {
  local name="$1"
  shift
  {
    printf '%s\n' "# command: $*"
    printf '%s\n' "# collected: $(date --iso-8601=seconds)"
    "$@"
  } >"$out_dir/$name" 2>&1 || printf '\n[command exited %s]\n' "$?" >>"$out_dir/$name"
}

run_shell() {
  local name="$1"
  local command_text="$2"
  {
    printf '%s\n' "# command: $command_text"
    printf '%s\n' "# collected: $(date --iso-8601=seconds)"
    bash -c "$command_text"
  } >"$out_dir/$name" 2>&1 || printf '\n[command exited %s]\n' "$?" >>"$out_dir/$name"
}

printf '%s\n' "Writing passive Livara DMS audit to $out_dir"

run host.txt bash -c 'printf "hostname=%s\nuser=%s\nuid=%s\nhome=%s\n" "$(hostname)" "$USER" "$(id -u)" "$HOME"; uname -a; printf "\n--- os-release ---\n"; cat /etc/os-release'
run hardware.txt bash -c 'printf "%s\n" "--- cpu ---"; lscpu; printf "%s\n" "--- gpu ---"; lspci -nnk | grep -A3 -Ei "vga|3d|display" || true; printf "%s\n" "--- battery ---"; find /sys/class/power_supply -maxdepth 1 -mindepth 1 -printf "%f\n" 2>/dev/null || true; printf "%s\n" "--- bluetooth ---"; bluetoothctl list 2>&1 || true; printf "%s\n" "--- network devices ---"; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>&1 || true'

run repo-state.txt bash -c 'for d in "$HOME/.config/nixos" "$HOME/Projects/shell-conf" "$HOME/Projects/vim-conf" "$HOME/Projects/nix-conf"; do if [ -d "$d/.git" ]; then printf "--- %s ---\n" "$d"; git -C "$d" status --short --branch; git -C "$d" log -3 --pretty="format:%H %an <%ae> %s"; printf "\n"; fi; done'
run flake-pins.txt bash -c 'if [ -f "$HOME/.config/nixos/flake.lock" ]; then grep -n -A18 -B2 '"'"'"'shell-conf'"'"'"' "$HOME/.config/nixos/flake.lock"; grep -n -A18 -B2 '"'"'"'vim-conf'"'"'"' "$HOME/.config/nixos/flake.lock"; fi'

run dms-version.txt bash -c 'command -v dms || true; dms --version 2>&1 || true; command -v quickshell || true; quickshell --version 2>&1 || true'
run niri-version.txt bash -c 'command -v niri || true; niri --version 2>&1 || true; niri validate 2>&1 || true'
run dms-unit.txt systemctl --user status dms.service --no-pager
run dms-unit-definition.txt systemctl --user cat dms.service
run dms-unit-environment.txt systemctl --user show dms.service --property=Environment --property=ExecStart --property=MainPID --property=ActiveState --property=SubState
run dms-journal.txt journalctl --user -u dms.service -b --no-pager -n 250
run dms-related-units.txt bash -c 'systemctl --user list-units --all --no-legend | grep -Ei "dms|livara|matugen|wallpaper|audiorelay|easy" || true'

run dms-settings.json bash -c 'for f in "$HOME/.config/DankMaterialShell/settings.json" "$HOME/.local/state/DankMaterialShell/session.json" "$HOME/.config/DankMaterialShell/plugin_settings.json"; do printf "--- %s ---\n" "$f"; if [ -f "$f" ]; then jq . "$f" 2>&1 || cat "$f"; else printf "MISSING\n"; fi; done'
run dms-wallpaper-ipc.txt bash -c 'if command -v dms >/dev/null 2>&1; then for action in "wallpaper state" "wallpaper get"; do printf "--- dms ipc call %s ---\n" "$action"; timeout 8 dms ipc call $action 2>&1 || true; done; fi'
run wallpaper-watcher.txt systemctl --user status dms-wallpaperWatcherDaemon.service --no-pager
run wallpaper-journal.txt bash -c 'journalctl --user -b --no-pager -n 350 | grep -Ei "wallpaper|matugen|theme adapter|Foliate|Heroic|KDE|Vesktop|error" || true'
run applied-applications.json bash -c 'for f in "$HOME/.local/state/livara/theme/applied-applications.json" "$HOME/.local/state/livara/theme"/applied-applications.json; do if [ -f "$f" ]; then jq . "$f" 2>&1 || cat "$f"; fi; done'
run theme-files.txt bash -c 'for root in "$HOME/.cache/DankMaterialShell" "$HOME/.config/DankMaterialShell" "$HOME/.local/state/livara/theme" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/nvim" "$HOME/.config/wezterm" "$HOME/.config/vesktop"; do printf "--- %s ---\n" "$root"; if [ -e "$root" ]; then find "$root" -maxdepth 3 -type f -o -maxdepth 3 -type l | sort | while read -r f; do stat -c "%y %F %n -> %N" "$f" 2>/dev/null || true; done; else printf "MISSING\n"; fi; done'

run icon-state.txt bash -c 'printf "%s\n" "--- gsettings ---"; gsettings get org.gnome.desktop.interface icon-theme 2>&1 || true; gsettings get org.gnome.desktop.interface cursor-theme 2>&1 || true; printf "%s\n" "--- dconf ---"; dconf read /org/gnome/desktop/interface/icon-theme 2>&1 || true; dconf read /org/gnome/desktop/interface/cursor-theme 2>&1 || true; printf "%s\n" "--- environment ---"; printf "GTK_THEME=%s\nGTK_ICON_THEME=%s\nXCURSOR_THEME=%s\nXCURSOR_SIZE=%s\n" "${GTK_THEME-}" "${GTK_ICON_THEME-}" "${XCURSOR_THEME-}" "${XCURSOR_SIZE-}"; printf "%s\n" "--- icon directories ---"; find "$HOME/.icons" "$HOME/.local/share/icons" "/usr/share/icons" -maxdepth 2 -type d -iname '*kora*' -o -maxdepth 2 -type d -iname '*livara*' 2>/dev/null | sort'
run nautilus-state.txt bash -c 'gio info -a metadata::custom-icon-name "$HOME/Fire" "$HOME/Vault" "$HOME/Projects" "$HOME/Wallpapers" "$HOME/Pictures" 2>&1 || true; printf "%s\n" "--- bookmarks ---"; cat "$HOME/.config/gtk-3.0/bookmarks" "$HOME/.config/gtk-4.0/bookmarks" 2>/dev/null || true; printf "%s\n" "--- icon service ---"; systemctl --user status livara-nautilus-special-folder-icons.service --no-pager 2>&1 || true; systemctl --user cat livara-nautilus-special-folder-icons.service 2>&1 || true'

run tablet.txt bash -c 'command -v livara-tablet-status && livara-tablet-status || true; printf "%s\n" "--- by-id ---"; find /dev/input/by-id -maxdepth 1 -type l -printf "%f -> %l\n" 2>/dev/null | sort || true; printf "%s\n" "--- sys names ---"; for f in /sys/class/input/event*/device/name; do [ -r "$f" ] && printf "%s: %s\n" "$f" "$(cat "$f")"; done | sort'
run audio.txt bash -c 'systemctl --user status audiorelay-virtual-audio.service --no-pager 2>&1 || true; printf "%s\n" "--- service definition ---"; systemctl --user cat audiorelay-virtual-audio.service 2>&1 || true; printf "%s\n" "--- recent audio journal ---"; journalctl --user -u audiorelay-virtual-audio.service -b --no-pager -n 200 2>&1 || true; printf "%s\n" "--- wpctl ---"; wpctl status 2>&1 || true; printf "%s\n" "--- pactl nodes ---"; pactl list short sinks 2>&1 || true; pactl list short sources 2>&1 || true; printf "%s\n" "--- easyeffects processes ---"; pgrep -a -f "easyeffects|easyeffects-service" || true'
run network.txt bash -c 'nmcli -f GENERAL,DEVICE,ACTIVE,STATE device show 2>&1 || true; printf "%s\n" "--- routes ---"; ip -br link; ip -br address; ip route'
run niri-state.txt bash -c 'niri msg -j workspaces 2>&1 || true; printf "%s\n" "--- windows ---"; niri msg -j windows 2>&1 || true; printf "%s\n" "--- env relevant ---"; systemctl --user show-environment | grep -Ei "WAYLAND|NIRI|DMS|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|QT_|GTK_|MATUGEN" || true'
run fastfetch.txt bash -c 'command -v fastfetch && fastfetch --version && printf "\n--- config ---\n" && sed -n "1,260p" "$HOME/.config/fastfetch/config.jsonc" || true'
run face.txt bash -c 'ls -l "$HOME/.face" "$HOME/.face.icon" 2>&1 || true; uid=$(id -u); dbus-send --system --print-reply --dest=org.freedesktop.Accounts --type=method_call /org/freedesktop/Accounts/User"$uid" org.freedesktop.DBus.Properties.Get string:org.freedesktop.Accounts.User string:IconFile 2>&1 || true'

printf '%s\n' "--- archive ---"
archive="${out_dir%/}.tar.gz"
tar -czf "$archive" -C "$(dirname "$out_dir")" "$(basename "$out_dir")"
printf '%s\n' "Created $archive"
