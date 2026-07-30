{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/77981d0d8e43ee2c652eaf835259665eb88a674d";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    # wrapper-modules: mantido para o wrapper do Noctalia (noctalia.nix)
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # O NixVim vive em um flake separado e reutilizável.
    vim-conf.url = "github:Joaoferraz-byte/vim-conf";
    # NixVim permanece uma entrada independente, sem forçar `follows`.
    # SDDM com tema Noctalia para o login manager
    sddm-noctalia.url = "github:ClementFombonne/sddm-noctalia-theme";
    nixvim.url = "github:nix-community/nixvim";
    # NOTA: nixvim aparece como input direto E dentro do vim-conf.
    # O input direto fornece o módulo HM compartilhado (homeModules.nixvim).
    # O vim-conf usa o nixvim internamente para construir o pacote.
    # Quickshell integration
    shell-conf.url = "github:Joaoferraz-byte/shell-conf";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, ... }: inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    # ── Input Consistency Policy ────────────────────────────────────────
    # Inputs do flake são usados para:
    #   - nixpkgs-stable: pino de segurança para o niri (libdisplay-info)
    #   - wrapper-modules: wrapper do Noctalia (nix-wrapper-modules)
    #   - nix-flatpak: gerência declarativa de Flatpaks
    #   - vim-conf: configuração NixVim declarativa (plugins, languages, keymaps)
    #   - nixvim: módulo HM compartilhado para programas.nixvim.*
    #   - home-manager: configuração do usuário livara
    imports = [
      (inputs.import-tree ./modules)
    ];
    perSystem = { system, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };
  };
}
