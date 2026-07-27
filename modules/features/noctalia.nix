{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      pkgs = pkgs // { noctalia-shell = inputs.wrapper-modules.packages.${pkgs.system}.noctalia-shell; };

      settings = builtins.fromJSON (builtins.readFile ./noctalia.json);
    };
  };
}
