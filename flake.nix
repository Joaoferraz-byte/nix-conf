{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # O NixVim vive em um flake separado e reutilizável.
    vim-conf.url = "github:Joaoferraz-byte/vim-conf";
    
    # NOTE: The Clockwork SDDM theme is now vendored locally in ./themes/clockwork/
    # and built as a Nix derivation in modules/features/greeter.nix.
    # No external qylock flake input is needed.
    
    nixvim.url = "github:nix-community/nixvim";
    
    # Caelestia Shell
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
