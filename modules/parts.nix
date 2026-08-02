{ lib, ... }: {
  options.flake = {
    nixosModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = {};
      description = "NixOS modules exported by this flake.";
    };
    homeManagerModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = {};
      description = "Home Manager modules exported by this flake.";
    };
    nixosConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = {};
      description = "NixOS configurations exported by this flake.";
    };
  };

  config = {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
