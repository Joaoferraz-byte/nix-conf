{ ... }: {
  flake.nixosModules.keyd = { ... }: {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            # Super must remain a plain modifier: the previous
            # overload(meta, menu) setup swallowed Solo-Super presses as
            # KEY_MENU and delayed meta delivery, breaking the DMS standard
            # shortcuts (Super+X, Super+Comma, ...). Keep the solo-key menu
            # behavior in a layer only if it is explicitly desired again.
            leftmeta = "meta";
          };
        };
      };
    };
  };
}
