{
  flake.nixosModules.developmentEmbedded = { config, lib, pkgs, ... }:
    let
      cfg = config.development;
    in
    {
      options.development.userName = lib.mkOption {
        type = lib.types.str;
        default = "livara";
        description = "User that owns embedded-development access.";
      };

      config = {
        users.groups.plugdev = { };

        environment.systemPackages = with pkgs; [
          # Expose arm-none-eabi-gcc and the companion binutils/GDB commands
          # to the login shell for Cortex-M/R firmware work.
          gcc-arm-embedded
          arduino-cli
          avrdude
          dfu-util
          minicom
          openocd
          picocom
          platformio
          probe-rs-tools
          stlink
          usbutils
        ];

        services.udev.packages = [
          pkgs.openocd
          pkgs.platformio
        ];

        users.users.${cfg.userName}.extraGroups = lib.mkAfter [
          "dialout"
          "plugdev"
        ];
      };
    };
}
