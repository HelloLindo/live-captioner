# Live Captioner

Live captions and translation for everything your Mac plays: videos, calls,
and podcasts. Speech recognition and translation run on your Mac, with captions
in a floating panel you can move anywhere.

Live Captioner is a fork of [Parakeet](https://github.com/LPFchan/parakeet).
Thank you to LPFchan and the Parakeet contributors for creating and sharing
the original version that makes this project possible.

**Apple silicon · macOS 15 or later · Free and open source**

[Build and run](#build-and-run) · [Using captions](#using-captions) ·
[Source](https://github.com/HelloLindo/live-captioner)

![Upstream demo showing captions and Korean translation in QuickTime Player](docs/screenshot.jpg)

*Demo image from the original Parakeet app. Live Captioner adds its own branding
and adjustable caption fonts.*

## Features

- Live captions for system audio, powered by Nemotron 3.5 ASR through FluidAudio.
- Optional translation through Apple's on-device Translation framework.
- Independent font sizes for translated and original captions, saved between
  sessions. Compact defaults are **16 pt** and **12 pt**.
- A draggable floating panel with animated text and scrolling.
- Screen text translation with ⇧⌘1, plus zoom and area selection.
- Menu bar controls, transcript copying, and Open at Login.

## Build and run

Install full **Xcode 26 or later**, open it once, and finish its license and
component setup. Command Line Tools alone do not include all required tools.

From the repository root:

```sh
scripts/build-app.sh
scripts/run-local.sh
```

The app is built at `build/LiveCaptioner.app`. The scripts launch that copy
without installing it into `/Applications`.

If your selected developer tools point to Command Line Tools, specify your
full Xcode installation when building. For example:

```sh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" scripts/build-app.sh
```

Adjust the path to match your Xcode installation. Dependencies are downloaded
on the first build. Local builds are not notarized; if macOS blocks a build you
trust, use System Settings → Privacy & Security → **Open Anyway**. Ad-hoc
rebuilds may require audio permission again.

On first launch, follow the welcome screen to allow system audio capture and
set up the speech model (about 640 MB). macOS downloads translation languages
as needed. Screen translation separately requires Screen Recording permission.

Live Captioner can coexist with Parakeet and has its own preferences and
permissions. Quit any other captioning copy before using it.

## Using captions

1. Play audio and enable **Captions** from the menu bar (⌘L).
2. Drag the floating caption panel to your preferred position. Hover over it
   to turn captions off, copy the transcript, or select a translation language.
3. Choose **Translate To** to show translated text above the original.
   Speech already in the selected target language is hidden.
4. Open **Caption Font Size** to adjust **Translated Captions** and
   **Original Captions** independently from **10–36 pt**. Settings apply
   immediately and persist after quitting. **Reset Font Sizes** restores
   16 pt and 12 pt. Original Captions also controls untranslated text.
5. Press **⇧⌘1** to translate text on screen. Pinch to zoom, drag an area
   to translate it again, and press Esc to dismiss.

Enable **Open at Login** from the menu bar to start the app when you sign in.
Updates are installed manually by rebuilding from the version you want to use.

You can also control a running copy from Terminal:

```sh
build/LiveCaptioner.app/Contents/MacOS/LiveCaptioner status
build/LiveCaptioner.app/Contents/MacOS/LiveCaptioner captions on
build/LiveCaptioner.app/Contents/MacOS/LiveCaptioner captions off
```

## Privacy

Speech recognition and translation run locally. Initial model and language-pack
downloads require a network connection. Audio capture includes the system mix,
which may contain other apps' calls or notifications; the app does not use your
microphone.

Transcripts remain in memory for the session. Hiding or turning captions off
does not erase them. **Copy Transcript** writes text to the clipboard. Screen
translation captures the screen when you invoke it.

## Credits and license

Live Captioner is based on [Parakeet](https://github.com/LPFchan/parakeet) by
LPFchan. The original [MIT license](LICENSE) and copyright notice are preserved.

Speech processing uses [FluidAudio](https://github.com/FluidInference/FluidAudio)
(Apache-2.0), [PermissionFlow](https://github.com/jaywcjlove/PermissionFlow) (MIT),
and NVIDIA's [Nemotron 3.5 ASR](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b)
([OpenMDW-1.1](https://openmdw.ai/license/1-1/)). Library notices ship in
`Contents/Resources/Licenses`. The website retains upstream demo attribution
and its media license.
