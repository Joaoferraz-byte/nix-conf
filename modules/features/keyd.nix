{ ... }: {
  flake.nixosModules.keyd = { ... }: {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          "meta:M" = { };

          main = {
            leftmeta = "overload(meta, menu)";
          };
        };
      };
    };
  };
}
