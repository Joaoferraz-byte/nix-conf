{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      # O noctalia-shell já está presente no nixpkgs-unstable, então o wrapper o encontrará automaticamente em `pkgs`.
      # Removida a injeção manual que causava erro de atributo ausente.
      settings = builtins.fromJSON (builtins.readFile ./noctalia.json);
    };
  };
}
