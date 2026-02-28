<p align="center">
  <img src="PasteClip/Resources/Assets.xcassets/AppIcon.appiconset/256.png" width="128" height="128" alt="PasteClip Icon">
</p>

<h1 align="center">PasteClip</h1>

<p align="center">
  A lightweight clipboard manager for macOS
</p>

<p align="center">
  <a href="https://github.com/minsang-alt/PasteClip/releases/latest"><img src="https://img.shields.io/github/v/release/minsang-alt/PasteClip?style=flat-square" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/minsang-alt/PasteClip?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/macOS-15%2B-blue?style=flat-square" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-6-orange?style=flat-square" alt="Swift 6">
</p>

---

## Screenshots

<!-- TODO: Add screenshots or GIF demo here -->

## Features

- **Clipboard History** — Automatically saves text, images, and files you copy
- **Quick Access Panel** — Open with a global hotkey; non-activating panel keeps your current app focused
- **Search** — Instantly find items in your clipboard history
- **Keyboard Navigation** — Navigate and paste entirely from the keyboard
- **Paste with One Click** — Select an item to paste it directly into the frontmost app
- **Image Support** — Copies images as PNG + file URL so they work everywhere, including terminals
- **Lightweight** — Lives in the menu bar, uses minimal resources
- **Privacy** — All data stays local on your Mac using SwiftData

## Installation

### Homebrew (Recommended)

```bash
brew install --cask --no-quarantine minsang-alt/tap/pasteclip
```

### GitHub Releases

Download the latest `.dmg` from the [Releases](https://github.com/minsang-alt/PasteClip/releases/latest) page.

> **Gatekeeper Warning:** Since the app is not notarized, macOS may show a warning on first launch.
> To resolve: **System Settings → Privacy & Security → scroll down → click "Open Anyway"**,
> or use the `--no-quarantine` flag with Homebrew.

### Build from Source

1. Install [xcodegen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```

2. Clone and build:
   ```bash
   git clone https://github.com/minsang-alt/PasteClip.git
   cd PasteClip
   xcodegen generate
   open PasteClip.xcodeproj
   ```

3. Build and run with `Cmd + R` in Xcode.

## Usage

1. **Launch** PasteClip — it appears as an icon in the menu bar.
2. **Copy** anything as usual (`Cmd + C`).
3. **Open the panel** with your configured hotkey (set in Preferences).
4. **Navigate** with arrow keys or search by typing.
5. **Paste** by pressing `Enter` or clicking an item.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6 (strict concurrency) |
| UI | SwiftUI + NSPanel (non-activating) |
| Data | SwiftData |
| Target | macOS 15+ |
| Dependencies | [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) |
| Build | [XcodeGen](https://github.com/yonaskolb/XcodeGen) |

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

## Acknowledgments

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus — Global keyboard shortcuts for macOS
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) by Yonas Kolb — Xcode project generation from YAML
