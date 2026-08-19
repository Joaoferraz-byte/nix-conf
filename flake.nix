{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vim-conf = {
      url = "github:Joaoferraz-byte/vim-conf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shell-conf = {
      url = "github:Joaoferraz-byte/shell-conf";
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
        inputs.home-manager.flakeModules.home-manager
        ./modules/parts.nix
        ./modules/features/audiorelay.nix
        ./modules/features/desktop-portals.nix
        ./modules/features/development.nix
        ./modules/features/embedded.nix
        ./modules/features/firejail.nix
        ./modules/features/flatpak.nix
        ./modules/features/greeter.nix
        ./modules/features/niri.nix
        ./modules/features/keyd.nix
        ./modules/features/nvidia.nix
        ./modules/features/system-hardening.nix
        ./modules/features/containers.nix
        ./modules/features/virtualization.nix
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
              nixos-install-tools
              nixos-rebuild
              util-linux
            ];
          };

          devShells.python = pkgs.mkShell {
            packages = with pkgs; [
              python3
              uv
              ruff
              pyright
              python3Packages.jupyterlab
              manim
              texlive.combined.scheme-full
            ];
          };

          devShells.embedded = pkgs.mkShell {
            packages = with pkgs; [
              arduino-cli
              avrdude
              dfu-util
              openocd
              platformio
              probe-rs-tools
              stlink
            ];
          };
        };
    };
}
