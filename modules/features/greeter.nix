{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, lib, ... }:
    let
      clockworkTheme = pkgs.stdenv.mkDerivation {
        name = "clockwork-sddm-theme";
        src = ../../themes/clockwork;
        installPhase = ''
          mkdir -p $out/share/sddm/themes/clockwork
          cp -aR $src/* $out/share/sddm/themes/clockwork/
        '';
      };
      sddmDependencies = with pkgs.kdePackages; [
        qt5compat
        qtdeclarative
        qtmultimedia
        qtsvg
        qtvirtualkeyboard
      ];
    in {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        theme = "clockwork";
        extraPackages = sddmDependencies;
        settings = {
          Theme = {
            CursorTheme = "Bibata-Modern-Classic";
          };
        };
      };
      services.displayManager.defaultSession = lib.mkForce "hyprland-uwsm";

      environment.systemPackages = [
        clockworkTheme
        pkgs.bibata-cursors
      ];

      security.pam.services.sddm.enableGnomeKeyring = true;
      services.accounts-daemon.enable = true;
    };
}
