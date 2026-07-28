{ config, pkgs, ... }:

{

  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "26.11";

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs;
    [ python3Packages.manim nerd-fonts.jetbrains-mono
      self.packages.${pkgs.stdenv.hostPlatform.system}.myNeovim
    ];

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
        decorations = "none";
      };
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        size = 12.0;
      };
      colors = {
        primary = { background = "#0d1117"; foreground = "#b3b1ad"; };
        normal = {
          black = "#484f58"; red = "#ff7b72"; green = "#3fb950"; yellow = "#d29922";
          blue = "#58a6ff"; magenta = "#bc8cff"; cyan = "#39c5cf"; white = "#b1bac4";
        };
        bright = {
          black = "#6e7681"; red = "#ffa198"; green = "#56d364"; yellow = "#e3b341";
          blue = "#79c0ff"; magenta = "#d2a8ff"; cyan = "#56d4dd"; white = "#f0f6fc";
        };
      };
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
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
    };
  };

  # A entrada de desktop para Neovim agora é gerenciada pelo wrapper
  # xdg.desktopEntries.nvim = {
  #   name = "Neovim";
  #   genericName = "Editor de Texto";
  #   exec = "alacritty -e nvim %F";
  #   terminal = false;
  #   categories = [ "Utility" "TextEditor" ];
  #   mimeType = [ "text/plain" "text/x-java" ];
  # };

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

