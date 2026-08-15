{
  flake.nixosModules.keyd = { ... }: {
    services.keyd = {
      enable = true;

      keyboards.default = {
        # Keep this wildcard by default so the mapping works on both hosts.
        # The attribute can later be narrowed to the physical keyboard IDs
        # discovered with `keyd monitor` if a second keyboard needs isolation.
        ids = [ "*" ];

        settings = {
          main = {
            # Preserve the existing modifier normalization.
            leftmeta = "meta";
          };

          # keyd's modifier layer preserves Ctrl for every other key and
          # emits a genuine arrow event for the four navigation chords.
          "control:C" = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
            "1" = "f1";
            "2" = "f2";
            "3" = "f3";
            "4" = "f4";
            "5" = "f5";
            "6" = "f6";
            "7" = "f7";
            "8" = "f8";
            "9" = "f9";
            "0" = "f10";
          };
        };
      };
    };
  };
}
