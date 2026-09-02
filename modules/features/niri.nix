{ ... }:
{
  flake.nixosModules.niri = { config, lib, pkgs, ... }:
    {
      config = lib.mkIf (config.desktop.profile.compositor == "niri") {
        programs.niri.enable = true;

        # The official module installs the CLI and the privileged
        # gsr-kms-server wrapper needed by direct monitor capture (-w screen).
        programs.gpu-screen-recorder.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite
          brightnessctl
          wev
          wl-clipboard
          wl-clip-persist
          grim
          slurp
          satty
          hyprpicker
          imagemagick
          tesseract
          curl
          jq
          xdg-utils
          procps
          zbar
          ffmpeg
          bind
          wl-screenrec
          wf-recorder
          swappy
          translate-shell
        ];
      };
    };
}
