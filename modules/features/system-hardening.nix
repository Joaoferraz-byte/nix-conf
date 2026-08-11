
{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, lib, ... }: {

    # Firewall
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 59100 ]; # AudioRelay
      allowedUDPPorts = [ 5353 ]; # mDNS
      allowPing = true;
      extraCommands = ''
        iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
      '';
    };

    # Kernel hardening
    security.protectKernelImage = true;

    boot.kernel.sysctl = {
      "kernel.yama.ptrace_scope" = 2; # ptrace restrict (desktop)

      "kernel.unprivileged_bpf_disabled" = 1; # block unprivileged BPF

      "kernel.sysrq" = 0;

      "kernel.kptr_restrict" = 1; # hide kernel pointers

      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
      "fs.suid_dumpable" = 0;
      "kernel.randomize_va_space" = 2;
      "net.core.bpf_jit_harden" = 2;
    };

    # Boot security
    boot.loader.systemd-boot.editor = false;

    boot.kernelParams = [
      "mitigations=auto"
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
    ];

    # Sudo
    security.sudo = {
      execWheelOnly = true;
      extraConfig = ''
        Defaults pwfeedback
      '';

      extraRules = [{
        users = [ "livara" ];
        commands = [
          { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        ];
      }];
    };

    services.geoclue2.enable = true; # DMS night light

    # Auditd (lock mode prevents root from wiping rules)
    security.audit = {
      enable = "lock";
      rules = [
        "-a always,exit -F arch=b64 -S open,openat -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access_denied"
        "-a always,exit -F arch=b64 -S open,openat -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access_denied"
        "-w /etc/sudoers -p wa -k sudoers_changes"
        "-w /etc/ssh/sshd_config -p wa -k sshd_config"
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
      ];
      backlogLimit = 8192;
    };

    # Nix
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [ "root" "livara" ];
        allow-import-from-derivation = false;
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 20d";
      };
    };

    # zram swap
    zramSwap = {
      enable = true;
      memoryPercent = 50;
      algorithm = "zstd";
    };

    systemd.services.systemd-resolved.serviceConfig = {
      PrivateDevices = "yes";
      ProtectHome = "yes";
      ProtectSystem = "full";
      NoNewPrivileges = "yes";
    };

    services.journald.extraConfig = ''
      SystemMaxUse=200M
      MaxRetentionSec=30day
      Compress=yes
      Seal=yes
    '';
  };
}
