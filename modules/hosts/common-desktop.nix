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

      config = {
        programs.dconf.enable = true;

        environment.sessionVariables = {
          HYPRLAND_CONFIG = "/home/${cfg.userName}/.config/hypr/hyprland.lua";
          XKB_DEFAULT_MODEL = "pc105";
          XKB_DEFAULT_RULES = "base";
          XKB_DEFAULT_LAYOUT = "br";
          XKB_DEFAULT_VARIANT = "abnt2";
          XKB_DEFAULT_OPTIONS = "";
        };

        services.xserver.xkb = {
          model = "pc105";
          layout = "br";
          # Explicitly select the `br(abnt2)` symbols instead of relying on
          # the layout's implicit default; this keeps every layer identical.
          variant = "abnt2";
          options = "";
        };

        # The console keymap is a separate layer from Hyprland/XKB.
        console.keyMap = "br-abnt2";

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
