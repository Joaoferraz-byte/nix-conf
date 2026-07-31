{ config, pkgs, lib, inputs, self, ... }:

let
  profileIcon = self.outPath + "/Icons/6afde16e1ef1cb3257b30e01890787dd.jpg";
in
{
  home.username = "livara";
  home.homeDirectory = "/home/livara";
  home.stateVersion = "26.11";

  home.sessionVariables = {
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
  };

  programs.home-manager.enable = true;

  # ── Neovim (NixVim) ─────────────────────────────────────────────────────
  # O módulo de configuração vem do flake reutilizável vim-conf; a interface
  # `programs.nixvim` é fornecida pelo módulo oficial compartilhado no host.
  programs.nixvim = {
    enable = true;
    imports = [ inputs.vim-conf.lib.nixvimModule ];
  };

  home.packages = with pkgs; [
    manim
    nerd-fonts.jetbrains-mono
    # Tema de ícones para o Ambxst (launcher e barra)
    # O Ambxst usa QS_ICON_THEME para encontrar ícones de apps.
    # O Papirus-Dark oferece cobertura ampla e visual consistente.
    papirus-icon-theme
  ];

  # O Ambxst-X lê ~/.face.icon. O greeter declara o mesmo ativo em
  # programs.silentSDDM.profileIcons.livara, evitando cópias divergentes.
  home.file.".face.icon".source = profileIcon;

  # ── Tema de ícones GTK ───────────────────────────────────────────────────
  # Define o tema de ícones para o sistema GTK e para o Ambxst.
  # O wrapper do Ambxst lê o tema via gsettings e exporta QS_ICON_THEME.
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
  };

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

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      xdg-terms = [ "alacritty" ];
      # Tema de ícones: lido pelo wrapper do Ambxst via gsettings
      # para definir QS_ICON_THEME corretamente
      icon-theme = "Papirus-Dark";
      gtk-theme = "adw-gtk3-dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
    };
  };

  xdg.desktopEntries.nvim = {
    name = "Neovim (NixVim)";
    genericName = "Editor";
    comment = "Edit text files";
    exec = "alacritty -e nvim %F";
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
    categories = [ "Development" "Utility" "TextEditor" ];
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
