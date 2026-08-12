{ self, inputs, ... }:
{
  imports = [
    ./configuration.nix
    ./hardware.nix
  ];

  flake.nixosConfigurations.latitude = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          inputs.shell-conf.overlays.niri
          inputs.affinity-nix.overlays.default
          (final: prev: {
            libdisplay-info_0_2 = final.libdisplay-info;
            gradience = prev.writeShellScriptBin "gradience" ''
              echo "gradience was removed from nixpkgs; using a no-op compatibility command." >&2
            '';
          })
        ];
      }
      self.nixosModules.commonDesktop
      self.nixosModules.latitudeConfiguration
    ];
  };
}
