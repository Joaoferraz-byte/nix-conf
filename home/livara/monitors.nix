{ monitorProfile ? "myMachine", ... }:
let
  monitorRules = {
    # The BOE description is the stable identity of the built-in panel.
    # Do not also declare eDP-1: that is the same physical output and the
    # duplicate rule made hotplug diagnostics look like a second display.
    latitude = [
      {
        output = "desc:BOE 0x07BB";
        scale = 1.25;
      }
    ];
    myMachine = [ ];
  };

  rules = monitorRules.${monitorProfile} or [ ];
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
