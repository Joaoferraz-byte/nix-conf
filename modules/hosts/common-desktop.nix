{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.appimage
        self.nixosModules.firejail
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
        description = "Global XKB layout applied by niri to every keyboard device.";
      };

      options.desktop.profile.keyboardVariant = lib.mkOption {
        type = lib.types.str;
        default = "abnt2";
        description = "Global XKB variant applied by niri to every keyboard device.";
      };

      options.desktop.profile.consoleKeyMap = lib.mkOption {
        type = lib.types.str;
        default = "br-abnt2";
        description = "Linux console keymap matching the built-in keyboard.";
      };


      config = {
        programs.dconf.enable = true;

        environment.sessionVariables = {
          XKB_DEFAULT_MODEL = "pc105";
          XKB_DEFAULT_RULES = "evdev";
          XKB_DEFAULT_LAYOUT = cfg.keyboardLayout;
          XKB_DEFAULT_VARIANT = cfg.keyboardVariant;
          XKB_DEFAULT_OPTIONS = "";
          GTK_ICON_THEME = "Livara-Kora";
          QT_ICON_THEME = "Livara-Kora";
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
          # DMS mutates its persistent session.json at runtime. Keep one
          # rolling Home Manager backup and replace that backup atomically on
          # later activations instead of aborting when .backup already exists.
          backupFileExtension = "backup";
          overwriteBackup = true;
          extraSpecialArgs = {
            inherit inputs self;
            userName = cfg.userName;
            desktopProfile = cfg;
          };
          sharedModules = [
            inputs.stylix.homeModules.stylix
            inputs.dms.homeModules.dank-material-shell
            inputs.shell-conf.homeModules.default
            inputs.nixvim.homeModules.nixvim
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
