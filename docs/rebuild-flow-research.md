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
