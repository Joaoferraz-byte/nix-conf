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
    ];
    myMachine = [ ];
  };

  rules = monitorRules.${hostName} or [ ];
  renderRule = rule:
    let
      scale = if builtins.isString rule.scale then rule.scale else toString rule.scale;
    in
    "monitor = ${rule.output}, preferred, auto, ${scale}\n";
in
{
  # The Serpantinum source includes monitors.conf. This file is the small
  # host-specific overlay loaded after it by hyprland.conf.
  home.file.".config/hypr/config/monitors.local.conf".text =
    builtins.concatStringsSep "" (map renderRule rules);
}
