# ─── Dell Latitude 5410: NixOS Configuration Entry Point ─────────────────
# Constrói a configuração completa da máquina.
# O hardware.nix contém UUIDs gerados pelo nixos-generate-config.
{ self, inputs, ... }: {
  flake.nixosConfigurations.dellLatitude5410 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      {
        nixpkgs.config.allowUnfree = true;
      }
      self.nixosModules.dellLatitude5410Configuration
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs self; };
        home-manager.backupFileExtension = "backup";
        # Módulos Home Manager compartilhados entre hosts.
        # NixVim: configuração declarativa do editor (via vim-conf).
        # Hyprland: configuração do compositor (keybinds, monitor, etc.).
        home-manager.sharedModules = [
          inputs.nixvim.homeModules.nixvim
          self.homeManagerModules.niri
        ];
        home-manager.users.livara = import ../../../home/livara/home.nix;
      }
    ];
  };
}
