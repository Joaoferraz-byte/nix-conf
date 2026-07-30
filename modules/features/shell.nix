# ─── Quickshell Integration [DEPRECATED] ────────────────────────────────
# DEPRECATED: Este módulo foi substituído por ambxst.nix (BUG-002).
# O módulo ambxst.nix fornece integração completa com o Ambxst shell,
# incluindo fontes, serviços (upower, power-profiles-daemon) e o módulo HM.
#
# Este arquivo é mantido apenas para referência histórica.
# Todos os hosts devem usar self.nixosModules.ambxst em vez de
# self.nixosModules.quickshell.
#
# TODO: Remover este arquivo após confirmar que nenhum host usa quickshell.
# ─── Quickshell Integration ────────────────────────────────────────────
# Integra a nova barra Quickshell (shell-conf) ao sistema Home Manager.
# Esta configuração é injetada como sharedModule do home-manager via
# o módulo de host (my-machine ou dell-latitude-5410).
#
# Conforme a documentação oficial do Quickshell:
# https://quickshell.org/docs/v0.1.0/guide/install-setup/
# O quickshell é instalado como pacote (pkgs.quickshell), não existe
# programs.quickshell como opção nativa do NixOS.
{ self, inputs, ... }: {
  # Módulo NixOS que adiciona o shell-conf como sharedModule do HM
  flake.nixosModules.quickshell = { pkgs, lib, config, ... }: {
    # Instala o pacote quickshell no sistema
    # (conforme documentação oficial do Quickshell para Nix)
    environment.systemPackages = with pkgs; [
      quickshell
    ];

    # Adiciona o shell-conf como módulo compartilhado do Home Manager
    # assim como o nixvim já é feito.
    # O módulo HM do shell-conf copia os arquivos para
    # ~/.config/quickshell/shell-conf/ e define o pacote no home.packages.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];
  };
}
