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
    "  hl.monitor({ output = \"${rule.output}\", mode = \"preferred\", position = \"auto\", scale = ${scale} })\n";
in
{
  # The Serpantinum source loads this module from hyprland.lua.
  # Host-specific monitor rules are applied after the generic fallback.
  home.file.".config/hypr/monitors_host.lua".text = ''
    local M = {}
    function M.apply()
${builtins.concatStringsSep "" (map renderRule rules)}    end
    return M
  '';
}
