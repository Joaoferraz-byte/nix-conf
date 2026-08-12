{ ... }:
{
  flake.nixosModules.latitudeHardware = { ... }:
    {
      imports = [ ./hardware-configuration.nix ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
}
