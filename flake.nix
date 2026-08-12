{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vim-conf = {
      url = "github:Joaoferraz-byte/vim-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xournal-conf = {
      url = "github:Joaoferraz-byte/xournal-conf";
      flake = false;
    };

    nixvim.url = "github:nix-community/nixvim";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shell-conf = {
      url = "github:Joaoferraz-byte/shell-conf";
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

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules/parts.nix
        ./modules/features/audiorelay.nix
        ./modules/features/desktop-portals.nix
        ./modules/features/dms-system.nix
        ./modules/features/firejail.nix
        ./modules/features/flatpak.nix
        ./modules/features/greeter.nix
        ./modules/features/keyd.nix
        ./modules/features/niri.nix
        ./modules/features/nvidia.nix
        ./modules/features/system-hardening.nix
        ./modules/packages/core-packages.nix
        ./modules/hosts/common-desktop.nix
        ./modules/hosts/my-machine
        ./modules/hosts/latitude
      ];

      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          _module.args.pkgs = pkgs;
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              btrfs-progs
              git
              nix
              nixos-rebuild
              util-linux
            ];
          };
        };
    };
}
