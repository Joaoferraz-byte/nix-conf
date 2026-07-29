{
  description = "A highly optimized NixVim configuration for Enterprise Development (Java, C/C++)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          nixvimModule = {
            inherit pkgs;
            module = import ./config;
            extraSpecialArgs = {
              inherit self;
            };
          };
          nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule nixvimModule;
        in
        {
          default = nvim;
        }
      );

      # Permite usar como um módulo do Home Manager ou NixOS
      nixvimModule = import ./config;
    };
}
