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
        # The built-in Latitude keyboard is Irish; configured external
        # devices receive the Brazilian ABNT2 layout at the niri input layer.
        desktop.profile.keyboardLayout = "ie";
        desktop.profile.keyboardVariant = "";
        desktop.profile.consoleKeyMap = "ie";
        desktop.profile.monitorProfile = "latitude";

        nixpkgs.config.allowUnfree = true;
      }
      self.nixosModules.commonDesktop
      self.nixosModules.development
      self.nixosModules.developmentEmbedded
      self.nixosModules.containers
      self.nixosModules.latitudeConfiguration
    ];
  };
}
