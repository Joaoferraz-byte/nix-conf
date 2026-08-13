# Rebuild flow research record

## Findings confirmed from documentation

The Flake Parts Home Manager module exposes `flake.homeModules` and `flake.homeConfigurations`. It must be imported inside the `mkFlake` import list through `inputs.home-manager.flakeModules.home-manager`. The repository previously used the nonstandard `flake.homeManagerModules` output without importing that module, which caused an unknown-output warning; defining it from two feature files then caused the uniqueness error because raw flake outputs are unique unless a typed mergeable option is declared.

The correct local contract is therefore:

```nix
imports = [ inputs.home-manager.flakeModules.home-manager ];

flake.homeModules = {
  hyprland = ...;
  end4 = ...;
};
```

Consumers use `self.homeModules.hyprland` and `self.homeModules.end4` in Home Manager `sharedModules`.

For a Git flake, the source copied into the Nix store is based on the Git worktree and untracked files are not included. A dirty tree warning is not itself an evaluation failure, but a configuration file referenced by the flake must be tracked or otherwise made available through an input/path that Nix can copy. The local `xournalpp/` directory is not referenced by the flake; the profile consumes the `xournal-conf` flake input and only uses the local directory as a runtime synchronization target.

The documented `nixos-rebuild switch` flow evaluates/builds `config.system.build.toplevel`, creates a new system profile generation, updates the bootloader default, and activates the generation. `boot` builds and selects the next boot without activating now; `test` activates without adding a bootloader entry; `build` only builds; `dry-activate` reports activation changes; and `--rollback switch` activates the previous generation without rebuilding.

A safe repository workflow must therefore separate: preserving local changes, fetching/merging the intended revision, updating the lockfile only when explicitly requested, running `nix flake check --no-build`, evaluating the target system derivation, using `nixos-rebuild dry-activate` or `test` before `switch` when the change is high-risk, and retaining a rollback path.

## References

1. [Flake Parts core options](https://flake.parts/options/flake-parts.html)
2. [Flake Parts Home Manager module](https://flake.parts/options/home-manager.html)
3. [Flake Parts modules option](https://flake.parts/options/flake-parts-modules.html)
4. [Official NixOS Wiki: nixos-rebuild](https://wiki.nixos.org/wiki/Nixos-rebuild)
5. [Home Manager manual](https://nix-community.github.io/home-manager/)


## Nix command semantics

The Nix reference distinguishes `nix flake lock` from `nix flake update`: `lock` creates missing entries and does not update entries that are already locked, while `update` updates existing inputs and accepts selected input names. `nix flake check --no-build` still evaluates the flake and verifies the expected output types; it only skips building checks. It evaluates `nixosConfigurations.<name>.config.system.build.toplevel`, so a successful check is a structural/evaluation gate, not proof that activation succeeded. `nix eval --raw` is appropriate for printing a derivation path but does not build or activate it.

References:

6. [Nix Reference: nix flake check](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-check)
7. [Nix Reference: nix flake lock](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-lock)
8. [Nix Reference: nix flake update](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-update)
9. [Nix Reference: nix eval](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-eval)


## Bootstrap and evaluation flags

The official Nix 2.34 reference lists `--no-update-lock-file` under common flake-related options for `nix develop`, `nix flake check`, and `nix eval`. The installer can therefore pass the flag during development-shell bootstrap and evaluation gates to prevent implicit lockfile changes. The same reference documents that `nix flake check --no-build` evaluates the flake and checks output types while skipping builds, whereas `nix eval --raw` evaluates an expression and prints its string result. These commands are necessary gates but do not replace a build or activation test.

References:

10. [Nix Reference: nix develop](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-develop)
11. [Nix Reference: nix flake check](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-check)
12. [Nix Reference: nix eval](https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-eval)

## Runtime findings from the first real installer run

The first real `NIX_CONF_REBUILD_MODE=test ./install.sh` run exposed two installer defects that static checks could not catch:

1. The evaluator used `$flake#latitude.config...`. A flake reference must include the output namespace, so the correct installable is `$flake#nixosConfigurations.latitude.config.system.build.toplevel.drvPath`, with the host selected dynamically. The Nix reference describes `nix eval` as accepting an installable and resolving an attribute path within the flake; the NixOS system is under the `nixosConfigurations` output.[13]
2. The hardware generator combined `findmnt --list` and `--raw`. The util-linux manual documents both as output-format selectors; the local util-linux version rejects their combination. The stable scripted form is `findmnt --kernel --noheadings --raw --output TARGET,SOURCE,FSTYPE,OPTIONS`, followed by explicit field parsing.[14]

Both defects were corrected and regression-tested. The mock installer test now asserts the complete `nixosConfigurations.<host>` path, while the sandbox executes the exact `findmnt` command and verifies that mount records are produced.

The operational implication is important: `nix flake check` can pass while an installer-owned `nix eval` command is still malformed, because `flake check` validates the flake's declared outputs rather than arbitrary attribute paths assembled by shell code. The installer therefore needs its own gate test, and that test must run before `nixos-rebuild`.

13. [Nix Reference: nix eval](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-eval)
14. [findmnt(8) Linux manual](https://man7.org/linux/man-pages/man8/findmnt.8.html)

## QuickShell/Qt build failure

The real build failed while compiling QuickShell 0.2.0, before any NixOS activation. The dependency chain was `quickshell -> quickshell-wrapped -> home-manager-path -> home-manager-generation -> user-environment -> etc -> nixos-system`; the root cause was the CMake target `Qt6::WaylandClientPrivate` being absent, not a service or hardware problem.

The QuickShell upstream CMake intentionally links `Qt6::WaylandClientPrivate` for generated Wayland protocol modules and calls `Qt6::qtwaylandscanner`. The official installation guide states that the embedded QuickShell flake must follow the same nixpkgs as the host because mismatched system dependencies can cause crashes and other issues. It also documents `quickshell.packages.<system>.default` as the supported flake package.[15] [16]

A closely related nixpkgs failure was fixed upstream by correcting the Qt6 `find_package` handling in the affected CMake project, confirming that this class of error is generally a Qt package integration/version issue rather than a missing runtime package.[17]

The current nix-conf uses the QuickShell `master` flake with `inputs.nixpkgs.follows = "nixpkgs"`, while the failing derivation is version 0.2.0. The next correction must therefore verify the locked QuickShell revision and its Qt dependency graph, prefer a compatible tagged release or a known-good upstream revision, and avoid adding arbitrary Qt packages only to make CMake appear to configure. The end-4 module currently adds Qt runtime packages to `home.packages`, but that cannot repair a missing CMake imported target in the QuickShell build derivation itself.

15. [QuickShell installation and setup](https://quickshell.org/docs/v0.3.0/guide/install-setup/)
16. [QuickShell Wayland CMake integration](https://github.com/quickshell-mirror/quickshell/blob/master/src/wayland/CMakeLists.txt)
17. [Nixpkgs PR #455451: upstream Qt6 find_package fix](https://github.com/NixOS/nixpkgs/pull/455451)

The release comparison identified the precise compatibility fix. QuickShell v0.2.0 always placed `qt6.qtwayland` in `buildInputs`; its package therefore fails against the Qt 6.10 layout used by the current nixpkgs revision, where CMake does not expose the expected `Qt6::WaylandClientPrivate` imported target in that configuration. QuickShell v0.3.0 updates its Nix expression: it keeps `qt6.qtwayland` as a native build dependency for the Wayland scanner, but only adds it to runtime `buildInputs` when `qt6.qtbase.version < 6.10.0`. The project is therefore pinned to the upstream `v0.3.0` tag rather than applying an ad-hoc local CMake patch.

The end-4 QML source uses standard `Quickshell`, `Quickshell.Wayland`, `Quickshell.Hyprland`, `Quickshell.Widgets`, and service modules without an explicit 0.2-only API declaration in the audited tree. This makes the v0.3.0 tag the supported compatibility upgrade for the current dotfiles revision. The lockfile must be regenerated for the changed tag; it must not be hand-edited with an invented NAR hash.

18. [QuickShell v0.2.0 package expression](https://git.outfoxxed.me/quickshell/quickshell/raw/tag/v0.2.0/default.nix)
19. [QuickShell v0.3.0 package expression](https://git.outfoxxed.me/quickshell/quickshell/raw/tag/v0.3.0/default.nix)
20. [Nix Archive format](https://nix.dev/manual/nix/2.22/protocols/nix-archive)
