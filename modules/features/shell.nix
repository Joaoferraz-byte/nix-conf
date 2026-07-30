# ─── Quickshell Integration ────────────────────────────────────────────
# Integra a nova barra Quickshell (shell-conf) ao sistema Home Manager.
# Esta configuração é injetada como sharedModule do home-manager via
# o módulo de host (my-machine ou dell-latitude-5410).
{ self, inputs, ... }: {
  # Módulo NixOS que adiciona o shell-conf como sharedModule do HM
  flake.nixosModules.quickshell = { pkgs, lib, config, ... }: {
    # Instala o pacote quickshell e o shell-conf
    environment.systemPackages = with pkgs; [
      quickshell
    ];

    # Garante que o shell-conf esteja no path do sistema
    # para que 'quickshell -c shell-conf' funcione
    programs.quickshell = {
      enable = true;
    };

    # Adiciona o shell-conf como módulo compartilhado do Home Manager
    # assim como o nixvim já é feito
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];
  };
}
