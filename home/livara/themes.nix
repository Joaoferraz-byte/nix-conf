{ config, lib, pkgs, ... }:
let
  themeDir = "${config.xdg.stateHome}/nix-conf/theme";
  themeManifest = builtins.toJSON {
    name = "Nix Conf Matugen";
    author = "Joaoferraz-byte";
    version = "2.1.0";
    description = "A Matugen theme generated from the active end-4 palette.";
    modes = "both";
    preview = {
      light = "#eff1f5";
      dark = "#1e1e2e";
    };
  };
  themeSyncScript = pkgs.writeShellScript "sync-matugen-apps" (builtins.readFile ../../scripts/sync-matugen-apps.sh);
in
{
  home.file.".local/bin/sync-matugen-apps".source = themeSyncScript;

  xdg.configFile."matugen/templates/firefox.css".text = ''
    :root {
      color-scheme: light dark;
      --nix-bg: {{ colors.background.default.hex }};
      --nix-surface: {{ colors.surface.default.hex }};
      --nix-surface-variant: {{ colors.surface_variant.default.hex }};
      --nix-fg: {{ colors.on_surface.default.hex }};
      --nix-fg-muted: {{ colors.on_surface_variant.default.hex }};
      --nix-accent: {{ colors.primary.default.hex }};
      --nix-accent-container: {{ colors.primary_container.default.hex }};
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
      color-scheme: light dark;
      --zen-background: {{ colors.background.default.hex }};
      --zen-surface: {{ colors.surface.default.hex }};
      --zen-surface-variant: {{ colors.surface_variant.default.hex }};
      --zen-foreground: {{ colors.on_surface.default.hex }};
      --zen-muted: {{ colors.on_surface_variant.default.hex }};
      --zen-accent: {{ colors.primary.default.hex }};
      --zen-accent-container: {{ colors.primary_container.default.hex }};
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
      color-scheme: light dark;
      --z-bg: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
      --z-bg-softer: {{ colors.surface_container.default.red }} {{ colors.surface_container.default.green }} {{ colors.surface_container.default.blue }};
      --z-bg-1: {{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }};
      --z-bg-2: {{ colors.surface_container_high.default.red }} {{ colors.surface_container_high.default.green }} {{ colors.surface_container_high.default.blue }};
      --z-bg-3: {{ colors.surface_container_highest.default.red }} {{ colors.surface_container_highest.default.green }} {{ colors.surface_container_highest.default.blue }};
      --z-bg-4: {{ colors.outline.default.red }} {{ colors.outline.default.green }} {{ colors.outline.default.blue }};
      --z-fg: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};
      --z-fg-1: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};
      --z-fg-2: {{ colors.on_surface_variant.default.red }} {{ colors.on_surface_variant.default.green }} {{ colors.on_surface_variant.default.blue }};
      --z-grey-2: {{ colors.on_surface_variant.default.red }} {{ colors.on_surface_variant.default.green }} {{ colors.on_surface_variant.default.blue }};
      --z-grey-1: {{ colors.outline.default.red }} {{ colors.outline.default.green }} {{ colors.outline.default.blue }};
      --z-grey-0: {{ colors.outline_variant.default.red }} {{ colors.outline_variant.default.green }} {{ colors.outline_variant.default.blue }};
      --z-grey-dim: {{ colors.outline.default.red }} {{ colors.outline.default.green }} {{ colors.outline.default.blue }};
      --z-accent: {{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }};
      --z-accent-soft: {{ colors.secondary.default.red }} {{ colors.secondary.default.green }} {{ colors.secondary.default.blue }};
      --z-accent-muted: {{ colors.tertiary.default.red }} {{ colors.tertiary.default.green }} {{ colors.tertiary.default.blue }};
      --z-red: {{ colors.error.default.red }} {{ colors.error.default.green }} {{ colors.error.default.blue }};
      --z-green: {{ colors.tertiary_container.default.red }} {{ colors.tertiary_container.default.green }} {{ colors.tertiary_container.default.blue }};
      --z-yellow: {{ colors.inverse_on_surface.default.red }} {{ colors.inverse_on_surface.default.green }} {{ colors.inverse_on_surface.default.blue }};
      --z-blue: {{ colors.secondary_container.default.red }} {{ colors.secondary_container.default.green }} {{ colors.secondary_container.default.blue }};
      --z-purple: {{ colors.tertiary.default.red }} {{ colors.tertiary.default.green }} {{ colors.tertiary.default.blue }};
      --z-aqua: {{ colors.on_tertiary.default.red }} {{ colors.on_tertiary.default.green }} {{ colors.on_tertiary.default.blue }};
      --z-shadow: 0 0 0;
      --z-glass-a1: 0.58;
      --z-glass-a2: 0.46;
      --z-glass-a3: 0.32;
      --z-glass-a4: 0.22;
    }

    :root[data-theme-mode="dark"] {
      color-scheme: dark;
      --z-bg: {{ colors.background.dark.red }} {{ colors.background.dark.green }} {{ colors.background.dark.blue }};
      --z-bg-softer: {{ colors.surface_container.dark.red }} {{ colors.surface_container.dark.green }} {{ colors.surface_container.dark.blue }};
      --z-bg-1: {{ colors.surface.dark.red }} {{ colors.surface.dark.green }} {{ colors.surface.dark.blue }};
      --z-bg-2: {{ colors.surface_container_high.dark.red }} {{ colors.surface_container_high.dark.green }} {{ colors.surface_container_high.dark.blue }};
      --z-bg-3: {{ colors.surface_container_highest.dark.red }} {{ colors.surface_container_high.dark.green }} {{ colors.surface_container_high.dark.blue }};
      --z-bg-4: {{ colors.outline.dark.red }} {{ colors.outline.dark.green }} {{ colors.outline.dark.blue }};
      --z-fg: {{ colors.on_surface.dark.red }} {{ colors.on_surface.dark.green }} {{ colors.on_surface.dark.blue }};
      --z-fg-1: {{ colors.on_surface.dark.red }} {{ colors.on_surface.dark.green }} {{ colors.on_surface.dark.blue }};
      --z-fg-2: {{ colors.on_surface_variant.dark.red }} {{ colors.on_surface_variant.dark.green }} {{ colors.on_surface_variant.dark.blue }};
      --z-grey-2: {{ colors.on_surface_variant.dark.red }} {{ colors.on_surface_variant.dark.green }} {{ colors.on_surface_variant.dark.blue }};
      --z-grey-1: {{ colors.outline.dark.red }} {{ colors.outline.dark.green }} {{ colors.outline.dark.blue }};
      --z-grey-0: {{ colors.outline_variant.dark.red }} {{ colors.outline_variant.dark.green }} {{ colors.outline_variant.dark.blue }};
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
    }
  '';

  xdg.configFile."matugen/templates/xournalpp.gpl".text = ''
    GIMP Palette
    Name: Nix Conf Matugen
    Columns: 4
    #
    {{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }} Primary
    {{ colors.secondary.default.red }} {{ colors.secondary.default.green }} {{ colors.secondary.default.blue }} Secondary
    {{ colors.tertiary.default.red }} {{ colors.tertiary.default.green }} {{ colors.tertiary.default.blue }} Tertiary
    {{ colors.primary_container.default.red }} {{ colors.primary_container.default.green }} {{ colors.primary_container.default.blue }} Primary container
    {{ colors.secondary_container.default.red }} {{ colors.secondary_container.default.green }} {{ colors.secondary_container.default.blue }} Secondary container
    {{ colors.tertiary_container.default.red }} {{ colors.tertiary_container.default.green }} {{ colors.tertiary_container.default.blue }} Tertiary container
    {{ colors.error.default.red }} {{ colors.error.default.green }} {{ colors.error.default.blue }} Error
    {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }} Foreground
    {{ colors.on_surface_variant.default.red }} {{ colors.on_surface_variant.default.green }} {{ colors.on_surface_variant.default.blue }} Muted
    {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }} Background
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

    [templates.xournalpp]
    input_path = '~/.config/matugen/templates/xournalpp.gpl'
    output_path = '~/.config/xournalpp/palettes/matugen.gpl'
  '';

  home.file = {
    ".var/app/org.zennotes.ZenNotes/config/zennotes/themes/nix-conf-matugen/manifest.json".text = themeManifest;
    ".config/zennotes/themes/nix-conf-matugen/manifest.json".text = themeManifest;
  };

  home.activation.configureMatugenTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${themeSyncScript}
  '';
}
