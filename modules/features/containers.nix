{
  flake.nixosModules.containers = { pkgs, ... }: {
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };

    environment.systemPackages = with pkgs; [
      docker
      docker-compose
      docker-buildx
      lazydocker
    ];
  };
}
