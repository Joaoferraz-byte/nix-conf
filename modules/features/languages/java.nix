{ ... }:
{
  # pkgs belongs to the NixOS module, not the flake-parts module.
  flake.nixosModules.developmentJava = { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        jdk8 jdk21 jdk25 jdt-language-server lombok maven gradle
      vscode-extensions.vscjava.vscode-java-test
      vscode-extensions.vscjava.vscode-java-debug
      ];
    };
}
