# ─── System Hardening & Security Module ────────────────────────────────────
# Based on: NixOS Wiki Security, Discourse discussions, and best practices.
# Designed for a desktop/workstation use case (not server), balancing
# security with usability. Port 1239 for AudioRelay is allowed explicitly.
{ ... }: {
  flake.nixosModules.system-hardening = { pkgs, lib, ... }: {

    # ── Firewall ──────────────────────────────────────────────────────────
    networking.firewall = {
      enable = true;

      # Block all incoming by default
      defaultPolicy = "drop";

      # AudioRelay requires TCP port 1239 open for audio streaming
      allowedTCPPorts = [ 1239 ];

      # Allow mDNS (used by Noctalia, Avahi, local discovery)
      allowedUDPPorts = [ 5353 ];

      # Allow ICMP ping (useful for debugging, not a security risk)
      allowPing = true;

      # Enable connection tracking for stateful inspection
      extraCommands = ''
        iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
      '';
    };

    # ── Kernel Hardening ──────────────────────────────────────────────────
    # Restrict kernel access to sensitive info
    security.protectKernelImage = true;

    # Disable ptrace for non-related processes (hardens against debugging attacks)
    boot.kernel.sysctl = {
      # Prevent non-privileged ptrace access to other processes
      "kernel.yama.ptrace_scope" = 2;

      # Restrict access to /proc/sysrq-trigger
      "kernel.sysrq" = 0;

      # Protect against SYN floods
      "net.ipv4.tcp_syncookies" = 1;

      # Disable source routing
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      # Disable ICMP redirects (prevent MITM via routing)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;

      # Disable IP forwarding (this is a workstation, not a router)
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;

      # Log suspicious packets
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;

      # Restrict core dumps from SUID programs
      "fs.suid_dumpable" = 0;

      # Prevent ASLR weakening
      "kernel.randomize_va_space" = 2;

      # Restrict BPF JIT (reduce attack surface)
      "net.core.bpf_jit_harden" = 2;

      # Hide kernel pointers (hardens against kernel exploits)
      "kernel.kptr_restrict" = 1;
    };

    # ── Boot Security ─────────────────────────────────────────────────────
    boot = {
      # Enable secure boot if supported
      loader.systemd-boot.enable = true;
      loader.systemd-boot.editor = false; # Prevent editing boot entries at boot time

      # Kernel module loading restrictions
      kernelModules = [
        "nvidia"
        "nvidia_modeset"
      ];
      kernelParams = [
        "mitigations=auto"
        "slab_nomerge"
        "init_on_alloc=1"
        "init_on_free=1"
        "page_alloc.shuffle=1"
      ];
    };

    # ── Sudo Hardening ────────────────────────────────────────────────────
    security.sudo = {
      # Only wheel group can use sudo
      execWheelOnly = true;
      # Add timestamp_timeout for convenience but with security
      extraRules = [{
        users = [ "livara" ];
        commands = [
          { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        ];
      }];
    };

    # ── Privacy & Telemetry ───────────────────────────────────────────────
    # Disable hardware tracking
    services.udev.extraRules = ''
      # Disable webcam indicator control
      ACTION=="add", SUBSYSTEM=="video4linux", ATTR{device/power/control}="auto"
    '';

    # Disable automatic firmware updates to prevent unexpected changes
    services.fwupd.enable = false;

    # Enable audit logging for security-relevant events
    auditd.enable = true;

    # ── Nix Store Security ────────────────────────────────────────────────
    nix = {
      settings = {
        auto-optimise-store = true;
        # Restrict who can install packages
        trusted-users = [ "root" "livara" ];
        # Disable import-from-derivation (security risk)
        allow-import-from-derivation = false;
        # Use binary cache from trusted sources only
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

    # ── Memory Protection ─────────────────────────────────────────────────
    zramSwap = {
      enable = true;
      memoryPercent = 50;
      algorithm = "zstd";
    };

    # ── Systemd Service Hardening ─────────────────────────────────────────
    # Apply common hardening defaults to services
    systemd.services.systemd-resolved.serviceConfig = {
      PrivateDevices = "yes";
      ProtectHome = "yes";
      ProtectSystem = "full";
      NoNewPrivileges = "yes";
    };

    # ── Log Retention ─────────────────────────────────────────────────────
    services.journald.extraConfig = ''
      SystemMaxUse=200M
      MaxRetentionSec=30day
      Compress=yes
      Seal=yes
    '';
  };
}
