{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      settings = builtins.fromJSON (builtins.readFile ./noctalia.json);
    };
    
    # Cria um wrapper para o Noctalia que expõe os diretórios de dados do Flatpak
    # para que ele consiga resolver ícones de aplicativos Flatpak na bandeja.
    packages.myNoctaliaWithFlatpakIcons = pkgs.writeShellScriptBin "noctalia-wrapper" ''
      export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
      exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia}/bin/noctalia "$@"
    '';
  };
}
