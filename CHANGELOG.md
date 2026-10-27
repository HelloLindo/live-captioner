# Changelog

## [0.1.1](https://github.com/HelloLindo/live-captioner/releases/tag/v0.1.1) — 2026-10-27

- Add **Disabled** to the original and translated caption font submenus.
  Visibility is saved independently and hiding a stream preserves its font size.
  Select a font size to show that stream again.
- Remove hidden caption rows from the layout. A single stream uses the full
  viewport; when both are disabled, the transparent overlay passes clicks through.
- Add **Reset Caption Settings** to restore both streams and the 16/12 pt defaults.
- Keep the welcome preview visible regardless of saved caption visibility.
- Add native regression checks for menu actions, restart persistence, all eight
  visibility/translation combinations, all 14 font sizes, and panel layout.

Hiding captions does not stop recognition, translation, or transcript collection.
Translation-only display requires a selected translation language and output.

## [0.1.0](https://github.com/HelloLindo/live-captioner/releases/tag/v0.1.0) — 2026-10-24

- Introduce Live Captioner, based on Parakeet by LPFchan, with a separate app identity.
- Add adjustable translated and original caption fonts, defaulting to 16 pt and 12 pt.
- Provide a macOS DMG installer and SHA-256 checksum through GitHub Releases.
- Preserve upstream attribution and licenses; remove inherited updater and release configuration.
