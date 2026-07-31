# ─── Ambxst-X Shell Integration ─────────────────────────────────────────────
# O shell-conf reexporta o módulo NixOS oficial do Ambxst-X. Mantemos aqui
# somente a ligação com os inputs deste flake e a configuração Home Manager.
{ inputs, ... }: {
  flake.nixosModules.ambxst = { pkgs, lib, ... }: {
    imports = [
      inputs.shell-conf.nixosModules.default
    ];

    # Fixa o módulo upstream ao pacote reexportado pelo shell-conf, garantindo
    # que wrapper, axctl, Quickshell e módulo pertençam à mesma revisão.
    programs.ambxst = {
      enable = true;
      package = inputs.shell-conf.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    # power-profiles-daemon é habilitado pelo módulo upstream. TLP fica
    # desabilitado por padrão para evitar a asserção de conflito; hosts que
    # precisam de TLP fazem override explícito junto de PPD.
    services.tlp.enable = lib.mkDefault false;

    # Arquivos JSON declarativos e a migração do binds.json legado.
    home-manager.sharedModules = [
      inputs.shell-conf.homeManagerModules.default
    ];
  };
}
