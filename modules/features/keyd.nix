{
  flake.nixosModules.keyd = { ... }: {
    services.keyd = {
      enable = true;

      keyboards.default = {
        # Restrict the custom layer to the two keyboard input interfaces
        # exposed by the Aitek Delta TM6101 (0603:9800). The consumer-control
        # interface is intentionally excluded; the Latitude's internal
        # keyboard is not matched and therefore keeps its normal behavior.
        ids = [
          "0603:9800:1458f7e7"
          "0603:9800:b87f5e17"
        ];

        settings = {
          # Keep an explicit default layer in the generated keyd config. The
          # control layer below is additive and must not replace main.
          main = { };

          # Do not remap Meta here. keyd already exposes the physical
          # left-meta key as the `meta` modifier; an explicit
          # `leftmeta = meta` mapping is redundant, is not part of upstream
          # Serpantinum, and can prevent Hyprland from seeing Super binds.

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
            # The 60% TM6101 exposes slash punctuation awkwardly under br(abnt2).
            # Ctrl+semicolon emits an unmodified slash; Shift remains stacked,
            # so Ctrl+Shift+semicolon emits question mark without firmware Fn.
            "semicolon" = "slash";
          };

          # Make the shifted chord explicit. keyd's modifier-layer rules
          # preserve Shift, but this composite layer removes ambiguity when
          # the external device is translated through the br XKB map.
          "control+shift" = {
            "semicolon" = "S-slash";
          };
        };
      };
    };
  };
}
