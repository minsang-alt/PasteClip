<p align="center">
  <img src="Clipbara/Resources/Assets.xcassets/AppIcon.appiconset/256.png" width="128" height="128" alt="Clipbara icon">
</p>

<h1 align="center">Clipbara</h1>

<p align="center">
  <strong>A fast, private, open-source clipboard manager for macOS.</strong>
  <br>
  Find anything you've copied, organize important clips, and paste without leaving your keyboard.
</p>

<p align="center">
  English | <a href="README.zh-CN.md">简体中文</a>
</p>

> [!NOTE]
> **Clipbara was formerly known as PasteClip.** The project was renamed in August 2026 because an unrelated app with the same name exists on the Mac App Store. Releases up to v1.1.11 still ship under the PasteClip name; the app itself is renamed starting with v1.2.0. All old links redirect automatically.

<p align="center">
  <a href="https://github.com/mobrava/Clipbara/releases/latest"><img src="https://img.shields.io/github/v/release/mobrava/Clipbara?style=flat-square" alt="Latest release"></a>
  <a href="https://github.com/mobrava/Clipbara/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/mobrava/Clipbara/build.yml?branch=main&style=flat-square" alt="Build status"></a>
  <a href="https://github.com/mobrava/Clipbara/releases"><img src="https://img.shields.io/github/downloads/mobrava/Clipbara/total?style=flat-square" alt="Total downloads"></a>
  <a href="https://github.com/mobrava/Clipbara/stargazers"><img src="https://img.shields.io/github/stars/mobrava/Clipbara?style=flat-square" alt="GitHub stars"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/mobrava/Clipbara?style=flat-square" alt="License"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square" alt="macOS 14 or later">
  <a href="https://apps.apple.com/app/clipbara/id6803537696?mt=12"><img src="https://img.shields.io/badge/Mac%20App%20Store-free-0D96F6?style=flat-square&logo=apple&logoColor=white" alt="Clipbara on the Mac App Store"></a>
</p>

<p align="center">
  <a href="https://apps.apple.com/app/clipbara/id6803537696?mt=12"><strong>Get it on the Mac App Store</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/mobrava/Clipbara/releases/latest"><strong>Download the DMG</strong></a>
  &nbsp;·&nbsp;
  <a href="#installation"><strong>Install with Homebrew</strong></a>
</p>

<p align="center">
  <img src="docs/assets/pasteclip-demo.gif" width="800" alt="Clipbara demo: press Cmd Shift V, click a clip once, and it is on your clipboard ready to paste">
</p>

## Highlights

- **Complete clipboard history:** Capture plain text, rich text, HTML, images, links, files, colors, and code snippets.
- **Instant access:** Open the non-activating panel with `⌘ ⇧ V` without losing focus from your current app.
- **Fast search and filters:** Search clip contents, titles, or source apps, then filter by content type or date.
- **Pinboards:** Keep important clips in named collections and organize them with drag and drop.
- **Quick Look:** Press `Space` to preview text, images, links, files, and colors before pasting.
- **One-click copy:** Click any clip once. It lands on your clipboard and the panel closes, ready for `⌘ V`.
- **Keyboard-first workflow:** Search, navigate, preview, and paste without reaching for the mouse.
- **Flexible settings:** Configure shortcuts, history size, appearance, launch at login, and excluded apps.
- **Private by default:** Clipboard data stays on your Mac with no account, server, analytics, or tracking.

## Screenshots

<p align="center">
  <img src="docs/assets/screenshot-history-panel.png" width="900" alt="Clipbara history panel with clipboard cards at the bottom of the screen">
</p>

<table align="center">
  <tr>
    <td align="center">
      <img src="docs/assets/screenshot-menubar.png" width="320" alt="Clipbara menu bar dropdown with recent copies"><br>
      <sub>Menu bar dropdown</sub>
    </td>
    <td align="center">
      <img src="docs/assets/screenshot-settings.png" width="420" alt="Clipbara settings window"><br>
      <sub>Settings</sub>
    </td>
  </tr>
</table>

## Why Clipbara?

|  | Clipbara | Paste | Maccy |
| --- | --- | --- | --- |
| Price | Free, open source (GPL-3.0) | Subscription | Free, open source (MIT) |
| Interface | Card grid with visual previews | Card grid with visual previews | Compact menu-bar list |
| Collections | Pinboards | Pinboards | — |
| Sync across devices | No, 100% local by design | iCloud sync | No |
| Notarized by Apple | Yes | Yes | Yes |

If you need clipboard sync across devices, Paste's subscription earns its price. Clipbara covers the other case. You get the card-style workflow without a subscription, and you can read every line of code that touches your clipboard.

## Installation

Clipbara requires **macOS 14 Sonoma or later**. It is free on both channels.

### Mac App Store

[**Download Clipbara on the Mac App Store**](https://apps.apple.com/app/clipbara/id6803537696?mt=12)

### Homebrew

```bash
brew install --cask mobrava/tap/clipbara
```

### Manual download

1. Download the latest `.dmg` from [GitHub Releases](https://github.com/mobrava/Clipbara/releases/latest).
2. Open the disk image and drag the app into **Applications**.
3. Launch Clipbara from the Applications folder.

The DMG is signed with an Apple Developer ID and notarized by Apple (as of v1.1.11), so it opens without any security warnings.

### Which build should I install?

Both builds are compiled from this repository and use the same storage format.

| | Mac App Store | DMG and Homebrew |
| --- | --- | --- |
| Price | Free | Free |
| Updates | Through the App Store | Built-in Sparkle updater |
| App Sandbox | On | Off |
| New features | Arrive one review cycle later | Arrive first |

If you are not sure, take the App Store build.

### Moving from the DMG to the App Store build

The two builds use different bundle IDs, so they keep separate histories. To carry your clips over:

1. In the DMG build, open **Settings → General → Backup → Export** and save the JSON file.
2. Install the App Store build and open **Settings → General → Backup → Import**, or use the Import button on the welcome screen.
3. Select the exported file. Existing clips are kept and duplicates are skipped.

Quit one of the two builds afterwards. Running both at once registers `⌘ ⇧ V` twice and opens two panels. The DMG channel stays supported, so migrating is optional.

## Quick start

1. Launch Clipbara. It will appear in the menu bar.
2. Copy anything normally with `⌘ C`.
3. Press `⌘ ⇧ V` to open your clipboard history.
4. Start typing to search, or use `←` and `→` to move between clips.
5. Click a clip once to copy it. The panel closes right away, so press `⌘ V` where you need it. Or press `Space` to preview and `Return` to copy.

The global shortcuts can be changed in **Settings → Shortcuts**.

### Image clips in terminal apps

Selecting an image clip puts the image back on the macOS clipboard, but a shell prompt itself cannot accept image data. The app or CLI running inside the terminal must support clipboard image input.

For example, with Codex CLI on macOS:

1. Press `⌘ ⇧ V` and select the image clip you want to reuse.
2. Return to Codex without copying anything else.
3. Press `Control + V` in Codex to attach the clipboard image.

Codex uses `Control + V` for image attachments rather than the usual macOS `⌘ V` text-paste shortcut. Other terminal apps may use a different image-paste workflow.

### Keyboard shortcuts

| Action | Default shortcut |
| --- | --- |
| Open or close clipboard history | `⌘ ⇧ V` |
| Move between clips | `←` / `→` |
| Open or close Quick Look | `Space` |
| Copy selected clip and close | `Return` |
| Clear search, go back, or close | `Esc` |
| Clear unpinned history while the panel is open | `⌘ ⇧ Delete` |

Right-click a clip to rename it, add it to a Pinboard, or delete it.

## Privacy

Clipbara is designed to keep your clipboard private:

- **Local-only storage:** Clipboard history is stored on your Mac using SwiftData.
- **No account or backend:** There is no sign-in and no server receiving your clipboard data.
- **No telemetry:** Clipbara does not collect analytics, tracking, or usage data.
- **App exclusions:** Prevent selected apps, such as password managers, from being recorded.
- **Offline core:** Capture, search, preview, and paste work without an internet connection. The DMG build reaches the network only to check for updates through Sparkle, and the App Store build ships without an updater.

## Build from source

### Requirements

- macOS 14 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
git clone https://github.com/mobrava/Clipbara.git
cd Clipbara
brew install xcodegen
xcodegen generate
open Clipbara.xcodeproj
```

Build and run the `Clipbara` scheme with `⌘ R` in Xcode.

## Tech stack

| Component | Technology |
| --- | --- |
| Language | Swift 6 with strict concurrency |
| Interface | SwiftUI + AppKit `NSPanel` |
| Persistence | SwiftData |
| Global shortcuts | [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) |
| Updates | [Sparkle](https://github.com/sparkle-project/Sparkle) in the DMG build, App Store in the MAS build |
| Project generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) |
| Minimum target | macOS 14 |

## Contributing

Contributions are welcome. Please read the [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before opening a pull request.

Found a bug or have an idea? [Open an issue](https://github.com/mobrava/Clipbara/issues/new/choose).

## License

Clipbara is available under the [GNU General Public License v3.0](LICENSE).

The Mac App Store edition is distributed by the copyright holder under a separate
proprietary license (dual licensing). The source code for both editions lives in
this repository.

<p align="center">
  If Clipbara is useful to you, consider starring the repository.
</p>
