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
        desktop.profile.compositor = "niri";
        desktop.profile.monitorProfile = "myMachine";

        nixpkgs.config.allowUnfree = true;
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
