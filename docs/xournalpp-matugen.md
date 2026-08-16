# Xournal++ configuration flow

`xournal-conf` is the versioned data repository consumed by `nix-conf`. The native Xournal++ profile used by this configuration is `$XDG_CONFIG_HOME/xournalpp`, normally `~/.config/xournalpp`. The path `~/.config/com.github.xournalpp.xournalpp` is not part of the native profile contract and must not be used as a second source of truth unless a separately installed package explicitly requires it.

## Ownership and paths

| Layer | Path | Owner | Purpose |
| --- | --- | --- | --- |
| Versioned source | `~/Projects/xournal-conf/xournalpp/` | `xournal-conf` | Reviewed settings, toolbar, palette and LaTeX template |
| Native editable profile | `~/.config/xournalpp/` | Home Manager activation + Xournal++ | Writable source consumed directly by Xournal++ |
| Legacy migration source | `~/.config/nixos/xournalpp/` | One-time activation migration | Read only when the native file does not exist |
| Dynamic desktop theme | `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` | Matugen | GTK appearance consumed by GTK applications, including Xournal++ |

The application settings and toolbar are intentionally seeded only when the native editable files do not exist. This allows the Xournal++ interface to modify them without every activation overwriting the user’s work. The static Tokyo Night palette remains available from the flake input, while the Serpantinum runtime palette is generated separately as `palettes/serpantinum.gpl`. The runtime adapter updates only the `colorPalette` property in the editable owner, never the rest of `settings.xml`.

## Editing and publishing

Close Xournal++ before synchronizing. To publish the current UI configuration into the repository, run:

```bash
cd ~/.config/nixos
./scripts/sync-xournalpp-config.sh --push ~/Projects/xournal-conf
```

Review the diff, then commit and push from the `xournal-conf` checkout. To pull a reviewed repository change into the active profile, run:

```bash
cd ~/.config/nixos
./scripts/sync-xournalpp-config.sh --pull ~/Projects/xournal-conf
```

Restart Xournal++ after a pull. The canonical editable files are now under `~/.config/xournalpp/`, which is the native profile consumed by Xournal++. A previous `~/.config/nixos/xournalpp/` checkout is migrated only when the native file is absent; it is not an active second source of truth.

## Current profile decisions

The versioned profile forces dark mode, uses a black page background, assigns Tokyo Night gold (`#e0af68`) to the highlighter, sets the eraser to `VERY_FINE`, and places `HIGHLIGHTER` followed by `ERASER` at the beginning of the custom tool cluster. The duplicate adjacent separators were removed from `toolbar.ini`.

Matugen owns the desktop GTK palette and the Xournal++ drawing-color palette. Xournal++ still owns its semantic drawing configuration. This is deliberate: rewriting the complete `settings.xml` would compete with UI edits and make the application profile non-deterministic. The adapter writes a valid GIMP `.gpl` file with at least eleven colors and changes only `colorPalette` in `~/.config/xournalpp/settings.xml`; tool behavior, toolbar layout and page semantics remain under `xournal-conf`. Xournal++ consumes both the GTK appearance and the selected Matugen palette after restart.

## References

1. [Xournal++ file locations](https://xournalpp.github.io/guide/file-locations/)
2. [Xournal++ toolbar colors](https://xournalpp.github.io/guide/config/toolbar-colors/)
3. [Xournal++ eraser](https://xournalpp.github.io/guide/tools/eraser/)
4. [Matugen](https://github.com/InioX/matugen)
