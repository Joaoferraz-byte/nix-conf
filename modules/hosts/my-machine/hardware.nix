{ ... }:
{
  flake.nixosModules.myMachineHardware = { config, lib, ... }:
    {
      imports = [ ./hardware-configuration.nix ];
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
