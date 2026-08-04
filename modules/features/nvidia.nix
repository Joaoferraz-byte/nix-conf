{ self, ... }: {
  flake.nixosModules.nvidia = { config, lib, pkgs, ... }: {
    hardware.enableRedistributableFirmware = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    boot.kernelModules = [
      "nvidia"
      "nvidia_modeset"
    ];
    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      modesetting.enable = true;
      open = false;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
    };

    # Wayland/Niri environment variables for NVIDIA
    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
