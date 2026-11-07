# Contributing to MDReader

Thanks for helping out. This page covers building, testing, how the code is organized, and a few
non-obvious decisions worth knowing before you change playback or the menu bar panel.

## Setup

- A Mac with Apple silicon, macOS 14 or later
- Xcode 16 or later, plus its Metal Toolchain component:

  ```bash
  xcodebuild -downloadComponent MetalToolchain
  ```

MDReader is a Swift package. Build it with `xcodebuild` (which `Scripts/build.sh` wraps) rather than
`swift build`: only `xcodebuild` compiles MLX's Metal shaders, and without them the app can't speak.

```bash
./Scripts/build.sh              # build dist/MDReader.app and open it
./Scripts/build.sh --no-launch  # build only
open Package.swift              # work in Xcode; every view has a #Preview
```

## Testing

```bash
xcodebuild test -scheme MDReader -destination 'platform=macOS'
```

The unit tests cover `MarkdownSanitizer`. Add a case there whenever you change what gets read.

Playback is checked end to end by the app's self-test, which reads the clipboard, then plays, seeks,
changes speed, pauses, exports and plays voice samples through the real audio engine. It plays sound,
so turn the volume down:

```bash
pbcopy < Samples/sample.md
dist/MDReader.app/Contents/MacOS/MDReader --selftest
```

It prints a PASS or FAIL line per step and exits non-zero on any failure. Run it after touching
anything in `Audio/` or `Player/`.

## Project structure

```
Sources/MDReaderCore/              library: no UI, unit-tested
  Markdown/   MarkdownSanitizer      Markdown → speakable paragraphs
              MarkdownBlockParser    headings, lists, tables, quotes, code fences
              InlineMarkdown         emphasis, links, images, HTML, entities
              MarkdownPattern        the regexes
  Speech/     SpeechEngine           text → AudioClip
              KokoroEngine/Runtime   Kokoro-82M on MLX; downloads the model on first use
              KokoroVoices           the 54 voices and their sample sentences
  Audio/      AudioClip              in-memory mono audio; join, read, write
              AudioCache             SHA-256 keyed CAF + JSON sidecar
              AudioPlayback          AVAudioEngine graph: source → time-pitch → mixer
              RenderState            samples + play position for the render thread
              AudioExporter          CAF → AAC .m4a
  Player/     PlayerController       observable state and transport (+Synthesis, +Preview)
              VoicePreviewer         the Voice tab's Test button
              NowPlayingBridge       media keys, Control Center, Now Playing
  Settings/   SettingsKey, SpeechSettings
Sources/MDReader/                  the app
  App/        MDReaderApp, AppDelegate
  Views/      Reader, Editor, SpeakingNow, Player, Voice, Glass
  System/     KeyboardShortcuts, GlobalHotKey, ExportPanel, Updater (Sparkle)
  Diagnostics/SelfTest, Screenshot   --selftest, --screenshot
Tests/MDReaderCoreTests/           MarkdownSanitizer tests
```

**How a document becomes audio.** `PlayerController.play()` runs the text through
`MarkdownSanitizer` to get paragraphs, hashes them with the voice into a cache key, and either loads
the audio from `AudioCache` or synthesizes each paragraph with `KokoroEngine`. The clips are joined
with a short pause between them, and the start time of each paragraph is kept so the player can
jump between paragraphs and highlight the current one.

## Things to know before changing playback

Playback is built the way it is because of three Core Audio problems found the hard way:

- **`AVAudioPlayer` tops out at 2×.** The speed range goes to 2.5×, so playback uses
  `AVAudioEngine` with `AVAudioUnitTimePitch` instead.
- **`AVAudioPlayerNode` stalls after a speed change.** Its stop → schedule → play cycle blocks for
  seconds and then throws "player did not see an IO cycle". So there's no player node: the clip
  lives in memory and an `AVAudioSourceNode` copies samples from a play position. Seek, pause and
  resume just move that position.
- **`AVAudioUnitTimePitch` freezes if you change its rate while it runs.** It intermittently stops
  pulling audio. `AudioPlayback` swaps in a fresh unit for every speed change instead of setting
  `rate` on the live one.

The render callback in `RenderState` runs on the real-time audio thread: it must not lock, allocate
or call into Swift concurrency. It shares plain memory with the main actor and only swaps samples
while the engine is stopped.

## Other gotchas

- **`@Observable` and `didSet`.** The macro turns stored properties into computed ones, so assigning
  a property inside its own `didSet` re-enters the setter. `PlayerController.rate` clamps without
  re-assigning unless it has to; the unconditional version recurses until the stack overflows.
- **The glass menu bar panel relies on private layout.** SwiftUI has no API for a MenuBarExtra
  panel's background, so `WindowGlassInstaller` hides SwiftUI's two background views and puts an
  `NSGlassEffectView` behind the content. A macOS update could change that layout; if the panel turns
  opaque again, start there.
- **Liquid Glass needs macOS 26.** Use `.glassIfAvailable()` and `.windowGlassIfAvailable()` rather
  than calling the glass APIs directly. They fall back on macOS 14 and 15.

## Releasing

MDReader ships as a sandboxed, hardened-runtime app signed with a Developer ID, notarized by Apple
and updated with [Sparkle](https://sparkle-project.org). `Scripts/release.sh` does all of it and
leaves `dist/MDReader-<version>.zip` plus the update feed `dist/appcast.xml`.

1. Bump `CFBundleShortVersionString` and `CFBundleVersion` in `Resources/Info.plist`.
2. Once per machine, store notarization credentials (an app-specific password from
   appleid.apple.com):

   ```bash
   xcrun notarytool store-credentials MDReader --apple-id <your Apple ID> --team-id <your team ID>
   ```

3. Run `./Scripts/release.sh`. It picks the first "Developer ID Application" certificate in your
   keychain; set `SIGN_IDENTITY` or `NOTARY_PROFILE` to override.
4. Publish with the `gh release create …` command it prints. The zip and `appcast.xml` must be
   attached to the **latest** release: the app looks for updates at
   `github.com/push1kb/MDReader/releases/latest/download/appcast.xml`.

Updates are signed with an EdDSA key that lives in the maintainer's login keychain; its public half is
`SUPublicEDKey` in `Info.plist`. Back it up (Sparkle's `generate_keys -x <file>` exports it, and
`-f <file>` imports it on another Mac). If it's lost, existing installs can't verify new updates.
Sparkle's tools come with the Sparkle package, in
`.build/xcode/SourcePackages/artifacts/sparkle/Sparkle/bin` after the first build.

Sparkle runs sandboxed through its installer service: `Installer.xpc`, the two
`mach-lookup` exceptions in the entitlements and `SUEnableInstallerLauncherService` in `Info.plist`
belong together. The downloader service is removed because the app has network access itself.

Ad-hoc builds from `Scripts/build.sh` leave the hardened runtime off, because its library
validation refuses ad-hoc signed frameworks such as Sparkle. Release builds turn it on.

Release resources live in `Resources/`: `Info.plist`, `MDReader.entitlements` (sandbox, outgoing
network for the model download and update checks, user-selected files for export, Sparkle's
installer), `PrivacyInfo.xcprivacy` and
`AppIcon.icns`. The icon is drawn by `Design/render-icon.swift`; to change it, edit that and run:

```bash
swift Design/render-icon.swift Design/AppIcon-1024.png 1024
```

then rebuild the `.icns` from an iconset with `iconutil` (16–512 pt at 1× and 2×).

The README screenshot is drawn by the app itself:

```bash
pbcopy < Samples/screenshot.md
cp "$(dist/MDReader.app/Contents/MacOS/MDReader --screenshot)" Design/screenshot.png
```

The app's files go through `AppFolder`: the voice model in Application Support (it's needed to
speak, so it mustn't be purged) and generated audio in Caches (it can always be regenerated). In
the sandbox both resolve inside `~/Library/Containers/com.push1kb.MDReader`.

## Style

- One type per file, grouped by feature. Keep files short; split before they pass about 200 lines.
- Every SwiftUI view gets a `#Preview`, written with the view. `PlayerController.preview()` and
  `.emptyPreview()` provide sample state.
- Comments explain *why*, not what.
- The build has no warnings. Keep it that way.
