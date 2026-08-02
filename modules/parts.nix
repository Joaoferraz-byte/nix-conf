{ lib, ... }: {
  # Declaração de saídas do flake para que o flake-parts saiba como mesclá-las
  # quando definidas em múltiplos arquivos (ex: hyprland.nix e niri.nix).
  options.flake = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;
      options = {
        nixosModules = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
        };
        homeManagerModules = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
        };
      };
    };
  };

  config = {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
