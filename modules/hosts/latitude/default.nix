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
        # The built-in Latitude keyboard is Irish; the external Aitek
        # receives its own br(abnt2) Hyprland override from Home Manager.
        desktop.profile.keyboardLayout = "ie";
        desktop.profile.keyboardVariant = "";
        desktop.profile.consoleKeyMap = "ie";

        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
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
      self.nixosModules.development
      self.nixosModules.developmentEmbedded
      self.nixosModules.containers
      self.nixosModules.latitudeConfiguration
    ];
  };
}
