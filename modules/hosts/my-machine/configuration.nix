
{ self, inputs, ... }: {
  flake.nixosModules.myMachineConfiguration = { config, pkgs, lib, ... }: {
	  imports = [ 
	      self.nixosModules.myMachineHardware
	      self.nixosModules.niri
	      self.nixosModules.nvidia
	      self.nixosModules.greeter
              self.nixosModules.desktop-portals
              self.nixosModules.system-hardening
	      self.nixosModules.flatpak
	      self.nixosModules.audiorelay
	  ];

	  services.audiorelay.enable = true;

	  # Bootloader.
	  boot.loader.systemd-boot.enable = true;
	  boot.loader.efi.canTouchEfiVariables = true;

	  # Use latest kernel.
	  boot.kernelPackages = pkgs.linuxPackages_zen;
	  networking.hostName = "limine"; # Define your hostname.

	  # Enable networking
	  networking.networkmanager.enable = true;

	  # Set your time zone.
	  time.timeZone = "America/Sao_Paulo";

	  # Select internationalisation properties.
	  i18n.defaultLocale = "en_US.UTF-8";

	  i18n.extraLocaleSettings = {
	    LC_ADDRESS = "pt_BR.UTF-8";
	    LC_IDENTIFICATION = "pt_BR.UTF-8";
	    LC_MEASUREMENT = "pt_BR.UTF-8";
	    LC_MONETARY = "pt_BR.UTF-8";
	    LC_NAME = "pt_BR.UTF-8";
	    LC_NUMERIC = "pt_BR.UTF-8";
	    LC_PAPER = "pt_BR.UTF-8";
	    LC_TELEPHONE = "pt_BR.UTF-8";
	    LC_TIME = "pt_BR.UTF-8";
	  };

	  # Configure keymap in X11
	  services.xserver.xkb = {
	    layout = "br";
	    variant = "";
	  };

	  # Configure console keymap
	  console.keyMap = "br-abnt2";

	  # Define a user account. Don't forget to set a password with ‘passwd’.
	  users.users."livara" = {
	    isNormalUser = true;
	    description = "Livara";
	    extraGroups = [ "networkmanager" "wheel" ];
	    packages = with pkgs; [];
	  };

	  boot.loader.systemd-boot.configurationLimit = 10;
	  
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

	  services.flatpak.enable = true;
	  nixpkgs.config.allowUnfree = true;

	  environment.systemPackages = with pkgs; [
	     
	     # Essential
	     neovim
	     git
	     gh
	     alacritty
	     nautilus

	     # Basic
	     brave
	     vesktop
	     kdePackages.okular
	     foliate
	     obsidian

             # Games
	     hydralauncher
	     heroic
             
	     # Programming
	     jdk21
	     jdk25
	     jdk8
	  ];

	  system.stateVersion = "26.05";
    };
}
