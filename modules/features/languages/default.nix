{ self, ... }:
{
  imports = [
    ./c.nix
    ./cpp.nix
    ./python.nix
    ./java.nix
    ./javascript.nix
    ./php.nix
    ./assembly.nix
    ./kotlin.nix
    ./rust.nix
  ];

  flake.nixosModules.developmentLanguages = {
    imports = [
      self.nixosModules.developmentC
      self.nixosModules.developmentCpp
      self.nixosModules.developmentPython
      self.nixosModules.developmentJava
      self.nixosModules.developmentJavaScript
      self.nixosModules.developmentPhp
      self.nixosModules.developmentAssembly
      self.nixosModules.developmentKotlin
      self.nixosModules.developmentRust
    ];
  };
}
