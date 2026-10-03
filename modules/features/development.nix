{
  flake.nixosModules.development = { pkgs, ... }:
    {
      # Shared utilities only. Language ownership lives in
      # ./languages/*.nix; project dependencies remain in project lockfiles.
      environment.systemPackages = with pkgs; [
        git
        ripgrep
        fd
        pkg-config
        curl
        unzip
        go
        gopls
        delve
      ];
    };
}
