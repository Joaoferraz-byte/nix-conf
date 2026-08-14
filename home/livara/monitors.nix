{ hostName, ... }:
let
  monitorRules = {
    latitude = [
      {
        output = "desc:BOE 0x07BB";
        scale = 1.25;
      }
      {
        output = "eDP-1";
        scale = 1.25;
      }
      {
        output = "desc:Samsung Electric Company S24D332 0x59325956";
        scale = 1.0;
      }
      {
        output = "HDMI-A-1";
        scale = 1.0;
      }
      {
        output = "DP-1";
        scale = 1.0;
      }
      {
        output = "";
        scale = "auto";
      }
    ];
    myMachine = [ ];
  };

  rules = monitorRules.${hostName} or [ ];
  renderRule = rule:
    let
      scale = if builtins.isString rule.scale then builtins.toJSON rule.scale else toString rule.scale;
    in
    ''
      hl.monitor({
        output = "${rule.output}",
        mode = "preferred",
        position = "auto",
        scale = ${scale}
      })
    '';
in
{
  wayland.windowManager.hyprland.extraLuaFiles."monitors.lua" = {
    content = builtins.concatStringsSep "\n" (map renderRule rules);
    autoLoad = false;
  };
}
