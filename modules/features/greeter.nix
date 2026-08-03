# ─── SDDM Display Manager + QyLock (Clockwork) ──────────────────────────────
# O tema SilentSDDM foi substituído pelo tema "Clockwork" da coleção QyLock.
# O QyLock fornece uma integração nativa via módulo NixOS para Hyprland/Quickshell.
#
# ASSETS: O ícone de perfil é gerenciado via AccountsService/face.icon.
{ self, inputs, ... }: {
  flake.nixosModules.greeter = { pkgs, config, ... }: {
    imports = [
      inputs.qylock.nixosModules.default
    ];

    # Desabilita explicitamente o SilentSDDM se ele ainda estiver ativo em algum lugar
    # para evitar conflitos no sddm.conf.
    # programs.silentSDDM.enable = false;

    # Configuração do QyLock com o tema Clockwork
    programs.qylock = {
      enable = true;
      theme = "clockwork";
      # Opções recomendadas para o tema Clockwork Orbital
      themeOptions.clockwork.orbital = {
        themeMode = "dark";
        enableWindup = true;
      };
    };

    # Habilita o SDDM e define o tema via QyLock
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
