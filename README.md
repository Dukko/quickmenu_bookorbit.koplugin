# QuickMenu: BookOrbit

BookOrbit as a toggleable [QuickMenu](https://github.com/jbreizh/quickmenu.koplugin)
item, rendered with full QuickMenu styling (button, shadow, highlight state)
and BookOrbit's own tab icon.

- **Tap**: opens BookOrbit — the *This book* overlay (position, Sync now,
  Jump/Stay) when a book is open, the library dashboard otherwise.
- **Hold**: syncs — this book in the reader, everything in the file browser.

No menu-bar changes, no settings writes outside QuickMenu: everything goes
through BookOrbit's own Dispatcher actions.

## Requires

- [QuickMenu](https://github.com/jbreizh/quickmenu.koplugin) 2.0+
- [BookOrbit](https://github.com/bookorbit/bookorbit) plugin (`bookorbit.koplugin`),
  signed in (the button hides itself when BookOrbit isn't active)

## Install

Via Storefront/AppStore, or manually:

1. Download `quickmenu_bookorbit.koplugin.zip` from
   [Releases](../../releases).
2. Unzip it and copy the `quickmenu_bookorbit.koplugin` folder into KOReader's
   `plugins` folder (`koreader/plugins/`, `.adds/koreader/plugins/` on Kobo).
3. Restart KOReader.

The button is added to QuickMenu's Actions section automatically on first
run. Remove or re-add it any time in QuickMenu's settings (Actions section),
or from Tools → QuickMenu: BookOrbit.

## Notes

- QuickMenu 2.0's `require("config")` collides with HomeAssistant's
  `config.lua` when both are installed; if the QuickMenu tab is missing, it
  needs the [documented one-spot patch](https://github.com/jbreizh/quickmenu.koplugin)
  (load its own `config.lua` by path). This companion is unaffected by that
  collision.

## License

AGPL-3.0-only, see [LICENSE](LICENSE).
