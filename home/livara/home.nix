{
  config,
  pkgs,
  lib,
  inputs,
  self,
  ...
}:
let
  iconsPath = builtins.path {
    path = ../../Icons;
    name = "nix-conf-icons";
  };
  profileIcon = iconsPath + "/6afde16e1ef1cb3257b30e01890787dd.jpg";
  randomDmsWallpaper = pkgs.writeShellScript "dms-wallpaper-random-on-login" ''
    set -eu
    wallpapers_dir="${config.home.homeDirectory}/Wallpapers"
    wallpaper="$(${pkgs.findutils}/bin/find "$wallpapers_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print | ${pkgs.coreutils}/bin/shuf -n 1)"
    if [ -z "$wallpaper" ]; then
      exit 1
    fi
    for attempt in $(${pkgs.coreutils}/bin/seq 1 30); do
      if dms ipc call wallpaper set "$wallpaper"; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    exit 1
  '';
in
{
  # Imports
  imports = [
    inputs.dms-plugin-registry.homeModules.default
    inputs.shell-conf.homeManagerModules.default
    inputs.zen-browser.homeModules.beta
  ];

  # Home Profile
  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "26.11";

  # Environment
  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projetos";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  # Avatar
  home.file.".face.icon".source = profileIcon;

  # Fire — directory for programs to be run under firejail
  home.file."Fire/.keep".text = "";

  # Neovim
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };

  # Zen Browser — declarative profile configuration
  # Preferences are written to prefs.js by zen-browser-flake.
  # The Matugen/DMS theme is imported via userChrome; shell-conf/zen.nix
  # already sets toolkit.legacyUserProfileCustomizations.stylesheets.
  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
    };
  };

  # Zen Browser theme: DMS matugen generates ~/.config/DankMaterialShell/zen.css at runtime.
  # The official DMS approach creates a symlink from the profile's chrome/userChrome.css
  # to the generated zen.css. We replicate this via home.activation because:
  # 1. @import url("file://...") doesn't work in userChrome.css (chrome CSP blocks file://)
  # 2. The zen-browser-flake userChrome option writes content at build time, but zen.css
  #    is generated at runtime by matugen after wallpaper changes.
  # 3. A symlink ensures the browser always reads the latest zen.css without rebuilds.
  programs.zen-browser.profiles.default.userChrome = "";

  # Firefox uses the same DMS Matugen template as upstream DMS. The generated
  # CSS is linked into every discovered native/Flatpak Firefox profile below.
  programs.firefox = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
    };
    profiles.default = {
      id = 0;
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;
        "userChrome.theme-material" = true;
      };
    };
  };

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

    if [ -f "$ZEN_CSS" ]; then
      # Zen uses ~/.config/zen for native installs and ~/.var/app/app.zen_browser.zen/.zen
      # for the Flatpak build. Profile directories carry a random suffix, so locate
      # every profile rather than hardcoding a single generated profile name.
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
    fi
  '';

  # Niri config: the keybinds, environment, layout and wallpaper IPC
  # bindings now come from the shell-conf `programs.niri.settings` module
  # (transitively imported above), which uses the current KDL syntax and
  # includes the DMS wallpaper IPC shortcut (Mod+Shift+W). Only the
  # per-machine input settings and extra autostart commands remain here.
  #
  # Legacy syntax (bare `Mod+Q close-window`, `spawn-at-startup { command
  # [...] }`) was rejected by `niri validate` — since niri v25.08, binds
  # must be written `Mod+Q { close-window; }` with a semicolon-terminated
  # block, and spawn-at-startup takes plain arguments.
  # Add machine-specific settings to the niri-flake module. The module
  # already owns ~/.config/niri/config.kdl, so do not declare that target
  # separately with xdg.configFile.
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "br";
      touchpad = {
        tap = true;
        dwt = true;
        natural-scroll = true;
      };
    };
    spawn-at-startup = [
      { command = [ "xwayland-satellite" ":0" ]; }
      {
        command = [
          "swaybg"
          "-i"
          "${config.home.homeDirectory}/.config/nixos/Wallpapers/wallhaven-83qwky.png"
          "-m"
          "fill"
        ];
      }
    ];
  };

  # Apply generated niri config changes to the current session when possible.
  # The symlink-reload diagnosis from the brief is stale for current niri, so
  # this uses niri's supported action rather than replacing the module output.
  home.activation.reloadNiriConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if command -v niri >/dev/null 2>&1 && [ -n "''${NIRI_SOCKET:-}" ]; then
      niri msg action load-config-file >/dev/null 2>&1 || true
    fi
  '';

  # Shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake .";
    };
    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "robbyrussell";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Packages
  home.packages = with pkgs; [
    manim
    nerd-fonts.jetbrains-mono
    git

    # Xournal++ with a complete TeX toolchain for advanced mathematics,
    # programming listings, SI units, circuit diagrams and hardware notes.
    xournalpp
    texlive.combined.scheme-full

    # Affinity v3 packaged by affinity-nix; the package creates its own
    # desktop entries and keeps user data outside the immutable Nix store.
    pkgs.affinity-v3
  ];

  # ZenNotes — adaptive theme via Matugen.
  # DMS invokes Matugen with ~/.config/matugen/config.toml. Manage that
  # configuration declaratively so the custom template is present even when
  # the file did not exist before activation; do not append to a possibly
  # absent or Home-Manager-managed file from an activation script.
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

  xdg.configFile."xournalpp/settings.xml".text = builtins.replaceStrings
    [ "/home/livara/.config/xournalpp" ]
    [ "${config.home.homeDirectory}/.config/xournalpp" ]
    (builtins.readFile "${inputs.xournal-conf}/xournalpp/settings.xml");
  xdg.configFile."xournalpp/toolbar.ini".source = "${inputs.xournal-conf}/xournalpp/toolbar.ini";
  xdg.configFile."xournalpp/default_template.tex".source = "${inputs.xournal-conf}/xournalpp/default_template.tex";
  xdg.configFile."xournalpp/palettes/tokyo-night.gpl".source = "${inputs.xournal-conf}/xournalpp/palettes/tokyo-night.gpl";

  # GTK theming via DMS matugen palette.
  # DMS generates ~/.config/gtk-{3,4}.0/dank-colors.css on every wallpaper/
  # theme change, but only symlinks it to gtk.css when the "Apply GTK Themes"
  # toggle is on; keep the symlinks declarative so every GTK 3/4 app, including
  # Nautilus, always consumes the live palette.
  xdg.configFile."gtk-3.0/gtk.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css";
  xdg.configFile."gtk-4.0/gtk.css".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css";

  # GTK4/libadwaita apps (Nautilus, GNOME apps) only reload the theme when the
  # system color-scheme changes; enable the DMS refresh that round-trips the
  # scheme so running apps pick up the new matugen palette immediately.
  xdg.configFile."environment.d/90-dms.conf".text = ''
    DMS_ENABLE_GTK4_REFRESH=1
  '';

  # Nautilus (system or Flatpak) reads its GTK overrides from
  # ~/.var/app/org.gnome.Nautilus/config/gtk-{3,4}.0/gtk.css, which DMS never
  # touches; import the generated palette there as well so the Files app matches.
  xdg.configFile."var/app/org.gnome.Nautilus/config/gtk-3.0/gtk.css".text = ''
    @import url("file://${config.home.homeDirectory}/.config/gtk-3.0/dank-colors.css");
  '';
  xdg.configFile."var/app/org.gnome.Nautilus/config/gtk-4.0/gtk.css".text = ''
    @import url("file://${config.home.homeDirectory}/.config/gtk-4.0/dank-colors.css");
  '';

  # [config] is required by matugen (missing field otherwise, fatal parse error)
  xdg.configFile."matugen/config.toml".text = ''
    [config]

    [templates.zennotes]
    input_path = "${config.home.homeDirectory}/.config/matugen/templates/zennotes.css"
    output_path = "${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen/theme.css"
  '';

  # Initial palette generation at activation so the ZenNotes theme exists on first run;
  # subsequent regenerations are owned by the DMS matugen worker (dms matugen queue).
  home.activation.ensureDmsThemeDirs = lib.hm.dag.entryAfter [ "cloneWallpapers" ] ''
    ZN_THEME_DIR="${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen"
    FIREFOX_THEME_DIR="${config.home.homeDirectory}/.config/DankMaterialShell"
    $DRY_RUN_CMD mkdir -p "$ZN_THEME_DIR" "$FIREFOX_THEME_DIR"
    WALLPAPER="${config.home.homeDirectory}/Wallpapers/green7.png"
    # Do not invoke Matugen from Home Manager activation. The DMS theme
    # worker owns wallpaper-triggered generation and serializes its queue;
    # a second activation-time invocation can race it and report failures.
  '';

  # ZenNotes is installed as a Flatpak (org.zennotes.ZenNotes), whose
  # per-user config lives under ~/.var/app/org.zennotes.ZenNotes/config.
  # The manifest and generated CSS must share the exact same theme slug.
  home.file.".var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen/manifest.json".text = builtins.toJSON {
    name = "DMS Matugen";
    author = "DankMaterialShell";
    version = "1.0.0";
    description = "A dark ZenNotes theme generated from the active DMS palette.";
    modes = "dark";
    preview = { dark = "#1e1e2e"; };
  };

  # ZenNotes activation only selects the declaratively provisioned theme.
  # Matugen owns theme.css generation when DMS changes wallpaper or theme.
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

  # affinity-nix installs the desktop entries for Affinity v3 itself.

  # Desktop Entries
  xdg.desktopEntries.nvim = {
    name = "Neovim (NixVim)";
    genericName = "Editor";
    comment = "Edit text files";
    exec = "wezterm start -- nvim %F";
    terminal = false;
    icon = "nvim";
    type = "Application";
    mimeType = [
      "text/plain"
      "text/x-java"
      "text/x-csrc"
      "text/x-c++src"
      "text/x-python"
      "application/json"
      "text/html"
      "text/css"
      "application/javascript"
    ];
    categories = [ "Development" "Utility" "TextEditor" ];
  };

  # Mime & User Dirs
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "text/plain" = [ "nvim.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };

  # DMS session migration: remove the legacy unmanaged session.json
  # produced by the old bidirectional sync (dms-settings-sync systemd
  # service) so Home Manager can take ownership via xdg.stateFile.
  home.activation.migrateDmsSession = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    OLD_SESSION="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json"
    if [ -f "$OLD_SESSION" ] && [ ! -L "$OLD_SESSION" ]; then
      BACKUP="${config.home.homeDirectory}/.local/state/DankMaterialShell/session.json.legacy"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp -f "$OLD_SESSION" "$BACKUP"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$OLD_SESSION"
    fi
  '';

  # DMS — wallpaper cycling and plugin
  # The existing session.json may be a regular file from the legacy sync
  # service; force the declarative state file to replace it during activation.
  xdg.stateFile."DankMaterialShell/session.json".force = true;

  programs.dank-material-shell = {
    plugins.wallpaperCarousel = {
      enable = true;
      settings.wallpaperDirectory = "${config.home.homeDirectory}/Wallpapers";
    };
    session = {
      perMonitorWallpaper = false;
      perModeWallpaper = false;
      wallpaperCyclingEnabled = false;
      wallpaperTransition = "random";
      isLightMode = false;
      doNotDisturb = false;
      doNotDisturbUntil = 0;
      nightModeEnabled = false;
      nightModeTemperature = 4500;
      nightModeHighTemperature = 6500;
      nightModeAutoEnabled = false;
      nightModeAutoMode = "time";
      nightModeStartHour = 18;
      nightModeStartMinute = 0;
      nightModeEndHour = 6;
      nightModeEndMinute = 0;
      latitude = -23.599722;
      longitude = -46.791389;
      nightModeUseIPLocation = false;
      nightModeLocationProvider = "";
      themeModeAutoEnabled = false;
      themeModeAutoMode = "time";
      themeModeStartHour = 18;
      themeModeStartMinute = 0;
      themeModeEndHour = 6;
      themeModeEndMinute = 0;
      themeModeShareGammaSettings = true;
      weatherLocation = "Jardim João XXIII, São Paulo, SP, Brasil";
      weatherCoordinates = "-23.599722,-46.791389";
      weatherHourlyDetailed = true;
      showThirdPartyPlugins = false;
      pluginBrowserInstalledFirst = false;
      pluginBrowserSortMode = "default";
      launchPrefix = "";
      searchAppActions = true;
      locale = "pt_BR";
      timeLocale = "pt_BR";
      appOverrides = {
        "zen-beta" = {
          name = "Zen Browser";
        };
      };
    };
  };

  systemd.user.services.dms = {
    Unit = {
      After = [ "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Install.WantedBy = [ "niri.service" ];
  };

  systemd.user.services.dms-wallpaper-random-on-login = {
    Unit = {
      Description = "Select one random DMS wallpaper at graphical session start";
      After = [ "dms.service" "niri.service" ];
      PartOf = [ "niri.service" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=/run/current-system/sw/bin:${config.home.homeDirectory}/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin"
      ];
      ExecStart = randomDmsWallpaper;
    };
    Install.WantedBy = [ "niri.service" ];
  };

  # Restart DMS after the declarative session and wallpaper directory are ready.
  # Home Manager updates session.json but the already-running Quickshell process
  # does not necessarily reload it when only state-file contents change.
  home.activation.restartDms = lib.hm.dag.entryAfter [ "cloneWallpapers" ] ''
    if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet dms.service; then
      systemctl --user daemon-reload
      systemctl --user restart dms.service
    fi
  '';

  # Wallpapers
  home.activation.cloneWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WALLPAPERS_DIR="${config.home.homeDirectory}/Wallpapers"
    WALLPAPERS_REPO="https://github.com/Joaoferraz-byte/Wallpapers.git"

    if [ ! -d "$WALLPAPERS_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"
    else
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$WALLPAPERS_DIR" pull --ff-only || true
    fi
  '';

  # Vault (Obsidian)
  home.activation.cloneVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    VAULT_DIR="${config.home.homeDirectory}/Vault"
    VAULT_REPO="git@github.com:Joaoferraz-byte/Vault.git"

    if [ ! -d "$VAULT_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$VAULT_REPO" "$VAULT_DIR" || true
    fi
  '';

  services.git-sync = {
    enable = true;
    repositories = {
      vault = {
        path = "${config.home.homeDirectory}/Vault";
        uri = "git+ssh://git@github.com/Joaoferraz-byte/Vault.git";
        interval = 300;
      };
    };
  };
}
