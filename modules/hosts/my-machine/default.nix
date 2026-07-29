{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      {
        nixpkgs.config.allowUnfree = true;
      }
      self.nixosModules.myMachineConfiguration
      inputs.home-manager.nixosModules.home-manager
      inputs.nixvim.homeModules.nixvim
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs self; };
        home-manager.backupFileExtension = "backup";
        home-manager.users.livara = import ../../../home/livara/home.nix;
      }
    ];
  };
}
