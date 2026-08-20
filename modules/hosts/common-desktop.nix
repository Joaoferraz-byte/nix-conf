{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.niri
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
      ];

      options.desktop.profile.compositor = lib.mkOption {
        type = lib.types.enum [ "niri" ];
        default = "niri";
        description = "Wayland compositor/session used by the desktop profile.";
      };

      options.desktop.profile.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "Home Manager user that owns the desktop profile.";
      };

      options.desktop.profile.monitorProfile = lib.mkOption {
        type = lib.types.enum [ "latitude" "myMachine" ];
        default = "myMachine";
        description = "Named monitor policy consumed by the Home Manager adapter.";
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

        # The console keymap is separate from the niri/XKB session layer.
        console.keyMap = cfg.consoleKeyMap;

        services.displayManager.defaultSession = lib.mkForce "niri";

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs self;
            userName = cfg.userName;
            desktopProfile = cfg;
          };
          sharedModules = [
            inputs.stylix.homeModules.stylix
            inputs.dms.homeModules.dank-material-shell
            inputs.shell-conf.homeManagerModules.default
            inputs.nixMonitor.homeManagerModules.default
            inputs.nixvim.homeModules.nixvim
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
