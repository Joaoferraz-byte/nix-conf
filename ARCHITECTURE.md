# Architecture Review and Refactoring Record

## 1. Scope and conclusion

This repository is a declarative NixOS workstation configuration composed from flake-parts modules, NixOS modules, Home Manager modules, external flakes, and application-owned data. The architecture is real and modular, but its previous boundaries were not consistently enforced. The main problem was not that the repository lacked modules; it was that some files were modules of the wrong layer, some outputs were duplicated, and several runtime concerns had more than one owner.

This revision makes the evaluated surface explicit, separates the common desktop profile from host identity, keeps DMS as a user-session authority, exposes Niri through a public shell-conf output, and treats Xournal++ configuration as data rather than a fake Nix module. It also splits the Home Manager profile into lifecycle-oriented modules and removes explanatory comments from active Nix code. Active source comments are limited to short English category headings.

The target is a single-direction architecture:

```text
flake inputs
  -> public flake outputs
    -> host composition roots
      -> NixOS system features
        -> shared desktop boundary
          -> Home Manager user profile
            -> application adapters and runtime services
```

The dependency direction is deliberate. Hosts may select features. Features may consume stable public outputs from external repositories. User profiles may consume application data and Home Manager modules. A low-level application module should not reach into a host's private implementation or into the internal inputs of another flake.

## 2. What is a module?

A NixOS or Home Manager module is an expression evaluated by the Nix module system. It may declare typed options, import other modules, and define values for the combined configuration. A module is therefore more than a file containing Nix syntax and more than a convenient place to store settings.

> A module has a coherent responsibility, a well-defined evaluation layer, and an explicit contract with the modules that consume it.

The canonical module shape is based on `imports`, `options`, and `config`. A reusable feature should expose options when consumers need to vary behavior. A fixed composition root may intentionally expose no options, but it should remain a composition module rather than pretending to be a reusable feature. Static XML, CSS, JSON, images, palettes, and templates are data inputs. They become part of a module only when a module declares how they are installed, generated, or adapted.

The repository uses four different kinds of Nix expressions:

| Kind | Evaluation layer | Examples | Architectural responsibility |
|---|---|---|---|
| flake-parts module | Flake evaluation | `modules/parts.nix`, feature files, host `default.nix` files | Publishes outputs and composes systems. |
| NixOS module | System evaluation | `features/flatpak.nix`, `features/dms-system.nix`, host `configuration.nix` | Declares services, packages, boot, hardware, security, and system policy. |
| Home Manager module | User-profile evaluation | `home/livara/session.nix`, `themes.nix`, `applications.nix` | Declares user services, programs, XDG files, and activation behavior. |
| Data input | Installed or transformed by a consumer | `xournal-conf/xournalpp/*`, icons, wallpapers | Provides application-owned content without pretending to be a module. |

This distinction is more important than the number of files. Splitting one concern into many files does not create modularity if all of them still depend on the same private state.

## 3. Repository boundaries

The repositories form a small configuration platform rather than one monolithic repository. `nix-conf` is the system composition root. `shell-conf` publishes the DMS/Niri session integration. `vim-conf` publishes a reusable NixVim module and a standalone editor package. `xournal-conf` publishes application data. `mesa-tomate-driver` publishes a NixOS hardware/service module.

| Repository | Public contract | Correct boundary |
|---|---|---|
| `nix-conf` | NixOS configurations and system modules | Owns host composition, system policy, user-profile selection, and cross-repository integration. |
| `shell-conf` | `nixosModules.niri`, `nixosModules.dankMaterialShell`, `overlays.niri`, and Home Manager modules | Owns the packaging and user-session integration of DMS and Niri. |
| `vim-conf` | `lib.nixvimModule`, `lib.nixvimModules.default`, package, and check | Owns editor policy and NixVim composition. |
| `xournal-conf` | Versioned XML, INI, GPL, and TeX data | Owns Xournal++ data, not host or system policy. |
| `mesa-tomate-driver` | `nixosModules.default` | Owns the tablet service, udev integration, and its own typed options. |

The consumer should use these public contracts. It should not navigate through `inputs.shell-conf.inputs.niri` or through another repository's private module tree. The refactor changes the Niri overlay consumption to `inputs.shell-conf.overlays.niri`.

## 4. Evaluated composition

The root `flake.nix` now imports the evaluated surface explicitly:

```nix
imports = [
  ./modules/parts.nix
  ./modules/features/audiorelay.nix
  ./modules/features/desktop-portals.nix
  ./modules/features/dms-system.nix
  ./modules/features/firejail.nix
  ./modules/features/flatpak.nix
  ./modules/features/greeter.nix
  ./modules/features/keyd.nix
  ./modules/features/niri.nix
  ./modules/features/nvidia.nix
  ./modules/features/system-hardening.nix
  ./modules/packages/core-packages.nix
  ./modules/hosts/common-desktop.nix
  ./modules/hosts/my-machine
  ./modules/hosts/latitude
];
```

This list is intentionally explicit. A new file placed in `archive/` or a future scratch directory cannot silently become an evaluated output. Historical material now lives in `archive/`, outside the evaluated module tree.

The two host roots are:

| Host | Composition |
|---|---|
| `myMachine` | Common desktop profile, desktop-specific configuration, hardware, Mesa-Tomate driver, system packages, GPU, portals, Flatpak, audio, keyd, hardening, and firejail. |
| `latitude` | Common desktop profile, laptop configuration, hardware, laptop-specific power and graphics policy, system packages, portals, Flatpak, audio, keyd, hardening, and firejail. |

`modules/hosts/common-desktop.nix` is a composition module, not a feature. It imports Home Manager, the shared DMS system bridge, Niri, the DMS plugin registry, and the shared NixVim module. It also provides a typed `desktop.profile.userName` option and passes that identity to the DMS bridge.

## 5. DMS and Niri: contextual architecture

### 5.1 Ownership model

DankMaterialShell is a complete Wayland desktop shell, not merely a status bar. It owns user-session presentation, widgets, shell state, runtime theme generation, plugins, and its user service. Niri owns compositor semantics: input, layout, window rules, startup commands, and compositor keybindings. NixOS owns system prerequisites such as portals, polkit, power services, packages, and hardware support.

The correct ownership model is therefore:

| Concern | Owner |
|---|---|
| DMS service, session settings, plugins, dynamic palette | `shell-conf` Home Manager modules and `home/livara/session.nix` |
| Niri compositor settings | `home/livara/session.nix` through the published Niri Home Manager contract |
| Niri system module and package overlay | `shell-conf` public NixOS module and `shell-conf.overlays.niri` |
| Quickshell, Matugen, Cava, Khal, NetworkManager and GLib prerequisites | `nix-conf/modules/features/dms-system.nix` |
| Polkit, geolocation, accounts and power service defaults | NixOS feature modules, with host overrides taking precedence |
| DMS plugin source installation | `dms-system.nix`, derived from the selected user's declared plugin sources |

The upstream DMS NixOS and Home Manager modules have historically exposed overlapping systemd options. Importing both as enabled lifecycle owners can produce option conflicts or duplicate DMS instances. The current configuration consequently uses the `shell-conf` Home Manager module for the user-facing DMS service and a small NixOS bridge for prerequisites and plugin source installation. The upstream DMS NixOS module is not imported by the active hosts.

### 5.2 What was wrong before

The previous design had four issues. First, the host assembly accessed `inputs.shell-conf.inputs.niri.overlays.niri`, which crossed a private input boundary. Second, `dms-system.nix` hard-coded `livara` and reached into `home-manager.users.livara.programs.dank-material-shell`. Third, the Home Manager profile declared a second `systemd.user.services.dms` lifecycle block and manually restarted DMS during activation even though the upstream Home Manager module already owns that service. Fourth, the `shell-conf` flake exposed a local file as a NixOS module even though that file was Home Manager-oriented and did not represent a valid NixOS contract.

The DMS implementation was therefore not conceptually hopeless, but it was poorly layered and fragile. It mixed a compatibility bridge with lifecycle ownership. The refactor keeps the bridge because the upstream conflict is real, but limits it to system prerequisites and plugin sources, parameterizes the user identity, and leaves service lifecycle to the Home Manager DMS module.

### 5.3 Niri configuration ownership

Niri configuration is declared through the Niri Home Manager module in `home/livara/session.nix`. The NixOS feature imports the published Niri NixOS module and enables the compositor at the system boundary. This avoids declaring `programs.niri` without first importing the module that defines its options.

The current configuration still uses a small activation reload hook and a startup command for Xwayland Satellite and the wallpaper. Those are runtime adapters, not a second Niri configuration owner. Any future DMS include mechanism must not also own `~/.config/niri/config.kdl`; one mechanism must be selected and documented.

## 6. Theme architecture

The themes were not fully standardized before the refactor. They were coherent as a practical hybrid, but the authority boundaries were implicit. DMS/Matugen generated runtime colors, Firefox and Zen received symlinked DMS CSS, GTK loaded DMS-generated CSS, ZenNotes received a Matugen template, and Xournal++ used a static Tokyo Night palette. NixVim consumed a DMS-generated Base46 colorscheme at runtime. Fonts, cursors, icons, and login assets were separate stable identity settings.

This is not automatically a defect. Dynamic wallpaper-derived colors and static application palettes are different contracts. The defect would be allowing Stylix and DMS/Matugen to generate the same target independently. This repository intentionally keeps DMS/Matugen as the runtime color authority and does not introduce Stylix as a competing color authority.

The refactored theme model is:

| Theme category | Authority | Consumers |
|---|---|---|
| Runtime palette | DMS and Matugen | DMS, GTK, Firefox, Zen, ZenNotes, NixVim adapter. |
| Stable appearance identity | Home Manager and package declarations | Fonts, cursors, icons, profile icon, login assets. |
| Application-specific static theme | Application repository | Xournal++ Tokyo Night palette and templates. |
| Editor runtime adapter | DMS-generated Base46 file consumed by `vim-conf` | NixVim colorscheme `dms`. |

`home/livara/themes.nix` now owns the theme adapters and generated template declarations. `applications.nix` owns application installation and Xournal++ data mapping. This prevents the application module from also becoming the theme authority.

### 6.1 Remaining theme stability considerations

DMS-generated CSS is mutable runtime output, while Home Manager-managed links are declarative references. That boundary is acceptable only because the generated file is intentionally produced outside the Nix store. The current design should not be described as fully immutable. A future hardening pass may replace direct out-of-store links with DMS-supported templates or a dedicated user service, but it must preserve one runtime generator.

Xournal++ remains static because its palette and template formats are application-owned. The consumer seeds `settings.xml` and `toolbar.ini` into `~/.config/nixos/xournalpp` only when they do not already exist, with the profile prefix normalized to `config.home.homeDirectory`. Home Manager then exposes those user-owned files through out-of-store links. This preserves a portable versioned baseline while allowing deliberate application edits. `scripts/sync-xournalpp-config.sh` copies reviewed local changes back to the xournal-conf checkout.

## 7. NixVim architecture

The NixVim boundary is one of the stronger parts of the system. `vim-conf` publishes `lib.nixvimModule`, and `nix-conf` imports it inside `programs.nixvim.imports`. That is the correct layer: the editor library owns editor options, plugins, keymaps, language tooling, UI behavior, and controlled Lua escape hatches. The host should not duplicate those policies.

The NixVim repository also publishes a standalone package and a check. Its plugin aggregation is real module composition rather than an arbitrary collection of files. The main compatibility risk is input lineage: NixVim is tested against a specific nixpkgs revision, so forcing follows relationships must be intentional. The current `vim-conf` input contract remains separate and is not rewritten to force a new nixpkgs relationship.

The DMS colorscheme is an explicit runtime adapter. It does not make the editor architecture unsound because the editor still builds declaratively and only the palette file is runtime-generated. The adapter should remain small; editor behavior must not depend on DMS being available during Nix evaluation.

## 8. Xournal++ architecture

`xournal-conf` is correctly modeled as a data repository. Its files are application-owned XML, INI, GPL, and TeX assets. They do not need `options`, `config`, or a flake output. `nix-conf` installs those assets through a focused Home Manager application module.

The important separation is:

```text
xournal-conf data
  -> applications.nix path and installation adapter
    -> Xournal++ runtime configuration
```

The refactor avoids promoting Xournal++ data into a NixOS feature. It also removes the consumer's hard dependency on `/home/livara` when installing the palette and LaTeX template. Device-class entries such as `MTM-1106 Pen` remain application configuration because the Mesa-Tomate driver owns device activation and Xournal++ owns input-class behavior.

## 9. Security and stability assessment

The current configuration contains meaningful security and reliability controls. It enables a firewall, restricts kernel pointers and dmesg access, configures audit rules, limits boot entries, configures zram, caps journald retention, enables Firejail support, and separates system packages from user packages. These are useful controls, but their presence does not make the system automatically secure.

| Area | Assessment | Refactor decision |
|---|---|---|
| DMS lifecycle | Previously duplicated and coupled to a hard-coded user. | Keep one Home Manager owner; retain only a small NixOS prerequisite bridge. |
| Niri evaluation | Previously relied on an undeclared or private Niri path. | Import the public Niri module through `shell-conf` and consume its public overlay. |
| Theme state | Runtime output is intentionally mutable. | Keep DMS/Matugen as the only runtime palette authority and document the boundary. |
| Home Manager activation | Network-dependent cloning and `git pull` made activation slow and failure-prone. | Moved synchronization to independent user services and timers. |
| Trusted users | A broad trusted-user setting can weaken the trust boundary. | Do not silently change it in this structural refactor; review it separately. |
| Hardening module | The feature combines security policy with some desktop assumptions. | Preserve current behavior; split security policy from desktop defaults in a later pass. |
| NixVim | Main risk is upstream nixpkgs compatibility, not module structure. | Preserve the library boundary and validate its package/check independently. |
| Xournal++ | Versioned defaults and user edits have different ownership. | Seed editable local settings, normalize their profile path, and provide an explicit sync-back helper. |
| Wallpapers and Vault | The repositories use network access and Vault uses SSH. | Synchronize through independent timers; consider making Vault opt-in under stricter trust policies. |

The highest stability risk was not the number of modules. It was doing network synchronization and mutable runtime repair during a declarative activation transaction. Wallpaper and Vault synchronization now run as independent user services on timers, so network failure does not prevent a local system rebuild. Vault access remains SSH-based and should still be made explicitly opt-in if the machine is used offline or under a restricted trust policy.

## 10. File-level architecture after refactoring

| File or directory | Role after refactoring |
|---|---|
| `flake.nix` | Explicit flake-parts import boundary and inputs. |
| `modules/parts.nix` | Shared flake-parts system list. |
| `modules/features/niri.nix` | NixOS adapter for the public Niri module and session packages. |
| `modules/features/dms-system.nix` | System prerequisites and plugin source bridge; no DMS lifecycle owner. |
| `modules/features/flatpak.nix` | Single Flatpak feature; the duplicate package definition was removed. |
| `modules/hosts/common-desktop.nix` | Shared NixOS/Home Manager composition and user identity option. |
| `modules/hosts/my-machine/default.nix` | Desktop host root, overlay selection, hardware-specific modules. |
| `modules/hosts/latitude/default.nix` | Laptop host root, overlay selection, laptop-specific modules. |
| `home/livara/home.nix` | Thin Home Manager entrypoint and user identity. |
| `home/livara/session.nix` | Niri settings, DMS session settings, wallpaper startup adapter. |
| `home/livara/themes.nix` | DMS/Matugen adapters and browser/GTK/ZenNotes integration. |
| `home/livara/applications.nix` | Applications, XDG associations, NixVim import, and Xournal++ baseline/edited-data adapter. |
| `home/livara/sync.nix` | Wallpaper and Vault repository synchronization. |
| `shell-conf/flake.nix` | Public NixOS, Home Manager, and Niri overlay contracts. |
| `vim-conf/flake.nix` | Public NixVim library/package/check contract. |
| `xournal-conf/xournalpp/*` | Versioned application data. |
| `archive/` | Historical material outside the evaluated module tree. |

## 11. Refactoring principles

The repository should continue to use one module per coherent concern, not one file per option. A host root may compose many features, but a feature should not assume a particular host name, disk layout, user name, or desktop session unless that assumption is expressed as an option.

System modules should own system services and prerequisites. Home Manager modules should own user services and user files. Cross-layer adapters should be narrow and typed. Runtime-generated files should be isolated from store-managed files. External repositories should expose stable outputs, and consumers should never reach through `inputs.<flake>.inputs` to obtain a private implementation detail.

The repository should prefer build-time validation for structured Niri and NixVim configuration, explicit activation ordering for unavoidable runtime adapters, and separate maintenance commands for network synchronization. These rules are more important than whether the directory tree contains ten or one hundred files.

## 12. Applied changes

The current refactor applied the following changes:

1. Replaced recursive module discovery with an explicit evaluated import list.
2. Moved historical modules from `modules/archive/` to `archive/`.
3. Removed the duplicate `modules/packages/flatpak.nix` definition.
4. Removed the unused `modules/homeManagerModules.nix` placeholder.
5. Published `shell-conf.overlays.niri` and consumed it from `nix-conf`.
6. Corrected `shell-conf.nixosModules.niri` so it exposes the upstream NixOS Niri module rather than a Home Manager-oriented local file.
7. Added the shared `commonDesktop` composition root and parameterized the desktop user identity.
8. Moved the DMS system bridge to `modules/features/dms-system.nix`, parameterized its user, and made plugin filtering null-safe.
9. Removed the duplicate DMS user service and activation-time restart from the Home Manager session.
10. Split the Home Manager profile into `applications.nix`, `session.nix`, `themes.nix`, and `sync.nix`.
11. Seeded editable Xournal++ settings locally, normalized their profile path at the consumer boundary, and retained a reviewed sync-back helper.
12. Removed verbose comments from active Nix files and translated remaining active comments and public descriptions to English.
13. Kept `vim-conf` as a reusable NixVim module library rather than moving editor policy into the system repository.
14. Moved Wallpapers and Vault synchronization out of Home Manager activation into independent user services and timers.
15. Removed the second wallpaper owner by allowing DMS to own runtime wallpaper selection.

## 13. Validation

The refactor was checked with repository status, path/reference checks, duplicate-output checks, balanced-delimiter checks, English active-source scans, and `git diff --check`. Nix 2.18 was installed in the sandbox for evaluation. The standalone `shell-conf` and `vim-conf` flakes passed `nix flake check --no-build`; the nix-conf host contracts also evaluated successfully with local overrides for the refactored inputs.

The following targeted evaluations passed for both desktop hosts where applicable:

```bash
nix eval .#nixosConfigurations.myMachine.config.system.stateVersion
nix eval .#nixosConfigurations.latitude.config.system.stateVersion
nix eval .#nixosConfigurations.myMachine.config.home-manager.users.livara.programs.dank-material-shell.enable
nix eval .#nixosConfigurations.myMachine.config.home-manager.users.livara.programs.niri.settings.prefer-no-csd
```

The broad `nix-conf flake check` traversal was interrupted by the sandbox while walking the complete output set; this is an environment limitation, not a reported Nix evaluation error. Before deployment, run the complete checks and builds on a normal Nix host:

```bash
nix flake lock
nix flake check --all-systems
nix build .#nixosConfigurations.myMachine.config.system.build.toplevel
nix build .#nixosConfigurations.latitude.config.system.build.toplevel
nix build github:Joaoferraz-byte/vim-conf#nixvim
```

The lock file has already removed stale inputs such as `import-tree`; it must be refreshed again after the dependent repositories receive their final commits so `nix-conf` points at their new revisions.

## References

[1]: https://nixos.wiki/wiki/NixOS_modules "NixOS Wiki — NixOS modules"
[2]: https://nixos.org/manual/nixos/stable/ "NixOS Manual — Writing NixOS modules"
[3]: https://home-manager.dev/manual/25.05/ "Home Manager Manual 25.05"
[4]: https://flake.parts/ "flake-parts — Introduction"
[5]: https://github.com/denful/import-tree "import-tree — Recursive Nix module imports"
[6]: https://danklinux.com/docs/dankmaterialshell/nixos-flake "DankMaterialShell — NixOS flake installation"
[7]: https://danklinux.com/docs/dankmaterialshell/application-themes "DankMaterialShell — Application themes"
[8]: https://github.com/sodiboo/niri-flake "sodiboo/niri-flake"
[9]: https://github.com/nix-community/nixvim "nix-community/nixvim"
[10]: https://nix-community.github.io/stylix/configuration.html "Stylix — Configuration"
[11]: https://github.com/AvengeMedia/DankMaterialShell/issues/1788 "DankMaterialShell issue #1788 — Niri/Home Manager integration"
[12]: https://github.com/srid/nixos-config "srid/nixos-config"
[13]: https://www.reddit.com/r/NixOS/comments/1e95b69/how_do_you_guys_organize_your_nix_config_files_i/ "Reddit — How do you organize your Nix configuration files?"
