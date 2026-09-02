{
  flake.nixosModules.keyd = { ... }: {
    services.keyd = {
      enable = true;

      keyboards.default = {
        # Restrict the custom layer to the Aitek Delta TM6101 (0603:9800)
        # keyboard interfaces. The internal keyboard is not matched.
        ids = [
          "0603:9800:1458f7e7"
          "0603:9800:b87f5e17"
        ];

        settings = {
          # Keep an explicit default layer in the generated keyd config. The
          # control layer below is additive and must not replace main.
          main = { };

          # Do not remap Meta — keyd already maps left-meta to the `meta`
          # modifier; an explicit mapping is redundant and can interfere
          # with compositor Super bindings.

          # keyd's modifier layer preserves Ctrl and emits real arrow events.
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
            # Ctrl+semicolon → slash (br-abnt2 layout quirk on 60% keyboard);
            # Shift stacks, so Ctrl+Shift+semicolon → question mark.
            "semicolon" = "slash";
          };

          # Explicit shifted chord for the br XKB map translation.
          "control+shift" = {
            "semicolon" = "S-slash";
          };
        };
      };
    };
  };
}
