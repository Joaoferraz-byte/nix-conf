{ ... }: {
  flake.nixosModules.keyd = { ... }: {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            leftmeta = "meta";
          };
        };
      };
    };
  };
}
