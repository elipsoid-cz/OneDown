# OneDown

**Permanently delete files from the Finder toolbar.**

OneDown adds a **Delete Forever** button to your Finder toolbar. Select files, click once, confirm — gone for good. No Trash, no recovery.

> Companion to [OneUp](https://github.com/elipsoid-cz/OneUp) — the Go Up button for Finder.

## Install

1. Download the DMG from [Releases](https://github.com/elipsoid-cz/OneDown/releases/latest)
2. Drag **OneDown.app** to `/Applications`
3. Open it — macOS will block it (no notarization). Go to **System Settings → Privacy & Security → Open Anyway**
4. The **Delete Forever** button appears in Finder toolbar automatically

## How it works

- Main app installs `DeletePermanently.applescript` into `~/Library/Application Scripts/`
- The Finder Sync Extension adds a toolbar button
- On click, the extension runs the script via `NSUserAppleScriptTask` (outside sandbox)
- The script asks Finder for the current selection, shows a confirmation dialog, then runs `rm -rf`

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel

## Build from source

```bash
xcodegen generate
xcodebuild -project OneDown.xcodeproj -scheme OneDown -configuration Debug build
```

## License

MIT
