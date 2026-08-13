# nix-conf Architecture

## 1. Scope and conclusion

`nix-conf` is a declarative NixOS workstation configuration composed from flake-parts modules, NixOS modules, Home Manager modules, pinned external inputs, and application-owned data. The repository is modular in the technical sense because its expressions are evaluated by the Nix module system, but modularity is only useful when every file has one owner, one evaluation layer, and one stable contract.

The active architecture now uses **Hyprland with UWSM**, the **end-4 illogical-impulse QuickShell profile**, and **Matugen** as the runtime palette generator. DMS and Niri are no longer active composition dependencies. The former shell integration was replaced rather than wrapped: immutable end-4 assets are consumed from a pinned source input, while local behavior is expressed in small NixOS and Home Manager adapters.

The dependency direction is:

```text
flake inputs
  -> flake-parts public outputs
    -> host composition roots
      -> NixOS system features
        -> shared desktop composition
          -> Home Manager profile
            -> application adapters and user services
```

A host may select system features. A system feature may consume public contracts from an external input. A Home Manager module may own user files and user services. Application repositories provide data and templates. No active module should reach through `inputs.<flake>.inputs` or make a host-specific assumption without an option or composition boundary.

## 2. What counts as a module

A NixOS or Home Manager module is an expression evaluated by the Nix module system. It may import other modules, declare typed options, and contribute configuration to a combined evaluation. A file containing Nix syntax is not automatically a module; a data file containing CSS, XML, JSON, or INI is not a module unless a consumer declares how it is installed or transformed.

> A module has a coherent responsibility, a defined evaluation layer, and an explicit contract with its consumers.

| Expression kind | Evaluation layer | Examples | Correct responsibility |
|---|---|---|---|
| Flake-parts module | Flake evaluation | `flake.nix`, `modules/parts.nix`, feature files, host assemblies | Publishes outputs and composes systems. |
| NixOS module | System evaluation | `modules/features/*.nix`, host `configuration.nix`, hardware entrypoints | Owns boot, services, system packages, security, drivers, and system policy. |
| Home Manager module | User-profile evaluation | `home/livara/session.nix`, `themes.nix`, `applications.nix` | Owns user programs, user services, XDG files, and activation adapters. |
| Application data | Installed or transformed by a consumer | `xournal-conf/xournalpp/*`, icons, templates | Remains application-owned content rather than pretending to be system policy. |
| Runtime state | Created outside the store | QuickShell generated JSON, Matugen outputs, browser profiles | Is writable and must not be represented as an immutable store symlink. |

The repository should prefer one module per coherent concern, not one module per option. A composition module may intentionally expose no reusable options, but it should be documented as a composition root instead of being treated as a general feature.

## 3. Repository and input boundaries

`nix-conf` is the system composition root. `vim-conf` is the editor library. `xournal-conf` is an application-data repository. `mesa-tomate-driver` is a system feature for the tablet driver. The end-4 dotfiles source is an immutable data input, and QuickShell is a separate flake input that provides the runtime package.

| Repository or input | Public contract | Ownership |
|---|---|---|
| `nix-conf` | NixOS configurations, system features, Home Manager composition, scripts, and documentation | Host composition and cross-repository integration. |
| `xBLACKICEx/dots-hyprland` | Pinned non-flake source tree from branch `tmp` | Immutable end-4 QuickShell, Hyprland, Matugen, Fuzzel, Hyprlock, Wlogout, and script assets. |
| `outfoxxed/quickshell` | `packages.${system}.default` | QuickShell runtime package. |
| `vim-conf` | NixVim module library and package | Editor policy and NixVim composition. |
| `xournal-conf` | XML, INI, GPL, and TeX data | Versioned Xournal++ application data. |
| `mesa-tomate-driver` | NixOS module | Tablet service, udev integration, and typed driver options. |
| `zen-browser-flake` | Home Manager browser module | Zen Browser package and profile integration. |

The active flake does not import `shell-conf` or `dms-plugin-registry`. The old DMS/Niri files remain only in historical or archived locations when explicitly retained for reference; they are not evaluated by the active import list.

## 4. Composition root and host model

The root `flake.nix` is the evaluated composition boundary. Its import list is explicit, so adding a file to an archive or scratch directory cannot silently alter a system output.

```nix
imports = [
  ./modules/parts.nix
  ./modules/features/audiorelay.nix
  ./modules/features/desktop-portals.nix
  ./modules/features/development.nix
  ./modules/features/embedded.nix
  ./modules/features/firejail.nix
  ./modules/features/flatpak.nix
  ./modules/features/end4.nix
  ./modules/features/greeter.nix
  ./modules/features/hyprland.nix
  ./modules/features/keyd.nix
  ./modules/features/nvidia.nix
  ./modules/features/system-hardening.nix
  ./modules/features/containers.nix
  ./modules/features/virtualization.nix
  ./modules/packages/core-packages.nix
  ./modules/hosts/common-desktop.nix
  ./modules/hosts/my-machine
  ./modules/hosts/latitude
];
```

The host roots intentionally share the same desktop and user profile. They differ in hardware, graphics, power, and machine-specific feature selection rather than carrying divergent shell implementations.

| Host | Shared layer | Host-specific layer |
|---|---|---|
| `latitude` | Hyprland/UWSM, end-4, Home Manager, NixVim, applications, themes, Xournal++, development, containers, security, Flatpak, audio, and keyd | Dell Latitude hardware, ext4 root, Intel graphics, laptop power policy, and tracked ESP/swap configuration. |
| `myMachine` | The same desktop and user profile as Latitude | AMD microcode, Btrfs root with `@`, `home`, and `nix` subvolumes, desktop hardware, NVIDIA and virtualization policy. |

`modules/hosts/common-desktop.nix` is a composition module. It imports Home Manager, the local Hyprland NixOS module, the local end-4 Home Manager module, and the reusable NixVim module. It exposes `desktop.profile.userName` so the user identity is passed into the profile rather than hard-coded inside reusable features.

## 5. System feature boundaries

The feature directory contains system-level capabilities. A feature should not own a user-specific file when the corresponding concern belongs in Home Manager, and a user module should not silently enable system drivers or privileged services.

| File | Layer and responsibility |
|---|---|
| `modules/features/hyprland.nix` | Enables Hyprland through the official NixOS module path, sets `withUWSM = true`, installs compositor-level screenshot and Wayland tools, and publishes the Home Manager cursor/session boundary. |
| `modules/features/end4.nix` | Home Manager adapter for the pinned end-4 source. Links immutable assets, provides QuickShell and Qt runtime packages, and seeds writable runtime directories without symlinking generated state into the store. |
| `modules/features/greeter.nix` | SDDM, Clockwork theme, cursor, keyring, and the `hyprland-uwsm` default session. |
| `modules/features/desktop-portals.nix` | Portals, GTK fallback, polkit, UDisks, and keyring prerequisites. The Hyprland portal is preferred for the Hyprland session with GTK as fallback. |
| `modules/features/development.nix` | Shared Python/Manim, native, web, Go, Rust, language-server, and build tools. Project-specific versions remain in project shells. |
| `modules/features/embedded.nix` | Arduino, PlatformIO, OpenOCD, probe-rs, serial tools, and narrowly scoped device access. |
| `modules/features/containers.nix` | Rootless Docker, Compose, Buildx, and user-facing container tools without requiring a privileged Docker group. |
| `modules/features/virtualization.nix` | libvirt, QEMU/KVM, SPICE, virt-manager, and access for the declared VM operator. |
| `modules/features/flatpak.nix` | Flatpak remotes, installed applications, update policy, and environment overrides. |
| `modules/features/system-hardening.nix` | Firewall, audit, kernel restrictions, journald policy, boot restrictions, and related security controls. |
| `modules/features/firejail.nix` | Firejail support and application sandbox integration. |
| `modules/features/audiorelay.nix` | Audio relay and related service policy. |
| `modules/features/keyd.nix` | Key remapping daemon and its system service. |
| `modules/features/nvidia.nix` | NVIDIA-specific system policy selected by the relevant host. |
| `modules/packages/core-packages.nix` | Shared system package baseline and compatibility packages. |

The separation is adaptive rather than ceremonial. For example, a screenshot binary is a system package because both the compositor bindings and user scripts need it, while a QuickShell IPC binding is a Home Manager concern because it belongs to the user session.

## 6. End-4, Hyprland, and UWSM architecture

### 6.1 Ownership model

Hyprland owns compositor semantics: input, focus, workspace behavior, window rules, monitor handling, and dispatch commands. UWSM owns the lifecycle of the desktop session launched from the display manager. QuickShell owns the shell surface: bars, overview, session menu, notifications, widgets, settings, and shell-specific state. Matugen owns runtime palette transformation.

| Concern | Owner |
|---|---|
| Login session and compositor package | `programs.hyprland` with `withUWSM = true` in `hyprland.nix` |
| User-session lifecycle integration | UWSM; Home Manager sets `wayland.windowManager.hyprland.systemd.enable = false` |
| Immutable end-4 assets | `inputs.illogical-impulse-dotfiles` through `end4.nix` |
| QuickShell executable | `inputs.quickshell.packages.${system}.default` |
| QuickShell profile | `ii`, selected with `QS_CONFIG` and `$qsConfig` |
| Local compositor overrides | `home/livara/session.nix` and generated `~/.config/hypr/nix-conf.conf` |
| Shell runtime state | `~/.local/state/quickshell/user/generated/` |
| System portal and polkit prerequisites | NixOS feature modules |
| User authentication agent | One end-4 startup command adapted to the Nix store executable |

The integration deliberately does not run the end-4 installer. It links the source assets that are safe to keep immutable, creates local runtime directories, and applies local overrides after the upstream configuration. This makes the two hosts share the same shell while keeping host hardware policy outside the shell source tree.

### 6.2 Why Hyprland replaces Niri

Niri and DMS previously divided compositor and shell responsibilities across a user policy, a public shell-conf output, a DMS registry, and a compatibility bridge. That arrangement had too many lifecycle owners and made the shell behavior dependent on the exact adapter version. The end-4 ecosystem is authored for Hyprland and QuickShell. Keeping Niri would therefore require a second compositor-specific translation layer and would discard the upstream end-4 configuration model.

Hyprland is the adaptive choice because it matches the end-4 source, provides a supported NixOS module path, integrates with UWSM, and exposes dispatches that can be used from the existing shortcut compatibility file. The migration is not a blind compositor swap: every previous Niri action was classified as a shell action, compositor action, application launch, or screenshot action and moved to the appropriate owner.

### 6.3 Shortcut migration

The upstream end-4 keybindings are sourced first. `session.nix` then writes a compatibility fragment that unbinds conflicting defaults and restores the shortcuts users already relied on.

| Previous action | New owner and implementation |
|---|---|
| Former DMS settings action | `qs -p ~/.config/quickshell/$qsConfig/settings.qml` |
| Former DMS power-menu action | `qs -c $qsConfig ipc call sessionToggle` |
| Former DMS dashboard/launcher action | `qs -c $qsConfig ipc call overviewToggle` |
| Former DMS clipboard action | `qs -c $qsConfig ipc call overviewClipboardToggle` |
| Former DMS keybind-overlay action | `qs -c $qsConfig ipc call cheatsheetToggle` |
| ZenNotes | Application launch through `zennotes` |
| Window focus and close | Hyprland `movefocus` and `killactive` dispatchers |
| Region screenshot | `grim -g "$(slurp)" - \\| satty ...` |
| Fullscreen and active-window screenshot | `grimblast` with copy/save actions |
| Wallpaper selection | end-4 `switchwall.sh`, with `--image` for login selection |

The local fragment intentionally does not reimplement the complete end-4 keymap. It only resolves collisions and preserves behavior that was part of the previous nix-conf contract.

## 7. Theme architecture

Matugen is the sole runtime palette generator. This avoids a conflict in which DMS, Stylix, QuickShell, and a browser theme each generate different versions of the same colors. Static visual identity such as the cursor, icon theme, and profile icon remains declarative and is not confused with wallpaper-derived runtime state.

| Theme artifact | Authority | Consumer |
|---|---|---|
| QuickShell `colors.json` | Matugen output in user state | QuickShell end-4 profile |
| Hyprland and Hyprlock colors | Matugen output in user config | Hyprland and Hyprlock |
| GTK 3/4 CSS | Matugen output in user config | GTK applications and Nautilus |
| Fuzzel and KDE color files | Matugen output | Fuzzel and Qt/KDE integration |
| Firefox CSS | Local Matugen template to stable user state | Firefox profiles |
| Zen Browser CSS | Local Matugen template to stable user state | Zen profiles |
| ZenNotes CSS | Local Matugen template to stable user state | ZenNotes theme |
| Xournal++ settings and toolbar | `xournal-conf` data and user edits | Xournal++ |
| NixVim appearance | NixVim module and its palette adapter | Neovim |

`home/livara/themes.nix` owns templates and links browser profiles to stable state files. It does not symlink generated CSS to a Nix store path. The activation hook backs up an existing regular `userChrome.css` before replacing it with a link to the runtime theme. GTK files are generated in the user configuration directory and imported by Flatpak Nautilus through `~/.var/app`.

The Xournal++ boundary is intentionally different. Its semantic toolbar and settings data must remain editable by the application and reviewable in `xournal-conf`. Matugen supplies the desktop GTK palette; it does not rewrite the entire Xournal++ settings file on every activation.

## 8. Home Manager and application architecture

`home/livara/home.nix` is a thin profile entrypoint. It sets identity, state version, environment variables, profile icon, and imports the user modules. It does not own compositor policy directly.

| File | Responsibility and stability boundary |
|---|---|
| `home/livara/session.nix` | Hyprland settings, input, UWSM-compatible systemd behavior, QuickShell compatibility bindings, idle policy, screenshot directory, and wallpaper startup. |
| `home/livara/themes.nix` | Matugen templates, browser CSS adapters, GTK imports, ZenNotes manifest/configuration, and theme activation. |
| `home/livara/applications.nix` | Applications, MIME handlers, Zen Browser, NixVim, Xournal++ staging, and XDG directories. |
| `home/livara/sync.nix` | Independent wallpaper and Vault synchronization services and timers. Network failure does not block a local rebuild. |
| `home/livara/appimage.nix` | Firejail AppImage desktop handler with private home, dropped capabilities, seccomp, and no network by default. |

### 8.1 NixVim

The NixVim boundary is structurally sound. `vim-conf` publishes a reusable NixVim module, and `nix-conf` imports it through `programs.nixvim.imports`. Editor behavior, plugins, language tooling, keymaps, and Lua policy belong to `vim-conf`; host hardware and shell concerns do not.

The main NixVim risk is input compatibility rather than module design. The flake lock must be refreshed and both host evaluations must be run when NixVim or nixpkgs revisions change. A runtime palette adapter may consume generated colors, but editor evaluation must not require QuickShell or Matugen to be running.

### 8.2 Xournal++

`xournal-conf` is correctly modeled as application data. The flow is:

```text
xournal-conf/xournalpp/*
  -> local editable staging under ~/.config/nixos/xournalpp
    -> out-of-store links under ~/.config/xournalpp
      -> Xournal++ runtime
```

The staging files are seeded only when absent so the Xournal++ interface can edit them without Home Manager overwriting changes. `scripts/sync-xournalpp-config.sh` copies reviewed `settings.xml` and `toolbar.ini` changes back to the separate repository. The black page background, dark mode, Tokyo Night highlighter, fine eraser, and corrected toolbar separators remain application configuration rather than Matugen-generated desktop policy.

## 9. Hardware and installer architecture

The stable hardware entrypoint is `modules/hosts/<host>/hardware.nix`. It imports the tracked `hardware-configuration.nix` and adds only host-specific microcode or graphics policy. The generated file is the machine-specific data boundary; it is not a temporary sidecar and must not remain untracked.

`scripts/generate-hardware.sh` is the single generator for both hosts. It accepts `--host latitude|myMachine`, `--repo`, `--target-root`, `--esp`, `--source`, and `--dry-run`. It detects the mounted installed root conservatively, distinguishes ext4 from Btrfs, validates the ESP, invokes `nixos-generate-config` when possible, and uses mounted kernel topology as a non-destructive Btrfs fallback when subvolume probing fails.

| Property | Latitude | myMachine |
|---|---|---|
| Root filesystem | ext4 | Btrfs |
| Root device | `/dev/sda2` in the current installation | Same filesystem UUID with subvolume layout |
| ESP | Existing vfat ESP, currently `/dev/sda1` | Host-specific existing ESP |
| Subvolume handling | None; no Btrfs options emitted | Preserves `@`, `home`, and `nix` mount options |
| Generated contract | `modules/hosts/latitude/hardware-configuration.nix` | `modules/hosts/my-machine/hardware-configuration.nix` |

The installer at `install.sh` runs from its own checkout, which is expected to be `~/.config/nixos`. It selects the host, calls the unified generator, preserves the exact hardware exit code, runs an automatic sanitized Latitude diagnostic only after a failure, executes `nix flake check --no-build`, and rebuilds only after the validation gate succeeds. It uses locked inputs by default; `NIX_CONF_UPDATE_FLAKE=1` is an explicit opt-in to update them.

The installer does not format disks, partition storage, unlock encrypted devices, modify firmware, guess among ambiguous roots, or add ACPI kernel parameters. ACPI firmware messages must be investigated as hardware or firmware symptoms rather than silenced by speculative boot flags.

## 10. Security and stability assessment

The system contains meaningful controls: firewall policy, audit rules, kernel pointer and dmesg restrictions, journald limits, boot-entry limits, zram, Firejail support, rootless containers, and narrow device permissions. These controls improve the default posture but do not make the workstation automatically secure.

| Area | Assessment | Current decision |
|---|---|---|
| Shell lifecycle | The former DMS/Niri integration had overlapping owners and private input boundaries. | One UWSM compositor lifecycle, one end-4 QuickShell startup, and one Home Manager session adapter. |
| Runtime state | QuickShell and Matugen must write after activation. | Mutable state is isolated under user state/config paths, never represented as store symlinks. |
| Hardware safety | Automatic hardware generation can be destructive if it formats or guesses. | Detection is mount-based, non-destructive, validates devices, and refuses ambiguity. |
| Audit service | Immutable audit mode prevents later rule reloads. | `security.audit.enable = true` is used rather than a literal immutable lock mode. |
| Containers | A privileged Docker group would weaken the boundary. | Rootless Docker and per-user tooling remain the default. |
| AppImages | Arbitrary AppImages can write to the user home. | Firejail handler uses a private home, dropped capabilities, seccomp, and no network. |
| Network synchronization | Activation-time network work can break rebuilds. | Wallpaper and Vault synchronization run as independent user services and timers. |
| Trusted users | Broad trusted-user settings can weaken the Nix trust boundary. | Review separately; this shell refactor does not silently change policy. |
| Nix inputs | Unlocked or stale inputs reduce reproducibility. | Keep `flake.lock` under review and update intentionally. |

The main remaining operational risk is the unavailable Nix validation gate in the analysis sandbox. The target NixOS checkout must run `nix flake lock`, `nix flake check --no-build`, and host builds before switching to the new generation.

## 11. File-level architecture

| File or directory | Role in the active architecture |
|---|---|
| `flake.nix` | Public inputs and explicit evaluated import boundary. |
| `flake.lock` | Reproducibility record for all system, user, browser, editor, QuickShell, and end-4 dependencies. |
| `modules/parts.nix` | Shared flake-parts outputs and host list. |
| `modules/features/hyprland.nix` | NixOS Hyprland/UWSM boundary and compositor-level packages. |
| `modules/features/end4.nix` | Home Manager end-4 source adapter and writable runtime seed. |
| `modules/features/greeter.nix` | SDDM and `hyprland-uwsm` login session. |
| `modules/features/desktop-portals.nix` | Portal, polkit, UDisks, and keyring prerequisites. |
| `modules/features/development.nix` | General programming capabilities and toolchains. |
| `modules/features/embedded.nix` | Embedded development tools and device permissions. |
| `modules/features/containers.nix` | Rootless Docker and Compose capability. |
| `modules/features/virtualization.nix` | libvirt/QEMU/KVM and virt-manager capability. |
| `modules/features/system-hardening.nix` | Security and audit policy. |
| `modules/hosts/common-desktop.nix` | Shared NixOS/Home Manager composition and user identity option. |
| `modules/hosts/latitude/default.nix` | Latitude system root and host-specific policy. |
| `modules/hosts/latitude/hardware.nix` | Latitude hardware entrypoint. |
| `modules/hosts/latitude/hardware-configuration.nix` | Tracked Latitude filesystems, boot modules, swap, and CPU data. |
| `modules/hosts/my-machine/default.nix` | myMachine system root and host-specific policy. |
| `modules/hosts/my-machine/hardware.nix` | myMachine hardware entrypoint and AMD microcode. |
| `modules/hosts/my-machine/hardware-configuration.nix` | Tracked Btrfs filesystems, subvolumes, boot modules, swap, and CPU data. |
| `home/livara/home.nix` | Thin Home Manager profile entrypoint. |
| `home/livara/session.nix` | Hyprland settings, shortcut compatibility, screenshots, idle, and wallpaper startup. |
| `home/livara/themes.nix` | Matugen outputs and browser/GTK/ZenNotes adapters. |
| `home/livara/applications.nix` | Applications, NixVim, Xournal++, MIME, and XDG integration. |
| `home/livara/sync.nix` | Independent repository synchronization services and timers. |
| `scripts/generate-hardware.sh` | Unified ext4/Btrfs detection, generation, validation, backup, and staging. |
| `scripts/collect-latitude-diagnostic.sh` | Sanitized Latitude diagnostic collection and optional upload. |
| `scripts/sync-xournalpp-config.sh` | Explicit reviewed Xournal++ push/pull helper. |
| `install.sh` | Host selection, hardware gate, flake gate, and rebuild orchestration. |
| `docs/xournalpp-matugen.md` | Xournal++ ownership and synchronization documentation. |
| `docs/end4-integration-research.md` | External source facts and integration contract record. |
| `archive/` | Historical material outside the evaluated module tree. |

Unnecessary legacy scripts for the old Latitude-specific hardware flow and DMS asset synchronization are deleted. The active scripts have one purpose each and pass Bash syntax checks.

## 12. Validation model

The validation sequence is intentionally layered. Cheap checks run first; Nix evaluation and builds run before a system switch.

```bash
git diff --check
find scripts -maxdepth 1 -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
nix flake lock
nix flake check --no-build
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
sudo nixos-rebuild test --flake .#latitude
```

The hardware generator should be tested independently with `--dry-run` and with ext4/Btrfs fixtures before a real rebuild. The installer must never proceed to `nixos-rebuild` when hardware generation or the flake check fails.

## 13. Design principles

The repository should continue to use explicit composition roots, one owner per runtime concern, public contracts between repositories, and typed options for meaningful variation. System modules own privileged services and machine policy. Home Manager modules own user files and user services. Runtime-generated data stays outside the Nix store. Application repositories remain data repositories. Network maintenance runs independently from activation. External source instructions are treated as reference data and are never executed as installers.

This architecture is more stable than the former shell design because it matches the end-4 source model, removes DMS/Niri lifecycle overlap, keeps host differences typed by composition, and makes mutable state visible instead of accidentally hiding it behind store links.

## References

[1]: https://nixos.org/manual/nixos/stable/#sec-writing-modules "NixOS manual — writing modules"
[2]: https://home-manager.dev/manual/ "Home Manager manual"
[3]: https://flake.parts/ "flake-parts"
[4]: https://github.com/xBLACKICEx/dots-hyprland/tree/tmp "end-4 illogical-impulse source"
[5]: https://github.com/xBLACKICEx/end-4-dots-hyprland-nixos "end-4 NixOS adapter"
[6]: https://git.outfoxxed.me/outfoxxed/quickshell "QuickShell source"
[7]: https://wiki.hypr.land/Nix/Hyprland-on-NixOS/ "Hyprland on NixOS"
[8]: https://github.com/InioX/matugen "Matugen"
[9]: https://github.com/nix-community/nixvim "NixVim"
[10]: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-generate-config.pl "nixos-generate-config source"
[11]: https://man7.org/linux/man-pages/man8/lsblk.8.html "lsblk manual"
[12]: https://man7.org/linux/man-pages/man8/findmnt.8.html "findmnt manual"
[13]: https://xournalpp.github.io/guide/file-locations/ "Xournal++ file locations"
[14]: https://github.com/end-4/dots-hyprland/discussions/1093 "end-4 discussion referenced by the integration brief"
[15]: https://github.com/ilyamiro/serpantinum "serpantinum reference"
[16]: https://github.com/end-4/CirnOS "CirnOS reference"
