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
  # ─── Imports ────────────────────────────────────────────────────────────────
  imports = [
    inputs.shell-conf.homeManagerModules.default
    inputs.zen-browser.homeModules.beta
  ];

  # ─── Home Profile ───────────────────────────────────────────────────────────
  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "26.11";

  # ─── Environment Variables ──────────────────────────────────────────────────
  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  # ─── Avatar ─────────────────────────────────────────────────────────────────
  home.file.".face.icon".source = profileIcon;

  # ─── Programs ───────────────────────────────────────────────────────────────

  # Neovim
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };

  # Zen Browser
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

  # ─── Packages ───────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    manim
    nerd-fonts.jetbrains-mono
    git
  ];

  # ─── Desktop Entries ────────────────────────────────────────────────────────
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

  # ─── Mime & User Dirs ───────────────────────────────────────────────────────
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

  # ─── Git Repositories ───────────────────────────────────────────────────────

  # Wallpapers — cloned/updated on each home-manager activation
  home.activation.cloneWallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    WALLPAPERS_DIR="${config.home.homeDirectory}/Wallpapers"
    WALLPAPERS_REPO="https://github.com/Joaoferraz-byte/Wallpapers.git"

    if [ ! -d "$WALLPAPERS_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"
    else
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$WALLPAPERS_DIR" pull --ff-only || true
    fi
  '';

  # Vault (Obsidian) — clone + git-sync for bidirectional sync
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
