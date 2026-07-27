{ self, inputs, ... }: {
  flake.nixosModules.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };

    environment.systemPackages = with pkgs; [
      grim
      slurp
      wl-clipboard
      brightnessctl
      bibata-cursors
      xwayland-satellite
    ];
  };

  perSystem = { pkgs, lib, self', ... }: {
    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      
      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.myNoctalia)
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        input = {
          keyboard.xkb.layout = "br";
          touchpad = {
            tap = true;
            natural-scroll = true;
          };
        };

        layout = {
          gaps = 14;
          center-focused-column = "never";
          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];

          border = {
            width = 0.5;
            active-color = "rgba(255, 255, 255, 0.5)";
            inactive-color = "rgba(128, 128, 128, 0.3)";
          };

          default-column-width = { proportion = 0.5; };

          focus-ring = {
            width = 1;
            active-color = "#7fc8ff";
            inactive-color = "#505050";
          };
        };

        cursor = {
          xcursor-theme = "Bibata-Modern-Classic";
          xcursor-size = 24;
          hide-when-typing = true;
          hide-after-inactive-ms = 3000;
        };

        window-rules = [
          {
            geometry-corner-radius = 12;
            clip-to-geometry = true;
            opacity = 0.80;
            draw-border-with-background = true;
          }
        ];

        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;

        binds = {
          "Mod+Return".spawn = [ (lib.getExe pkgs.alacritty) ];
          "Mod+S".spawn = [ (lib.getExe self'.packages.myNoctalia) "ipc" "call" "launcher" "toggle" ];
          "Mod+O".spawn = [ (lib.getExe pkgs.obsidian) ];
          "Mod+W".spawn = [ (lib.getExe pkgs.brave) ];
          "Mod+E".spawn = [ (lib.getExe pkgs.nautilus) ];
          "Mod+D".spawn = [ (lib.getExe pkgs.vesktop) ];

          "Mod+Q".close-window = _: { };
          "Mod+F".maximize-column = _: { };
          "Mod+Shift+F".fullscreen-window = _: { };
          "Mod+V".toggle-window-floating = _: { };
          "Mod+Comma".consume-window-into-column = _: { };
          "Mod+Period".expel-window-from-column = _: { };

          "Mod+Left".focus-column-left = _: { };
          "Mod+Right".focus-column-right = _: { };
          "Mod+Up".focus-window-up = _: { };
          "Mod+Down".focus-window-down = _: { };

          "Mod+Shift+Left".move-column-left = _: { };
          "Mod+Shift+Right".move-column-right = _: { };
          "Mod+Shift+Up".move-window-up = _: { };
          "Mod+Shift+Down".move-window-down = _: { };

          "Mod+R".switch-preset-column-width = _: { };
          "Mod+Minus".set-column-width = "-10%";
          "Mod+Equal".set-column-width = "+10%";

          "Mod+1".focus-workspace = 1;
          "Mod+2".focus-workspace = 2;
          "Mod+3".focus-workspace = 3;
          "Mod+4".focus-workspace = 4;
          "Mod+Shift+1".move-column-to-workspace = 1;
          "Mod+Shift+2".move-column-to-workspace = 2;
          "Mod+Shift+3".move-column-to-workspace = 3;
          "Mod+Shift+4".move-column-to-workspace = 4;
          "Mod+Page_Down".focus-workspace-down = _: { };
          "Mod+Page_Up".focus-workspace-up = _: { };

          "Print".screenshot = _: { };
          "Mod+Print".screenshot-window = _: { };

          "XF86AudioRaiseVolume".spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ];
          "XF86AudioLowerVolume".spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
          "XF86AudioMute".spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
          "XF86MonBrightnessUp".spawn = [ "brightnessctl" "set" "+5%" ];
          "XF86MonBrightnessDown".spawn = [ "brightnessctl" "set" "5%-" ];

          "Mod+Shift+E".quit = _: { };
        };
      };
    };
  };
}
