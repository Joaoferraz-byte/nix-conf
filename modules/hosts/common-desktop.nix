{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.hyprland
        self.nixosModules.niri
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
      ];

      options.desktop.profile.compositor = lib.mkOption {
        type = lib.types.enum [ "hyprland" "niri" ];
        default = "hyprland";
        description = "Wayland compositor/session used by the desktop profile.";
      };

      options.desktop.profile.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "Home Manager user that owns the desktop profile.";
      };

      options.desktop.profile.shellProfile = lib.mkOption {
        type = lib.types.enum [ "laptop" "desktop" ];
        default = "desktop";
        description = "Legacy capability profile retained for application adapters.";
      };

      options.desktop.profile.shellBackend = lib.mkOption {
        type = lib.types.enum [ "serpantinum" "noctalia" ];
        default = "noctalia";
        description = "Visible Wayland shell backend. Noctalia owns the UI; Serpantinum remains the Matugen adapter.";
      };

      options.desktop.profile.powerWidgetVariant = lib.mkOption {
        type = lib.types.enum [ "battery" "performance" ];
        default = "battery";
        description = "Power popup contract selected by the host profile.";
      };

      options.desktop.profile.tabletWidget = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Expose the drawing-tablet status tile in Serpantinum.";
      };

      options.desktop.profile.monitorProfile = lib.mkOption {
        type = lib.types.enum [ "latitude" "myMachine" ];
        default = "myMachine";
        description = "Named monitor policy consumed by the Home Manager adapter.";
      };

      options.desktop.profile.networkWidgets = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Expose network widgets in the Serpantinum profile.";
      };

      options.desktop.profile.bluetoothWidgets = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Expose Bluetooth widgets in the Serpantinum profile.";
      };

      options.desktop.profile.keyboardLayout = lib.mkOption {
        type = lib.types.str;
        default = "br";
        description = "Global fallback XKB layout for the built-in keyboard.";
      };

      options.desktop.profile.keyboardVariant = lib.mkOption {
        type = lib.types.str;
        default = "abnt2";
        description = "Global fallback XKB variant for the built-in keyboard.";
      };

      options.desktop.profile.consoleKeyMap = lib.mkOption {
        type = lib.types.str;
        default = "br-abnt2";
        description = "Linux console keymap matching the built-in keyboard.";
      };

      options.desktop.profile.internalKeyboardDevice = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Stable libinput/keyd name for the built-in keyboard.";
      };

      options.desktop.profile.externalKeyboardDevices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Stable device names receiving the external keyboard layout.";
      };

      options.desktop.profile.externalKeyboardLayout = lib.mkOption {
        type = lib.types.str;
        default = "br";
        description = "XKB layout for configured external keyboards.";
      };

      options.desktop.profile.externalKeyboardVariant = lib.mkOption {
        type = lib.types.str;
        default = "abnt2";
        description = "XKB variant for configured external keyboards.";
      };

      config = {
        programs.dconf.enable = true;

        environment.sessionVariables = {
          SERPANTINUM_COMPOSITOR = cfg.compositor;
          HYPRLAND_CONFIG = "/home/${cfg.userName}/.config/hypr/hyprland.lua";
          XKB_DEFAULT_MODEL = "pc105";
          XKB_DEFAULT_RULES = "evdev";
          XKB_DEFAULT_LAYOUT = cfg.keyboardLayout;
          XKB_DEFAULT_VARIANT = cfg.keyboardVariant;
          XKB_DEFAULT_OPTIONS = "";
          GTK_ICON_THEME = "Kora";
          QT_ICON_THEME = "Kora";
        };

        services.xserver.xkb = {
          model = "pc105";
          layout = cfg.keyboardLayout;
          variant = cfg.keyboardVariant;
          options = "";
        };

        # The console keymap is a separate layer from Hyprland/XKB.
        console.keyMap = cfg.consoleKeyMap;

        services.displayManager.defaultSession = lib.mkForce (
          if cfg.compositor == "niri" then "niri" else "hyprland-uwsm"
        );

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs self;
            userName = cfg.userName;
            desktopProfile = cfg;
            compositor = cfg.compositor;
            powerWidgetVariant = cfg.powerWidgetVariant;
            tabletWidget = cfg.tabletWidget;
            shellBackend = cfg.shellBackend;
          };
          sharedModules = [
            inputs.stylix.homeModules.stylix
            inputs.shell-conf.homeManagerModules.default
            inputs.noctalia.homeModules.default
            inputs.nixvim.homeModules.nixvim
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
