{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
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
      self.nixosModules.myMachineConfiguration
      inputs.mesa-tomate-driver.nixosModules.default
      self.nixosModules.niri
      # The upstream DMS NixOS module is intentionally NOT imported: it
      # declares systemd.enable options in both its NixOS and Home Manager
      # modules, which cannot be enabled together on one machine. The
      # system-level pieces it used to provide are re-declared in
      # dms-system.nix; the user-level pieces come from the shell-conf
      # Home Manager module imported in home.nix.
      self.nixosModules.dmsSystem
      inputs.dms-plugin-registry.nixosModules.default
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
