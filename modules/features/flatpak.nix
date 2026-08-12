{ inputs, ... }: {
  flake.nixosModules.flatpak = { ... }: {
    imports = [
      inputs.nix-flatpak.nixosModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;

      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "flatpark";
          location = "https://dl.flatpark.org/flatpark.flatpakrepo";
        }
        {
          name = "freesmlauncher";
          location = "https://flatpak.freesmlauncher.org/freesmlauncher.flatpakrepo";
        }
      ];

      packages = [
        { appId = "org.zennotes.ZenNotes"; origin = "flatpark"; }
        { appId = "org.vinegarhq.Sober"; origin = "flathub"; }
        { appId = "net.audiorelay.AudioRelay"; origin = "flathub"; }
        { appId = "org.freesmlauncher.FreesmLauncher"; origin = "freesmlauncher"; }
      ];

      update.onActivation = false;
      update.auto.enable = false;

      overrides.settings.global = {
        Environment = {
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
          XDG_DATA_DIRS = "/run/host/usr/share:/run/host/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
        };
      };
    };
  };
}
