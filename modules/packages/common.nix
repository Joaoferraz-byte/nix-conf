{ ... }: {
  flake.nixosModules.commonPackages = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh
      nautilus
      brave
      vesktop
      kdePackages.okular
      foliate
      hydralauncher
      heroic
      jdk21
      jdk8
      jdt-language-server
      spring-boot-cli
      lombok
      file-roller
      tlp
      powertop
    ];
  };
}
