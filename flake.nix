{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree = {
      url = "github:vic/import-tree";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };
    vim-conf = {
      url = "github:Joaoferraz-byte/vim-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell + Niri via shell-conf
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shell-conf = {
      url = "github:Joaoferraz-byte/shell-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mesa-tomate-driver = {
      url = "github:Joaoferraz-byte/mesa-tomate-driver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
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
