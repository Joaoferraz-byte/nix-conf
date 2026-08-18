{ self, inputs, ... }:
{
  imports = [
    ./configuration.nix
    ./hardware.nix
  ];

  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      {
        # This host is named `limine` at the network layer, but its desktop
        # profile is explicitly `myMachine`; consumers must not infer this
        # identity from networking.hostName.
        desktop.profile.compositor = "hyprland";
        desktop.profile.shellProfile = "desktop";
        desktop.profile.monitorProfile = "myMachine";
        desktop.profile.networkWidgets = true;
        desktop.profile.bluetoothWidgets = false;
        desktop.profile.powerWidgetVariant = "performance";
        desktop.profile.tabletWidget = true;

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
      self.nixosModules.virtualization
      self.nixosModules.myMachineConfiguration
      inputs.mesa-tomate-driver.nixosModules.default
    ];
  };
}
