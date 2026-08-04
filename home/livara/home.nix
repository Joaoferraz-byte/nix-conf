{
  config,
  pkgs,
  lib,
  inputs,
  self,
  ...
}:
let
  # ── Assets: usar caminhos relativos para o store ──
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
  };
  programs.home-manager.enable = true;

  # ── DankMaterialShell + Niri (via shell-conf) ─────────────────────────
  # A configuração detalhada está no flake shell-conf, que atua como wrapper.
  # As customizações visuais e atalhos já estão configurados lá.

  # ── Neovim (NixVim) ─────────────────────────────────────────────────────
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };
  home.packages = with pkgs; [
    manim
    nerd-fonts.jetbrains-mono
  ];
  home.file.".face.icon".source = profileIcon;
  home.file.".config/nixos/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/Wallpapers";
  # ── Tema de ícones GTK ───────────────────────────────────────────────────
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.kora-icon-theme;
      name = "kora";
    };
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
  };
  # ── Kitty: terminal ───────────────────────────────────────────────────────
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.9";
      dynamic_background_opacity = "yes";
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-livara";
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      hide_window_decorations = "titlebar-only";
      macos_option_as_alt = "yes";
      update_check_interval = 0;
      url_style = "hand";
      wayland_titlebar_color = "background";
    };
    extraConfig = ''
      # Clipboard integration
      map ctrl+c copy_to_clipboard
      map ctrl+v paste_from_clipboard
      # Open URLs with default browser
      map ctrl+shift+e open_url_with_default_browser
      # Font size
      map ctrl+plus change_font_size all +2.0
      map ctrl+minus change_font_size all -2.0
      map ctrl+backspace change_font_size all 0
    '';
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      xdg-terms = [ "kitty" ];
      icon-theme = "kora";
      gtk-theme = "adw-gtk3-dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
    };
  };
  xdg.desktopEntries.nvim = {
    name = "Neovim (NixVim)";
    genericName = "Editor";
    comment = "Edit text files";
    exec = "kitty -e nvim %F";
    terminal = true;
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
    categories = [
      "Development"
      "Utility"
      "TextEditor"
    ];
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake .#latitude";
    };
    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
      theme = "robbyrussell";
    };
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "text/plain" = [ "nvim.desktop" ];
      "text/x-java" = [ "nvim.desktop" ];
      "text/x-csrc" = [ "nvim.desktop" ];
      "text/x-c++src" = [ "nvim.desktop" ];
      "text/x-python" = [ "nvim.desktop" ];
      "application/json" = [ "nvim.desktop" ];
      "text/html" = [ "nvim.desktop" ];
      "text/css" = [ "nvim.desktop" ];
      "application/javascript" = [ "nvim.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
    };
  };
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    videos = "${config.home.homeDirectory}/Videos";
  };
}
