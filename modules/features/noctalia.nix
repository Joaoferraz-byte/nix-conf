# ─── Noctalia Wrapper ─────────────────────────────────────────────────────
# Configuração base compartilhada entre hosts.
# Layouts de desktop widgets específicos por host ficam em
# modules/hosts/<host>/desktop-widgets.json e são mesclados via wrapper.
{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;
      settings = builtins.fromJSON (builtins.readFile ./noctalia.json);
    };

    # Wrapper que expõe os diretórios de dados do Flatpak para que o
    # Noctalia consiga resolver ícones de aplicativos Flatpak na bandeja.
    packages.myNoctaliaWithFlatpakIcons = pkgs.writeShellScriptBin "noctalia-wrapper" ''
      export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
      exec ${self.packages.${pkgs.stdenv.hostPlatform.system}.myNoctalia}/bin/noctalia "$@"
    '';
  };
}
