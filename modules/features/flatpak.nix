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

      update.onActivation = true;
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
