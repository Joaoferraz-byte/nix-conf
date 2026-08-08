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
in
{
  # Imports
  imports = [
    # inputs.dms-plugin-registry.homeModules.default  # removed: conflicts with shell-conf HM module (double systemd.enable declaration)
    inputs.shell-conf.homeManagerModules.default
    inputs.zen-browser.homeModules.beta
    # niri-flake Home Manager module — required by the shell-conf niri
    # module (programs.niri.settings options) imported transitively above.
    inputs.niri.homeModules.niri
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
  home.activation.linkZenTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ZEN_BASE="${config.home.homeDirectory}/.config/zen"
    ZEN_CSS="${config.home.homeDirectory}/.config/DankMaterialShell/zen.css"

    if [ -f "$ZEN_CSS" ]; then
      # Profile directories carry a random suffix (e.g. "default-abc123"), so
      # we locate every profile dir instead of hardcoding a single path.
      for profile in $(find "$ZEN_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null); do
        $DRY_RUN_CMD mkdir -p "$profile/chrome"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$ZEN_CSS" "$profile/chrome/userChrome.css"
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
  xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard {
        xkb {
          layout "br"
        }
      }
      touchpad {
        tap
        dwt
        natural-scroll
      }
    }

    spawn-at-startup "xwayland-satellite" ":0"
    spawn-at-startup "swaybg" "-i" "${config.home.homeDirectory}/.config/nixos/Wallpapers/wallhaven-83qwky.png" "-m" "fill"
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
  ];

  # ZenNotes — adaptive theme via matugen
  # Matugen generates the theme.css at runtime from the template.
  xdg.configFile."matugen/templates/zennotes.css".text = ''
    :root {
      --z-background: {{ colors.surface.dark.red }} {{ colors.surface.dark.green }} {{ colors.surface.dark.blue }};
      --z-surface: {{ colors.surface_variant.dark.red }} {{ colors.surface_variant.dark.green }} {{ colors.surface_variant.dark.blue }};
      --z-primary: {{ colors.primary.dark.red }} {{ colors.primary.dark.green }} {{ colors.primary.dark.blue }};
      --z-on-primary: {{ colors.on_primary.dark.red }} {{ colors.on_primary.dark.green }} {{ colors.on_primary.dark.blue }};
      --z-secondary: {{ colors.secondary.dark.red }} {{ colors.secondary.dark.green }} {{ colors.secondary.dark.blue }};
      --z-text: {{ colors.on_surface.dark.red }} {{ colors.on_surface.dark.green }} {{ colors.on_surface.dark.blue }};
      --z-text-muted: {{ colors.on_surface_variant.dark.red }} {{ colors.on_surface_variant.dark.green }} {{ colors.on_surface_variant.dark.blue }};
    }
  '';

  # ZenNotes is installed as a Flatpak (org.zennotes.ZenNotes), whose
  # per-user config lives under ~/.var/app/org.zennotes.ZenNotes/config —
  # the previous manifest written to ~/.config/zennotes/ was silently
  # ignored by the Flatpak build.
  # NOTE: home.file (not xdg.configFile) is required here — xdg.configFile
  # would place the manifest under ~/.config/var/app/..., which ZenNotes
  # never reads. The Flatpak data dir ~/.var/app/... must be addressed
  # with an absolute path.
  home.file.".var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen/manifest.json".text = builtins.toJSON {
    name = "DMS Matugen";
    slug = "dms-matugen";
    version = "1.0.0";
    modes = ["dark"];
  };

  # ZenNotes activation: set the themeId in the Flatpak config.toml and
  # register the matugen template. Paths must target the Flatpak runtime
  # data directory and use absolute (no tilde) matugen input/output
  # paths — matugen does not expand '~'.
  home.activation.configureZenNotes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZN_DIR="${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes"
    ZN_CONFIG="${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/config.toml"
    MATUGEN_CONFIG="${config.home.homeDirectory}/.config/matugen/config.toml"

    $DRY_RUN_CMD mkdir -p "$ZN_DIR/themes/dms-matugen"

    # Set ZenNotes theme
    if [ -f "$ZN_CONFIG" ]; then
      if ! grep -q 'themeId = "custom-dms-matugen"' "$ZN_CONFIG"; then
        $DRY_RUN_CMD sed -i 's/^themeId = .*/themeId = "custom-dms-matugen"/' "$ZN_CONFIG"
      fi
    else
      $DRY_RUN_CMD mkdir -p "$(dirname "$ZN_CONFIG")"
      $DRY_RUN_CMD echo '[appearance]' > "$ZN_CONFIG"
      $DRY_RUN_CMD echo 'themeId = "custom-dms-matugen"' >> "$ZN_CONFIG"
    fi

    # Add ZenNotes template to Matugen config if not present
    if [ -f "$MATUGEN_CONFIG" ]; then
      if ! grep -q '\[templates.zennotes\]' "$MATUGEN_CONFIG"; then
        $DRY_RUN_CMD cat >> "$MATUGEN_CONFIG" <<EOF

[templates.zennotes]
input_path = '${config.home.homeDirectory}/.config/matugen/templates/zennotes.css'
output_path = '${config.home.homeDirectory}/.var/app/org.zennotes.ZenNotes/config/zennotes/themes/dms-matugen/theme.css'
EOF
      fi
    fi
  '';

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
    session = {
      wallpaperPath = "${config.home.homeDirectory}/Wallpapers/green7.png";
      perMonitorWallpaper = false;
      perModeWallpaper = false;
      wallpaperCyclingEnabled = true;
      wallpaperCyclingMode = "interval";
      wallpaperCyclingInterval = 900;
      wallpaperTransition = "random";
    };
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
