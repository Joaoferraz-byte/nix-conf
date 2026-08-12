{ self, inputs, ... }:
{
  flake.nixosModules.commonDesktop = { config, lib, ... }:
    let
      cfg = config.desktop.profile;
    in
    {
      imports = [
        self.nixosModules.dmsSystem
        self.nixosModules.niri
        inputs.dms-plugin-registry.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
      ];

      options.desktop.profile.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "Home Manager user that owns the desktop profile.";
      };

      config = {
        services.dank-material-shell.userName = cfg.userName;

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs self;
            userName = cfg.userName;
          };
          sharedModules = [
            inputs.shell-conf.homeManagerModules.dms
            inputs.shell-conf.homeManagerModules.desktopPolicy
            inputs.shell-conf.homeManagerModules.niriPolicy
            inputs.nixvim.homeModules.nixvim
          ];
          users.${cfg.userName} = import ../../home/livara/home.nix;
        };
      };
    };
}
