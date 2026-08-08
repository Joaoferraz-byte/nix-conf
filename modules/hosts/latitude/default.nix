{ self, inputs, ... }:

{
  flake.nixosConfigurations.latitude = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs self;
    };

    modules = [
      {
        nixpkgs.config.allowUnfree = true;

        nixpkgs.overlays = [
          inputs.shell-conf.inputs.niri.overlays.niri
          (final: prev: {
            libdisplay-info_0_2 = final.libdisplay-info;
            gradience = prev.writeShellScriptBin "gradience" ''
              echo "gradience foi removido do nixpkgs; stub no-op." >&2
            '';
          })
        ];
      }

      self.nixosModules.latitudeConfiguration
      self.nixosModules.dmsSystem
      self.nixosModules.niri
      inputs.dms-plugin-registry.nixosModules.default
      inputs.home-manager.nixosModules.home-manager

      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.extraSpecialArgs = {
          inherit inputs self;
        };

        home-manager.backupFileExtension = "backup";

        home-manager.sharedModules = [
          inputs.nixvim.homeModules.nixvim
        ];

        home-manager.users.livara = import ../../../home/livara/home.nix;
      }
    ];
  };
}
