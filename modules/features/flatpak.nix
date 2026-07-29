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

      # Overrides globais para todos os Flatpaks
      # Garante que ícones e cursores do sistema sejam visíveis dentro do sandbox.
      overrides.settings.global = {
        Environment = {
          # Expõe os diretórios de ícones do host para dentro do sandbox Flatpak.
          # Necessário para que ícones de tema (ex: Bibata-Modern-Classic) sejam
          # encontrados por apps Flatpak no Niri/Noctalia.
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
          # Garante que os dados do sistema (incluindo ícones de apps) estejam
          # disponíveis para o Flatpak. Crítico para descoberta de ícones no Niri.
          XDG_DATA_DIRS = "/run/host/usr/share:/run/host/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
        };
      };
    };
  };
}
