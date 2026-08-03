{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # O NixVim vive em um flake separado e reutilizável.
    vim-conf.url = "github:Joaoferraz-byte/vim-conf";
    # NixVim permanece uma entrada independente, sem forçar `follows`.
    # Tema SDDM declarativo com suporte nativo a ícones por usuário.
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";
    # NOTA: nixvim aparece como input direto E dentro do vim-conf.
    # O input direto fornece o módulo HM compartilhado (homeModules.nixvim).
    # O vim-conf usa o nixvim internamente para construir o pacote.
    # Caelestia Shell (substitui o DMS)
    # O shell-conf agora consome o Caelestia upstream.
    shell-conf = {
      url = "github:Joaoferraz-byte/shell-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, ... }: inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    # ── Input Consistency Policy ────────────────────────────────────────
    # Inputs do flake são usados para:

    #   - nix-flatpak: gerência declarativa de Flatpaks
    #   - vim-conf: configuração NixVim declarativa (plugins, languages, keymaps)
    #   - nixvim: módulo HM compartilhado para programas.nixvim.*
    #   - home-manager: configuração do usuário livara
    #   - shell-conf: Caelestia Shell
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
