# Xournal++ configuration flow

`xournal-conf` is the versioned data repository consumed by `nix-conf`. The native Xournal++ profile used by this configuration is `$XDG_CONFIG_HOME/xournalpp`, normally `~/.config/xournalpp`. The path `~/.config/com.github.xournalpp.xournalpp` is not part of the native profile contract and must not be used as a second source of truth unless a separately installed package explicitly requires it.

## Ownership and paths

| Layer | Path | Owner | Purpose |
| --- | --- | --- | --- |
| Versioned source | `~/Projects/xournal-conf/xournalpp/` | `xournal-conf` | Reviewed settings, toolbar, palette and LaTeX template |
| Native editable profile | `~/.config/xournalpp/` | Home Manager activation + Xournal++ | Writable source consumed directly by Xournal++ |
| Legacy migration source | `~/.config/nixos/xournalpp/` | One-time activation migration | Read only when the native file does not exist |
| GTK preferences | `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` | `shell-conf` | Stable icon-theme and dark-mode preferences; the native GTK/libadwaita stylesheet remains toolkit-owned |

The application settings and toolbar are intentionally seeded only when the native editable files do not exist. This allows the Xournal++ interface to modify them without every activation overwriting the user’s work. The requested `defaultSaveName=%F` convention is a narrow declarative policy: activation converges that one property in an existing profile, while other UI-editable settings remain untouched. The static Livara fallback palette remains available from the flake input, while the Ambxst runtime palette is validated from `~/.cache/ambxst/colors.json` and adapted dynamically by `shell-conf`. The runtime adapter updates only the managed visual properties (`colorPalette`, canvas/selection colors and graph page-template colors) in the editable owner, never the rest of `settings.xml`.

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

The versioned profile follows the system appearance through `themeVariant=useSystem`, uses the dark Livara fallback for the page and graph template, assigns the Livara gold role to the highlighter, sets the eraser to `VERY_FINE`, and places `HIGHLIGHTER` followed by `ERASER` at the beginning of the custom tool cluster. The duplicate adjacent separators were removed from `toolbar.ini`.

Ambxst owns the dynamic shell palette, while the Xournal++ adapter consumes its semantic aliases and writes the drawing-color palette. Xournal++ still owns its semantic drawing configuration. This is deliberate: rewriting the complete `settings.xml` would compete with UI edits and make the application profile non-deterministic. The adapter writes a valid GIMP `.gpl` file containing only drawing-oriented roles (`text`, contrast/outline and terminal accent colors), rejects Material surface aliases such as `primary_container`, `secondary` and `tertiary`, deduplicates by RGB, and converges only the documented visual properties in `~/.config/xournalpp/settings.xml`; Home Manager converges the explicitly requested `defaultSaveName` property, and tool behavior and toolbar layout remain under `xournal-conf`. The New Xournal helper creates native gzip-compressed Xournal++ XML and opens the resulting path, so the first Save targets that file instead of treating it as an unsaved document. GTK/libadwaita and Qt toolkit styles remain under their documented toolkit integrations rather than receiving an undocumented second global writer.

## References

1. [Xournal++ file locations](https://xournalpp.github.io/guide/file-locations/)
2. [Xournal++ toolbar colors](https://xournalpp.github.io/guide/config/toolbar-colors/)
3. [Xournal++ eraser](https://xournalpp.github.io/guide/tools/eraser/)
4. [GTK4 CSS overview](https://docs.gtk.org/gtk4/css-overview.html)
5. [Qt Style Sheets](https://doc.qt.io/qt-6/stylesheet.html)
