{ config, pkgs, self, ... }:

{
  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "26.11";

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
  };

  programs.home-manager.enable = true;

  # ── Neovim (NixVim) ─────────────────────────────────────────────────────
  # NixVim é configurado como módulo do Home Manager usando o flake separado.
  programs.nixvim = {
    enable = true;
    imports = [ self.inputs.nixvim-config.nixvimModule ];
  };

  home.packages = with pkgs; [
    manim
    nerd-fonts.jetbrains-mono
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 10; y = 10; };
        dynamic_padding = true;
        decorations = "none";
        opacity = 1.0;
      };
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        size = 12.0;
      };
      colors = {
        primary = { background = "#010409"; foreground = "#c9d1d9"; };
        cursor = { text = "#0d1117"; cursor = "#58a6ff"; };
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

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake .#myMachine";
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
