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
    nixvim.url = "github:nix-community/nixvim";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, ... }: inputs.flake-parts.lib.mkFlake {inherit inputs;} {
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
