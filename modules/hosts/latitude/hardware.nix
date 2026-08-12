{ ... }:
{
  flake.nixosModules.latitudeHardware = { lib, ... }:
    let
      generatedHardware = builtins.readFile ./hardware-configuration.nix;
      hasPlaceholder = lib.any (needle: lib.hasInfix needle generatedHardware) [
        "BOOT-PARTUUID"
        "CHANGE_ME"
        "PARTUUID_HERE"
        "UUID_HERE"
      ];
    in
    {
      assertions = [
        {
          assertion = !hasPlaceholder;
          message = "Latitude hardware-configuration.nix still contains a placeholder. Run scripts/recover-latitude-boot.sh on the target machine before rebuilding.";
        }
      ];

      imports = [ ./hardware-configuration.nix ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
}
