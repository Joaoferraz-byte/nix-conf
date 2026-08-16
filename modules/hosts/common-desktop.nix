{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.hyprland
        inputs.home-manager.nixosModules.home-manager
      ];

      options.desktop.profile.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "Home Manager user that owns the desktop profile.";
      };

      config = {
        environment.sessionVariables = {
          HYPRLAND_CONFIG = "/home/${cfg.userName}/.config/hypr/hyprland.lua";
          XKB_DEFAULT_LAYOUT = "br";
          XKB_DEFAULT_VARIANT = "abnt2";
          XKB_DEFAULT_OPTIONS = "";
        };

        services.xserver.xkb = {
          layout = "br";
          variant = "abnt2";
          options = "";
        };

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
            inputs.shell-conf.homeManagerModules.default
            inputs.nixvim.homeModules.nixvim
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
