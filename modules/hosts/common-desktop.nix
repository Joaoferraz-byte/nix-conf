{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.hyprland
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
      ];

      options.desktop.profile.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "Home Manager user that owns the desktop profile.";
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

      config = {
        programs.dconf.enable = true;

        environment.sessionVariables = {
          HYPRLAND_CONFIG = "/home/${cfg.userName}/.config/hypr/hyprland.lua";
          XKB_DEFAULT_MODEL = "pc105";
          XKB_DEFAULT_RULES = "evdev";
          XKB_DEFAULT_LAYOUT = cfg.keyboardLayout;
          XKB_DEFAULT_VARIANT = cfg.keyboardVariant;
          XKB_DEFAULT_OPTIONS = "";
        };

        services.xserver.xkb = {
          model = "pc105";
          layout = cfg.keyboardLayout;
          variant = cfg.keyboardVariant;
          options = "";
        };

        # The console keymap is a separate layer from Hyprland/XKB.
        console.keyMap = cfg.consoleKeyMap;

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs self;
            userName = cfg.userName;
            hostName = config.networking.hostName;
          };
          sharedModules = [
            inputs.stylix.homeModules.stylix
            inputs.shell-conf.homeManagerModules.default
            inputs.nixvim.homeModules.nixvim
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
