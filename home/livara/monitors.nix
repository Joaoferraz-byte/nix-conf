{ hostName ? "unknown", ... }:
let
  monitorRules = {
    latitude = [
      {
        output = "eDP-1";
        scale = 1.25;
      }
      {
        output = "HDMI-A-1";
        scale = 1.0;
      }
      {
        output = "DP-1";
        scale = 1.0;
      }
    ];
    myMachine = [ ];
  };
  rules = monitorRules.${hostName} or [ ];
  renderRule = rule: ''
    hl.monitor({
      output = "${rule.output}",
      mode = "preferred",
      position = "auto",
      scale = ${toString rule.scale}
    })
  '';
  fallback = ''
    hl.monitor({
      output = "",
      mode = "preferred",
      position = "auto",
      scale = "auto"
    })
  '';
in
{
  wayland.windowManager.hyprland.extraLuaFiles."monitors.lua" = {
    content = builtins.concatStringsSep "\n" (map renderRule rules ++ [ fallback ]);
    autoLoad = false;
  };
}
