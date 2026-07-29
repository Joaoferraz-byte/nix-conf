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
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs self; };
        home-manager.backupFileExtension = "backup";
        # nixvim é importado como módulo compartilhado do Home Manager.
        # Isso faz com que `programs.nixvim.*` esteja disponível para
        # todos os usuários do home-manager sem precisar importar
        # separadamente em cada home.nix.
        home-manager.sharedModules = [
          inputs.nixvim.homeModules.nixvim
        ];
        home-manager.users.livara = import ../../../home/livara/home.nix;
      }
    ];
  };
}
