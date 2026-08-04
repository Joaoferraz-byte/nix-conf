{
  config,
  pkgs,
  lib,
  inputs,
  self,
  ...
}:
let
  # Assets
  iconsPath = builtins.path {
    path = ../../Icons;
    name = "nix-conf-icons";
  };
  profileIcon = iconsPath + "/6afde16e1ef1cb3257b30e01890787dd.jpg";
in
{
  imports = [
    inputs.shell-conf.homeManagerModules.default
  ];

  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "26.11";
  
  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
    TERMINAL = "wezterm";
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  # Neovim (NixVim via vim-conf)
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };

  home.packages = with pkgs; [
    manim
    nerd-fonts.jetbrains-mono
    wezterm
  ];

  home.file.".face.icon".source = profileIcon;
  home.file.".config/nixos/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/Wallpapers";

  # Desktop entries
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

  # Shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      # Update alias
      update = "sudo nixos-rebuild switch --flake .";
    };
    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "robbyrussell"; # Catppuccin Mocha theme for OMZ could be added later
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
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
}
