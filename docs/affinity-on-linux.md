# Affinity on NixOS

The Affinity integration uses [affinity-nix](https://github.com/mrshmllow/affinity-nix), not Bottles. The flake adds the `affinity-nix` input, applies `inputs.affinity-nix.overlays.default`, and installs `pkgs.affinity-v3` through Home Manager.

The package provides an isolated Wine-based runtime and overlay filesystem for user data. It does not redistribute Canva's proprietary Affinity archives. The package is unfree and may require the upstream binary cache or a local build according to the affinity-nix README.

After updating the system, launch the generated **Affinity v3** desktop entry or run:

```bash
affinity-v3
```

For diagnostics, the package exposes its own Wine wrapper:

```bash
affinity-v3 --help
affinity-v3 wine winecfg
```

Affinity v3 support remains dependent on Wine, GPU drivers and the current upstream package revision. If the program fails to start, run `affinity-v3 --verbose` and report the output together with the package revision; do not reintroduce Bottles unless the upstream project explicitly recommends it.

## References

- [affinity-nix README](https://github.com/mrshmllow/affinity-nix)
- [Affinity compatibility notes](https://affinity.liz.pet/)
