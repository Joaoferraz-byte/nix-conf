#!/usr/bin/env bash
set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
THEME_DIR="$XDG_STATE_HOME/nix-conf/theme"
FIREFOX_CSS="$THEME_DIR/firefox.css"
ZEN_CSS="$THEME_DIR/zen.css"
ZENNOTES_CSS="$THEME_DIR/zennotes.css"

link_css() {
  local profile="$1"
  local css="$2"
  local target="$profile/chrome/userChrome.css"

  [[ -f "$css" ]] || return 0
  mkdir -p "$profile/chrome"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv -n "$target" "$target.legacy" || true
  fi
  ln -sfn "$css" "$target"
}

ensure_firefox_pref() {
  local profile="$1"
  local user_js="$profile/user.js"

  [[ -d "$profile" ]] || return 0
  if [[ -L "$user_js" ]]; then
    return 0
  fi
  touch "$user_js"
  if ! grep -Fq 'toolkit.legacyUserProfileCustomizations.stylesheets' "$user_js"; then
    printf '%s\n' 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$user_js"
  fi
  if ! grep -Fq 'layout.css.prefers-color-scheme.content-override' "$user_js"; then
    printf '%s\n' 'user_pref("layout.css.prefers-color-scheme.content-override", 2);' >> "$user_js"
  fi
}

sync_browser_profiles() {
  local base="$1"
  local css="$2"
  [[ -d "$base" ]] || return 0

  while IFS= read -r -d '' profile; do
    link_css "$profile" "$css"
    ensure_firefox_pref "$profile"
  done < <(find "$base" -mindepth 1 -maxdepth 2 -type f -name prefs.js -printf '%h\0' 2>/dev/null | sort -zu)
}

detect_theme_mode() {
  local scheme gtk_theme
  scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || true)"
  gtk_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || true)"
  case "$scheme:$gtk_theme" in
    prefer-light:*|*:adw-gtk3) printf '%s\n' light ;;
    *) printf '%s\n' dark ;;
  esac
}

sync_gtk_mode() {
  local mode="$1"
  if command -v gsettings >/dev/null 2>&1; then
    if [[ "$mode" == light ]]; then
      gsettings set org.gnome.desktop.interface color-scheme prefer-light || true
      gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3 || true
    else
      gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
      gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark || true
    fi
    gsettings set org.gnome.desktop.interface icon-theme Kora || true
  fi
}

set_toml_key() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp="$file.tmp"

  if grep -qE "^${key}[[:space:]]*=" "$file"; then
    sed -E "s|^${key}[[:space:]]*=.*|${key} = ${value}|" "$file" > "$tmp"
  else
    if grep -q '^\[appearance\]$' "$file"; then
      sed "/^\[appearance\]$/a ${key} = ${value}" "$file" > "$tmp"
    else
      {
        cat "$file"
        printf '\n[appearance]\n%s = %s\n' "$key" "$value"
      } > "$tmp"
    fi
  fi
  mv "$tmp" "$file"
}

sync_zennotes() {
  local root="$1"
  local theme="$root/themes/nix-conf-matugen"
  local config="$root/config.toml"

  mkdir -p "$theme"
  [[ -f "$ZENNOTES_CSS" ]] && ln -sfn "$ZENNOTES_CSS" "$theme/theme.css"
  touch "$config"
  sed -E '/^(themeId|themeMode|themeFamily)[[:space:]]*=/d' "$config" > "$config.tmp"
  mv "$config.tmp" "$config"
  set_toml_key "$config" theme_family '"custom"'
  set_toml_key "$config" theme_mode '"auto"'
  set_toml_key "$config" theme_id '"custom-nix-conf-matugen"'
}

sync_gtk_sandbox() {
  local root="$1"
  mkdir -p "$root/gtk-3.0" "$root/gtk-4.0"
  [[ -f "$XDG_CONFIG_HOME/gtk-3.0/gtk.css" ]] && cp -L "$XDG_CONFIG_HOME/gtk-3.0/gtk.css" "$root/gtk-3.0/gtk.css"
  [[ -f "$XDG_CONFIG_HOME/gtk-4.0/gtk.css" ]] && cp -L "$XDG_CONFIG_HOME/gtk-4.0/gtk.css" "$root/gtk-4.0/gtk.css"
}

sync_browser_profiles "$HOME/.mozilla/firefox" "$FIREFOX_CSS"
sync_browser_profiles "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" "$FIREFOX_CSS"
sync_browser_profiles "$HOME/.zen" "$ZEN_CSS"
sync_browser_profiles "$XDG_CONFIG_HOME/zen" "$ZEN_CSS"
sync_browser_profiles "$HOME/.var/app/app.zen_browser.zen/.zen" "$ZEN_CSS"

sync_gtk_mode "$(detect_theme_mode)"
sync_zennotes "$XDG_CONFIG_HOME/zennotes"
sync_zennotes "$HOME/.var/app/org.zennotes.ZenNotes/config/zennotes"
sync_gtk_sandbox "$HOME/.var/app/org.gnome.Nautilus/config"
sync_gtk_sandbox "$HOME/.var/app/com.github.xournalpp.xournalpp/config"
