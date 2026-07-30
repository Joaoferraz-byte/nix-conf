# ─── Quickshell Integration ────────────────────────────────────────────
# Integra a nova barra Quickshell (shell-conf) ao sistema Home Manager.
{ self, inputs, ... }: {
  flake.homeConfigurations.livara = { pkgs, lib, config, ... }: {
    # ── Inputs ──────────────────────────────────────────────────────────
    # O shell-conf é um flake separado que fornece o pacote e o módulo HM.
    imports = [ inputs.shell-conf.homeManagerModules.default ];
    
    # ── Instalação do pacote ───────────────────────────────────────────
    home.packages = with pkgs; [
      quickshell
      inputs.shell-conf.packages.${system}.default
    ];
  };
}
