# ─── Ambxst Shell Integration ─────────────────────────────────────────────
# Integra o Ambxst (shell Quickshell) ao sistema via Home Manager.
#
# O Ambxst é um ecossistema completo de shell para Wayland que usa:
# - Quickshell (QML) para a interface
# - axctl para abstração de compositor (suporta Niri nativamente)
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
    # O wrapper "ambxst" é instalado no sistema e chamado pelo Niri no
    # spawn-at-startup. Ele inicializa o axctl e o Quickshell.
    environment.systemPackages = [
      inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # ── Fontes necessárias para o Ambxst ───────────────────────────────────
    # Phosphor Icons: fonte de ícones da interface do shell (barra, botões)
    # As demais fontes são bundled no pacote, mas registrar no sistema
    # garante que outros apps também as encontrem.
    fonts.packages = with pkgs; [
      roboto
      roboto-mono
      league-gothic
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      # Phosphor Icons (embutido no pacote do shell-conf)
      inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.ttf-phosphor-icons
    ];

    # ── Serviços recomendados pelo Ambxst ──────────────────────────────────
    services.upower.enable = lib.mkDefault true;
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # ── Módulo Home Manager ────────────────────────────────────────────────
    # Gerencia os arquivos JSON de configuração e os keybinds do Ambxst.
    # Segue o mesmo padrão do nixvim e do noctalia.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];
  };
}
