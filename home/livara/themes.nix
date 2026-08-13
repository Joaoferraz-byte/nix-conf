{ config, lib, ... }:
let
  home = config.home.homeDirectory;
  themeDir = "${config.xdg.stateHome}/nix-conf/theme";
in
{
  xdg.configFile."matugen/templates/firefox.css".text = ''
    :root {
      --nix-bg: {{ colors.background.dark.hex }};
      --nix-surface: {{ colors.surface.dark.hex }};
      --nix-surface-variant: {{ colors.surface_variant.dark.hex }};
      --nix-fg: {{ colors.on_surface.dark.hex }};
      --nix-fg-muted: {{ colors.on_surface_variant.dark.hex }};
      --nix-accent: {{ colors.primary.dark.hex }};
      --nix-accent-container: {{ colors.primary_container.dark.hex }};
    }

    #navigator-toolbox,
    #TabsToolbar,
    #nav-bar,
    #PersonalToolbar {
      background: var(--nix-bg) !important;
      color: var(--nix-fg) !important;
      border-color: var(--nix-surface-variant) !important;
    }

    .tabbrowser-tab[selected] .tab-background {
      background: var(--nix-accent-container) !important;
    }

    .tabbrowser-tab[selected] .tab-label,
    .toolbarbutton-1,
    .urlbar-input {
      color: var(--nix-fg) !important;
    }
  '';

  xdg.configFile."matugen/templates/zen.css".text = ''
    :root {
      --zen-background: {{ colors.background.dark.hex }};
      --zen-surface: {{ colors.surface.dark.hex }};
      --zen-surface-variant: {{ colors.surface_variant.dark.hex }};
      --zen-foreground: {{ colors.on_surface.dark.hex }};
      --zen-muted: {{ colors.on_surface_variant.dark.hex }};
      --zen-accent: {{ colors.primary.dark.hex }};
      --zen-accent-container: {{ colors.primary_container.dark.hex }};
    }

    #navigator-toolbox,
    #TabsToolbar,
    #nav-bar,
    #PersonalToolbar {
      background-color: var(--zen-background) !important;
      color: var(--zen-foreground) !important;
      border-color: var(--zen-surface-variant) !important;
    }

    .tabbrowser-tab[selected] .tab-background {
      background-color: var(--zen-accent-container) !important;
    }
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

  xdg.configFile."matugen/config.toml".text = ''
    [config]
    version_check = false

    [templates.m3colors]
    input_path = '~/.config/matugen/templates/colors.json'
    output_path = '~/.local/state/quickshell/user/generated/colors.json'

    [templates.hyprland]
    input_path = '~/.config/matugen/templates/hyprland/colors.lua'
    output_path = '~/.config/hypr/hyprland/colors.lua'

    [templates.hyprlock]
    input_path = '~/.config/matugen/templates/hyprland/hyprlock-colors.conf'
    output_path = '~/.config/hypr/hyprlock/colors.conf'

    [templates.fuzzel]
    input_path = '~/.config/matugen/templates/fuzzel/fuzzel_theme.ini'
    output_path = '~/.config/fuzzel/fuzzel_theme.ini'

    [templates.gtk3]
    input_path = '~/.config/matugen/templates/gtk-3.0/gtk.css'
    output_path = '~/.config/gtk-3.0/gtk.css'

    [templates.gtk4]
    input_path = '~/.config/matugen/templates/gtk-4.0/gtk.css'
    output_path = '~/.config/gtk-4.0/gtk.css'

    [templates.kde_colors]
    input_path = '~/.config/matugen/templates/kde/color.txt'
    output_path = '~/.local/state/quickshell/user/generated/color.txt'

    [templates.wallpaper]
    input_path = '~/.config/matugen/templates/wallpaper.txt'
    output_path = '~/.local/state/quickshell/user/generated/wallpaper/path.txt'

    [templates.firefox]
    input_path = '~/.config/matugen/templates/firefox.css'
    output_path = '~/.local/state/nix-conf/theme/firefox.css'

    [templates.zen]
    input_path = '~/.config/matugen/templates/zen.css'
    output_path = '~/.local/state/nix-conf/theme/zen.css'

    [templates.zennotes]
    input_path = '~/.config/matugen/templates/zennotes.css'
    output_path = '~/.local/state/nix-conf/theme/zennotes.css'
  '';

  home.file.".var/app/org.zennotes.ZenNotes/config/zennotes/themes/nix-conf-matugen/manifest.json".text = builtins.toJSON {
    name = "Nix Conf Matugen";
    author = "Joaoferraz-byte";
    version = "1.0.0";
    description = "A dark ZenNotes theme generated by Matugen.";
    modes = "dark";
    preview = { dark = "#1e1e2e"; };
  };

  home.file.".var/app/org.gnome.Nautilus/config/gtk-3.0/gtk.css".text = ''
    @import url("file://${home}/.config/gtk-3.0/gtk.css");
  '';
  home.file.".var/app/org.gnome.Nautilus/config/gtk-4.0/gtk.css".text = ''
    @import url("file://${home}/.config/gtk-4.0/gtk.css");
  '';

  home.activation.configureMatugenTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme_dir="${themeDir}"
    zennotes_dir="${home}/.var/app/org.zennotes.ZenNotes/config/zennotes/themes/nix-conf-matugen"
    $DRY_RUN_CMD mkdir -p "$theme_dir" "$zennotes_dir" "${home}/.config/gtk-3.0" "${home}/.config/gtk-4.0"

    for profile_base in \
      "${home}/.mozilla/firefox" \
      "${home}/.var/app/org.mozilla.firefox/.mozilla/firefox"; do
      if [ -d "$profile_base" ]; then
        while IFS= read -r profile; do
          $DRY_RUN_CMD mkdir -p "$profile/chrome"
          if [ -f "$profile/chrome/userChrome.css" ] && [ ! -L "$profile/chrome/userChrome.css" ]; then
            $DRY_RUN_CMD mv "$profile/chrome/userChrome.css" "$profile/chrome/userChrome.css.legacy"
          fi
          $DRY_RUN_CMD ln -sfn "$theme_dir/firefox.css" "$profile/chrome/userChrome.css"
        done < <(find "$profile_base" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
      fi
    done

    for profile_base in \
      "${home}/.config/zen" \
      "${home}/.var/app/app.zen_browser.zen/.zen"; do
      if [ -d "$profile_base" ]; then
        while IFS= read -r profile; do
          $DRY_RUN_CMD mkdir -p "$profile/chrome"
          if [ -f "$profile/chrome/userChrome.css" ] && [ ! -L "$profile/chrome/userChrome.css" ]; then
            $DRY_RUN_CMD mv "$profile/chrome/userChrome.css" "$profile/chrome/userChrome.css.legacy"
          fi
          $DRY_RUN_CMD ln -sfn "$theme_dir/zen.css" "$profile/chrome/userChrome.css"
        done < <(find "$profile_base" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
      fi
    done

    $DRY_RUN_CMD ln -sfn "$theme_dir/zennotes.css" "$zennotes_dir/theme.css"

    config_file="${home}/.var/app/org.zennotes.ZenNotes/config/zennotes/config.toml"
    $DRY_RUN_CMD mkdir -p "$(dirname "$config_file")"
    if [ -f "$config_file" ]; then
      if grep -q '^themeId = ' "$config_file"; then
        $DRY_RUN_CMD sed -i 's/^themeId = .*/themeId = "nix-conf-matugen"/' "$config_file"
      elif grep -q '^\[appearance\]$' "$config_file"; then
        $DRY_RUN_CMD sed -i '/^\[appearance\]$/a themeId = "nix-conf-matugen"' "$config_file"
      else
        printf '\n[appearance]\nthemeId = "nix-conf-matugen"\n' | $DRY_RUN_CMD tee -a "$config_file" >/dev/null
      fi
    else
      printf '[appearance]\nthemeId = "nix-conf-matugen"\n' | $DRY_RUN_CMD tee "$config_file" >/dev/null
    fi
  '';
}
