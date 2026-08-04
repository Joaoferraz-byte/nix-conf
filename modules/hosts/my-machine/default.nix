{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          (final: prev: {
            gradience = prev.writeShellScriptBin "gradience" ''
              echo "gradience foi removido do nixpkgs; stub no-op." >&2
            '';
            gnome-icon-theme = prev.adwaita-icon-theme;
          })
        ];
      }
      self.nixosModules.myMachineConfiguration
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs self; };
        home-manager.backupFileExtension = "backup";
        home-manager.sharedModules = [
          inputs.nixvim.homeModules.nixvim
        ];
        home-manager.users.livara = import ../../../home/livara/home.nix;
      }
    ];
  };
}
