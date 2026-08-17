{ pkgs, ... }:
{
  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 10;
        terminal = 11;
        popups = 10;
        desktop = 10;
      };
    };

    opacity = {
      applications = 0.96;
      desktop = 1.0;
      popups = 0.96;
      terminal = 0.92;
    };

    targets = {
      gtk = {
        enable = true;
        flatpakSupport.enable = true;
      };
      qt = {
        enable = true;
        platform = "qtct";
        standardDialogs = "default";
      };
      wezterm.enable = true;
      neovim = {
        enable = true;
        transparentBackground = {
          main = true;
          signColumn = true;
          numberLine = true;
        };
      };
      nixvim = {
        enable = true;
        transparentBackground = {
          main = true;
          signColumn = true;
          numberLine = true;
        };
      };
      zen-browser = {
        enable = true;
        profileNames = [ "default" ];
        enableCss = true;
      };
    };
  };
}
