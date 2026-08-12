{ config, pkgs, lib, inputs, self, ... }:

{
  # Themes
  home.activation.linkFirefoxDmsTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    FIREFOX_CSS="${config.home.homeDirectory}/.config/DankMaterialShell/firefox.css"
    if [ -f "$FIREFOX_CSS" ]; then
      for FIREFOX_BASE in \
        "${config.home.homeDirectory}/.mozilla/firefox" \
        "${config.home.homeDirectory}/.var/app/org.mozilla.firefox/.mozilla/firefox"; do
        if [ -d "$FIREFOX_BASE" ]; then
          while IFS= read -r profile; do
            $DRY_RUN_CMD mkdir -p "$profile/chrome"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$FIREFOX_CSS" "$profile/chrome/userChrome.css"
          done < <(find "$FIREFOX_BASE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
        fi
      done
    fi
  '';

  home.activation.linkZenTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ZEN_CSS="${config.home.homeDirectory}/.config/DankMaterialShell/zen.css"
    for ZEN_BASE in \
      "${config.home.homeDirectory}/.config/zen" \
      "${config.home.homeDirectory}/.var/app/app.zen_browser.zen/.zen"; do
      if [ -d "$ZEN_BASE" ]; then
        while IFS= read -r profile; do
          $DRY_RUN_CMD mkdir -p "$profile/chrome"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$ZEN_CSS" "$profile/chrome/userChrome.css"
        done < <(find "$ZEN_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
      fi
    done
  '';

  xdg.configFile."matugen/templates/zennotes.css".text = ''
    :root {
      color-scheme: dark;
      --z-bg: {{ colors.background.dark.red }} {{ colors.background.dark.green }} {{ colors.background.dark.blue }};
      --z-bg-softer: {{ colors.surface_variant.dark.red }} {{ colors.surface_variant.dark.green }} {{ colors.surface_variant.dark.blue }};
      --z-bg-1: {{ colors.surface.dark.red }} {{ colors.surface.dark.green }} {{ colors.surface.dark.blue }};
      --z-bg-2: {{ colors.surface.dark.red }} {{ colors.surface.dark.green }} {{ colors.surface.dark.blue }};
      --z-bg-3: {{ colors.surface.dark.red }} {{ colors.surface.dark.green }} {{ colors.surface.dark.blue }};
      --z-bg-4: {{ colors.outline.dark.red }} {{ colors.outline.dark.green }} {{ colors.outline.dark.blue }};
      --z-fg: {{ colors.on_surface.dark.red }} {{ colors.on_surface.dark.green }} {{ colors.on_surface.dark.blue }};
      --z-fg-1: {{ colors.on_surface.dark.red }} {{ colors.on_surface.dark.green }} {{ colors.on_surface.dark.blue }};
      --z-fg-2: {{ colors.on_surface_variant.dark.red }} {{ colors.on_surface_variant.dark.green }} {{ colors.on_surface_variant.dark.blue }};
      --z-grey-2: {{ colors.on_surface_variant.dark.red }} {{ colors.on_surface_variant.dark.green }} {{ colors.on_surface_variant.dark.blue }};
      --z-grey-1: {{ colors.outline.dark.red }} {{ colors.outline.dark.green }} {{ colors.outline.dark.blue }};
      --z-grey-0: {{ colors.outline.dark.red }} {{ colors.outline.dark.green }} {{ colors.outline.dark.blue }};
      --z-grey-dim: {{ colors.outline.dark.red }} {{ colors.outline.dark.green }} {{ colors.outline.dark.blue }};
      --z-accent: {{ colors.primary.dark.red }} {{ colors.primary.dark.green }} {{ colors.primary.dark.blue }};
      --z-accent-soft: {{ colors.secondary.dark.red }} {{ colors.secondary.dark.green }} {{ colors.secondary.dark.blue }};
      --z-accent-muted: {{ colors.tertiary.dark.red }} {{ colors.tertiary.dark.green }} {{ colors.tertiary.dark.blue }};
      --z-red: {{ colors.error.dark.red }} {{ colors.error.dark.green }} {{ colors.error.dark.blue }};
      --z-green: {{ colors.tertiary_container.dark.red }} {{ colors.tertiary_container.dark.green }} {{ colors.tertiary_container.dark.blue }};
      --z-yellow: {{ colors.inverse_on_surface.dark.red }} {{ colors.inverse_on_surface.dark.green }} {{ colors.inverse_on_surface.dark.blue }};
      --z-blue: {{ colors.secondary_container.dark.red }} {{ colors.secondary_container.dark.green }} {{ colors.secondary_container.dark.blue }};
      --z-purple: {{ colors.tertiary.dark.red }} {{ colors.tertiary.dark.green }} {{ colors.tertiary.dark.blue }};
      --z-aqua: {{ colors.on_tertiary.dark.red }} {{ colors.on_tertiary.dark.green }} {{ colors.on_tertiary.dark.blue }};
      --z-shadow: 0 0 0;
      --z-glass-a1: 0.58;
      --z-glass-a2: 0.46;
      --z-glass-a3: 0.32;
      --z-glass-a4: 0.22;
    }
  '';

  xdg.configFile."gtk-3.0/gtk.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
  xdg.configFile."gtk-4.0/gtk.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";
  xdg.configFile."environment.d/90-dms.conf".text = ''
    DMS_ENABLE_GTK4_REFRESH=1
  '';
  xdg.configFile."var/app/org.gnome.Nautilus/config/gtk-3.0/gtk.css".text = ''
    @import url("file://${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css");
  '';
  xdg.configFile."var/app/org.gnome.Nautilus/config/gtk-4.0/gtk.css".text = ''
    @import url("file://${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css");
  '';

  xdg.configFile."matugen/config.toml".text = ''
    [config]

    [templates.zennotes]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/zennotes.css"
    output_path = "${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen/theme.css"
  '';

  home.activation.ensureDmsThemeDirs = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD mkdir -p \
      "${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen" \
      "${config.home.homeDirectory}/.config/DankMaterialShell"
  '';

  home.file.".var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen/manifest.json".text = builtins.toJSON {
    name = "DMS Matugen";
    author = "DankMaterialShell";
    version = "1.0.0";
    description = "A dark ZenNotes theme generated from the active DMS palette.";
    modes = "dark";
    preview = { dark = "#1e1e2e"; };
  };

  home.activation.configureZenNotes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZN_CONFIG="${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/config.toml"
    $DRY_RUN_CMD mkdir -p "$(dirname "$ZN_CONFIG")"
    if [ -f "$ZN_CONFIG" ]; then
      if grep -q '^themeId = ' "$ZN_CONFIG"; then
        $DRY_RUN_CMD sed -i 's/^themeId = .*/themeId = "dms-matugen"/' "$ZN_CONFIG"
      elif grep -q '^\[appearance\]$' "$ZN_CONFIG"; then
        $DRY_RUN_CMD sed -i '/^\[appearance\]$/a themeId = "dms-matugen"' "$ZN_CONFIG"
      else
        $DRY_RUN_CMD cat >> "$ZN_CONFIG" <<EOF

[appearance]
themeId = "dms-matugen"
EOF
      fi
    else
      $DRY_RUN_CMD cat > "$ZN_CONFIG" <<EOF
[appearance]
themeId = "dms-matugen"
EOF
    fi
  '';

}
