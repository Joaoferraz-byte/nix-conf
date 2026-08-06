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
    ZEN_PROFILE_DIR="${config.home.homeDirectory}/.config/zen/default"
    ZEN_CSS="${config.home.homeDirectory}/.config/DankMaterialShell/zen.css"
    USER_CHROME="$ZEN_PROFILE_DIR/chrome/userChrome.css"

    if [ -f "$ZEN_CSS" ]; then
      $DRY_RUN_CMD mkdir -p "$ZEN_PROFILE_DIR/chrome"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$ZEN_CSS" "$USER_CHROME"
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
  ];

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

    plugins.wallpaperCarousel.enable = true;
  };

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
