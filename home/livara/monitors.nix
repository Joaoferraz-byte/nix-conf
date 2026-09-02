{ monitorProfile ? "myMachine", ... }:

let
  monitorRules = {
    latitude = [
      {
        selector = "desc:BOE 0x07BB";
        scale = 1.25;
      }
    ];
    # No explicit output is declared for myMachine. niri discovers connected
    # outputs at runtime and therefore does not reserve a phantom second screen.
    myMachine = [ ];
  };

  rules = monitorRules.${monitorProfile} or [ ];
  renderRule = rule: ''
output "${rule.selector}" {
  scale ${toString rule.scale}
}
'';
in
{
  home.file.".config/niri/outputs.kdl".text = builtins.concatStringsSep "\n" (map renderRule rules);
}
