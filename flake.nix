{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

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

    study-planner = {
      url = "github:Joaoferraz-byte/livara-study-planner";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim";

    nix-jetbrains-plugins = {
      url = "github:nix-community/nix-jetbrains-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
        ./modules/features/appimage.nix
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
              dmidecode
              git
              kmod
              lshw
              nix
              nixos-install-tools
              nixos-rebuild
              pciutils
              usbutils
              util-linux
            ];
            shellHook = ''
              export NIX_CONFIG="''${NIX_CONFIG:-}
              experimental-features = nix-command flakes"
            '';
          };

          devShells.python = pkgs.mkShell {
            packages = with pkgs; [
              python3
              uv
              ruff
              pyright
              python3Packages.jupyterlab
            ];
            shellHook = ''
              export VIRTUAL_ENV="''${VIRTUAL_ENV:-$PWD/.venv}"
              if [ ! -d "$VIRTUAL_ENV" ]; then
                uv venv "$VIRTUAL_ENV" --python ${pkgs.python3}/bin/python3
              fi
              export PATH="$VIRTUAL_ENV/bin:$PATH"
              export PYTHONDONTWRITEBYTECODE=1
              export UV_LINK_MODE=copy
            '';
          };

          devShells.science = pkgs.mkShell {
            packages = with pkgs; [
              python3
              python3Packages.manim
              texliveSmall
              imagemagick
            ];
            shellHook = ''
              export MPLBACKEND="''${MPLBACKEND:-Agg}"
              export TEXMFHOME="''${TEXMFHOME:-$PWD/.texmf}"
            '';
          };

          devShells.java = pkgs.mkShell {
            packages = with pkgs; [
              jdk21
              maven
              gradle
              spring-boot-cli
              lombok
            ];
            shellHook = ''
              export JAVA_HOME="${pkgs.jdk21}"
              export MAVEN_OPTS="''${MAVEN_OPTS:--Xmx1g -Dfile.encoding=UTF-8}"
              export GRADLE_USER_HOME="''${GRADLE_USER_HOME:-$PWD/.gradle}"
            '';
          };

          devShells.node = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              pnpm
              yarn
              typescript
              typescript-language-server
            ];
            shellHook = ''
              export COREPACK_HOME="''${COREPACK_HOME:-$PWD/.corepack}"
              export npm_config_cache="''${npm_config_cache:-$PWD/.npm-cache}"
              export PNPM_HOME="''${PNPM_HOME:-$PWD/.pnpm}"
              export PATH="$PNPM_HOME:$PATH"
            '';
          };

          devShells.rust = pkgs.mkShell {
            packages = with pkgs; [
              rustc
              cargo
              rust-analyzer
              rustfmt
              clippy
              pkg-config
              openssl
            ];
            shellHook = ''
              export CARGO_HOME="''${CARGO_HOME:-$PWD/.cargo}"
              export RUSTUP_HOME="''${RUSTUP_HOME:-$PWD/.rustup}"
              export CARGO_TARGET_DIR="''${CARGO_TARGET_DIR:-$PWD/target}"
            '';
          };

          devShells.go = pkgs.mkShell {
            packages = with pkgs; [
              go
              gopls
              delve
              gotools
              golangci-lint
            ];
            shellHook = ''
              export GOPATH="''${GOPATH:-$PWD/.go}"
              export GOMODCACHE="''${GOMODCACHE:-$PWD/.gomodcache}"
              export GOCACHE="''${GOCACHE:-$PWD/.gocache}"
              export PATH="$GOPATH/bin:$PATH"
            '';
          };

          devShells.docker = pkgs.mkShell {
            packages = with pkgs; [
              docker
              docker-compose
              docker-buildx
              lazydocker
            ];
            shellHook = ''
              if [ -z "''${DOCKER_HOST:-}" ] && [ -S "$XDG_RUNTIME_DIR/docker.sock" ]; then
                export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
              fi
              docker context ls >/dev/null 2>&1 || true
            '';
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

          checks.border-contract = pkgs.runCommand "niri-noctalia-border-contract" { } ''
            test "$(grep -c 'width 1.4' ${self}/home/livara/niri.nix)" -eq 2
            test "$(grep -c 'width 1.4' ${inputs.shell-conf}/config/noctalia/templates/niri.kdl)" -eq 2
            ! grep -q 'width 1.6' ${self}/home/livara/niri.nix
            ! grep -q 'width 1.6' ${inputs.shell-conf}/config/noctalia/templates/niri.kdl
            touch "$out"
          '';
        };
    };
}
