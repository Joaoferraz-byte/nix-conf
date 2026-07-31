# ─── Ambxst Shell Integration ─────────────────────────────────────────────
# Integra o Ambxst (shell Quickshell) ao sistema via Home Manager.
#
# O Ambxst é um ecossistema completo de shell para Wayland que usa:
# - Quickshell (QML) para a interface
# - axctl para abstração de compositor (suporta Hyprland nativamente)
# - JSON para configuração declarativa
#
# Esta integração segue o mesmo padrão do noctalia.nix:
# - Configurações base armazenadas em JSON no repositório shell-conf
# - Gerenciadas declarativamente pelo Home Manager
# - O wrapper Nix garante o ambiente correto (PATH, QML, fontes, ícones)
#
# Referência: https://github.com/Axenide/Ambxst
{ self, inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, lib, config, ... }: {

    # ── Pacote principal ───────────────────────────────────────────────────
    # O wrapper "ambxst" é instalado no sistema e chamado pelo Hyprland no
    # spawn-at-startup. Ele inicializa o axctl e o Quickshell.
    environment.systemPackages = [
      inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # ── Fontes necessárias para o Ambxst ───────────────────────────────────
    # Ambxst-X requer: Roboto, Roboto Mono, League Gothic, Nerd Fonts Symbols.
    # As demais fontes são bundled no pacote upstream.
    fonts.packages = with pkgs; [
      roboto
      roboto-mono
      league-gothic
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];

    # ── Serviços recomendados pelo Ambxst ──────────────────────────────────
    # NOTE: power-profiles-daemon conflicts with tlp. The Dell Latitude 5410
    # host sets services.tlp.enable = true, so we disable power-profiles-daemon
    # there. For hosts that want power-profiles-daemon, they should NOT enable tlp.
    # Use `lib.mkForce false` to ensure tlp wins on the Dell host.
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # Disable tlp if power-profiles-daemon is enabled to avoid the NixOS assertion.
    # Hosts that prefer tlp (e.g., Dell Latitude) should override this with
    # `services.tlp.enable = lib.mkForce true` and
    # `services.power-profiles-daemon.enable = lib.mkForce false`.
    services.tlp.enable = lib.mkDefault false;

    # ── Módulo Home Manager ────────────────────────────────────────────────
    # Gerencia os arquivos JSON de configuração e os keybinds do Ambxst.
    # Segue o mesmo padrão do nixvim e do noctalia.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];
  };
}
