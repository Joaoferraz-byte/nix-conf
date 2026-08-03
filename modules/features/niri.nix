{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, config, ... }: {
    programs.niri.enable = true;

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      swaybg
      waybar
      fuzzel
      kitty
      dunst
      libnotify
    ];
  };

  flake.homeManagerModules.niri = { pkgs, lib, config, ... }: {
    programs.niri = {
      enable = true;
      settings = {
        input = {
          keyboard.xkb.layout = "br";
          touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
          };
        };

        layout = {
          gaps = 8;
          focus-ring = {
            enable = true;
            width = 2;
            active.color = "#7aa2f7";
            inactive.color = "#414868";
          };
        };

        # Window management
          "Mod+Q" = close-window;
          "Mod+Left" = focus-column-left;
          "Mod+Right" = focus-column-right;
          "Mod+Up" = focus-window-up;
          "Mod+Down" = focus-window-down;
          
          "Mod+Shift+Left" = move-column-left;
          "Mod+Shift+Right" = move-column-right;
          
          "Mod+1" = focus-workspace 1;
          "Mod+2" = focus-workspace 2;
          "Mod+3" = focus-workspace 3;
          "Mod+4" = focus-workspace 4;
          "Mod+5" = focus-workspace 5;
          "Mod+6" = focus-workspace 6;
          "Mod+7" = focus-workspace 7;
          "Mod+8" = focus-workspace 8;
          "Mod+9" = focus-workspace 9;
          
          "Mod+Shift+1" = move-column-to-workspace 1;
          "Mod+Shift+2" = move-column-to-workspace 2;
          "Mod+Shift+3" = move-column-to-workspace 3;
          "Mod+Shift+4" = move-column-to-workspace 4;
          "Mod+Shift+5" = move-column-to-workspace 5;
          "Mod+Shift+6" = move-column-to-workspace 6;
          "Mod+Shift+7" = move-column-to-workspace 7;
          "Mod+Shift+8" = move-column-to-workspace 8;
          "Mod+Shift+9" = move-column-to-workspace 9;
        };
        
        spawn-at-startup = [
          { command = [ "xwayland-satellite" ":0" ]; }
          { command = [ "swaybg" "-i" "${config.home.homeDirectory}/.config/nixos/Wallpapers/wallhaven-83qwky.png" "-m" "fill" ]; }
        ];
      };
    };
  };
}
