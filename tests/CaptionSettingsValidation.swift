import AppKit
import SwiftUI

// Exercises the production menu actions and real AppKit/SwiftUI caption panel.
// A standalone executable keeps test preferences separate from the app's domain.
@main
struct CaptionSettingsValidation {
    @MainActor static func pump(_ seconds: Double = 0.35) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    @MainActor static func main() throws {
        let defaults = UserDefaults.standard
        let sizeKeys = [CaptionFontSize.translatedKey, CaptionFontSize.originalKey]
        let visibilityKeys = [CaptionVisibility.translatedKey, CaptionVisibility.originalKey]
        if CommandLine.arguments.contains("--verify-persistence") {
            precondition(sizeKeys.map { defaults.double(forKey: $0) } == [30, 24])
            precondition(visibilityKeys.allSatisfy { !CaptionVisibility.saved(forKey: $0) })
            print("PASS: sizes and disabled states survive a fresh process")
            return
        }
        precondition(Bundle.main.bundleIdentifier != "io.github.hellolindo.livecaptioner")
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let keys = sizeKeys + visibilityKeys + ["translateTo", "NSWindow Frame Captions"]
        let previous = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, previous) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
        let menuOwner = CaptionFontMenu()
        func submenus() -> [NSMenu] {
            Array(menuOwner.makeMenu().items.prefix(2)).map { $0.submenu! }
        }
        func send(_ item: NSMenuItem) {
            let delivered = app.sendAction(item.action!, to: item.target, from: item)
            precondition(delivered, "production menu action was not dispatched")
            pump()
        }
        func choose(_ stream: Int, _ size: Int) {
            send(submenus()[stream].items.first { $0.tag == size }!)
            let checked = submenus()[stream].items.filter { $0.state == .on }
            precondition(checked.count == 1 && checked[0].tag == size)
        }
        func disable(_ stream: Int) {
            send(submenus()[stream].items[0])
            let checked = submenus()[stream].items.filter { $0.state == .on }
            precondition(checked.count == 1 && checked[0].title == "Disabled")
        }
        func reset() { send(menuOwner.makeMenu().items.last!) }
        precondition(visibilityKeys.allSatisfy { CaptionVisibility.saved(forKey: $0) })
        precondition(submenus()[0].items.first { $0.state == .on }?.tag == 16)
        precondition(submenus()[1].items.first { $0.state == .on }?.tag == 12)
        choose(0, 30)
        choose(1, 24)
        disable(0)
        precondition(CaptionVisibility.saved(forKey: visibilityKeys[1]), "streams must be independent")
        disable(1)
        precondition(sizeKeys.map { defaults.double(forKey: $0) } == [30, 24], "hiding must preserve sizes")
        defaults.synchronize()
        let reader = Process()
        reader.executableURL = Bundle.main.executableURL!
        reader.arguments = ["--verify-persistence"]
        try reader.run()
        reader.waitUntilExit()
        precondition(reader.terminationStatus == 0)
        reset()
        precondition(visibilityKeys.allSatisfy { CaptionVisibility.saved(forKey: $0) })
        precondition(CaptionFontSize.saved(forKey: sizeKeys[0], fallback: 16) == 16)
        precondition(CaptionFontSize.saved(forKey: sizeKeys[1], fallback: 12) == 12)
        print("PASS: actual menu defaults, independent disabling, retained sizes, checkmarks, and reset")

        let captions = Captions()
        let translator = Translator()
        let original = "ORIGINAL: Good morning everyone. The quick brown fox jumps over the lazy dog. "
        let translated = "TRANSLATED: Bonjour à tous. Le renard brun rapide saute par-dessus le chien paresseux. "
        captions.lock(String(repeating: original, count: 4))
        translator.target = Locale.Language(identifier: "fr")
        translator.output.lock(String(repeating: translated, count: 4))
        let panel = CaptionPanel(captions: captions, translator: translator, onClose: {}, onCopy: {})
        panel.orderFrontRegardless()
        defer { panel.orderOut(nil) }
        pump(1)
        func snapshot(_ name: String) throws {
            let view = panel.contentView!
            let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
            view.cacheDisplay(in: view.bounds, to: rep)
            if name == "both-disabled" {
                precondition(rep.colorAt(x: rep.pixelsWide / 2, y: rep.pixelsHigh / 2)?.alphaComponent == 0,
                             "hidden overlay must be transparent")
            }
            try rep.representation(using: .png, properties: [:])!.write(
                to: URL(fileURLWithPath: "build/caption-tests/\(name).png"))
        }
        choose(0, 36)
        choose(1, 36)
        let bottom = panel.frame.minY
        let width = panel.frame.width
        let bilingualHeight = panel.frame.height
        precondition(!panel.ignoresMouseEvents)
        try snapshot("both-enabled")
        disable(1)
        let translatedHeight = panel.frame.height
        precondition(!panel.ignoresMouseEvents && translatedHeight < bilingualHeight)
        precondition(panel.frame.minY == bottom && panel.frame.width == width)
        try snapshot("translated-only")
        disable(0)
        precondition(panel.ignoresMouseEvents, "both disabled must not intercept clicks")
        try snapshot("both-disabled")
        let originalCount = captions.transcript.count
        let translatedCount = translator.output.transcript.count
        captions.lock(original)
        translator.output.lock(translated)
        pump()
        precondition(captions.transcript.count == originalCount + 1)
        precondition(translator.output.transcript.count == translatedCount + 1)
        precondition(translator.target?.minimalIdentifier == "fr")
        choose(1, 36)
        let originalHeight = panel.frame.height
        precondition(!panel.ignoresMouseEvents && originalHeight < bilingualHeight)
        precondition(panel.frame.minY == bottom && panel.frame.width == width)
        try snapshot("original-only")
        translator.target = nil
        pump()
        precondition(!panel.ignoresMouseEvents, "original-only must work with translation off")
        disable(1)
        choose(0, 36)
        precondition(panel.ignoresMouseEvents, "translated-only needs a selected translation language")

        // Empty hidden streams cannot keep an otherwise empty panel visible.
        translator.target = Locale.Language(identifier: "fr")
        translator.output.clear()
        captions.lock(original)
        pump()
        precondition(panel.ignoresMouseEvents, "hidden original must not leak into translation-only mode")
        translator.output.lock(translated)
        pump()
        precondition(!panel.ignoresMouseEvents)
        disable(0)
        choose(1, 36)
        captions.clear()
        translator.output.lock(translated)
        pump()
        precondition(panel.ignoresMouseEvents, "hidden translation must not keep original-only mode visible")
        captions.lock(original)
        pump()
        precondition(!panel.ignoresMouseEvents)

        // Retain native-language hiding when translations are displayed, but
        // original-only mode must still caption speech in the target language.
        translator.target = Locale.Language(identifier: "en")
        _ = translator.hear(String(repeating: original, count: 3))
        precondition(translator.hearingNative)
        choose(0, 36)
        pump()
        precondition(panel.ignoresMouseEvents)
        disable(0)
        precondition(!panel.ignoresMouseEvents)
        translator.target = Locale.Language(identifier: "fr")
        translator.output.lock(translated)
        choose(0, 36)
        for translationOn in [false, true] {
            translator.target = translationOn ? Locale.Language(identifier: "fr") : nil
            if translationOn { translator.output.lock(translated) }
            for originalOn in [false, true] {
                for translatedOn in [false, true] {
                    if originalOn { choose(1, 36) } else { disable(1) }
                    if translatedOn { choose(0, 36) } else { disable(0) }
                    let expectedVisible = originalOn || (translatedOn && translationOn)
                    precondition(panel.ignoresMouseEvents == !expectedVisible,
                                 "visibility matrix failed: translation=\(translationOn), original=\(originalOn), translated=\(translatedOn)")
                }
            }
        }
        print("PASS: all 8 visibility/translation combinations, single-row layout, click-through, hidden-stream isolation, and native-language behavior")
        print("PASS: panel heights bilingual \(bilingualHeight), translated-only \(translatedHeight), original-only \(originalHeight); position/width stable")
        for size in CaptionFontSize.choices {
            choose(0, size)
            choose(1, size)
            precondition(panel.frame.height > 0 && panel.frame.height <= bilingualHeight)
        }
        let stableHeight = panel.frame.height
        captions.lock(String(repeating: original, count: 4))
        translator.output.lock(String(repeating: translated, count: 4))
        pump(1)
        precondition(panel.frame.height == stableHeight)
        if let visible = panel.screen?.visibleFrame {
            choose(0, 10)
            choose(1, 10)
            panel.setFrameOrigin(NSPoint(x: panel.frame.minX, y: visible.maxY - panel.frame.height))
            choose(0, 36)
            choose(1, 36)
            precondition(panel.frame.maxY <= visible.maxY)
        }
        disable(0)
        disable(1)
        var previewShown = false
        var previewHeight: CGFloat = 0
        let preview = NSHostingView(rootView: CaptionView(captions: captions,
            onHeightChange: { previewHeight = $0 }, onVisibilityChange: { previewShown = $0 },
            originalSizeOverride: CaptionFontSize.originalDefault).frame(width: 440, height: 116))
        preview.sizingOptions = []
        panel.contentView = preview
        panel.setContentSize(NSSize(width: 440, height: 116))
        pump()
        precondition(previewShown && previewHeight > 0 && previewHeight <= 116)
        try snapshot("welcome-preview")
        print("PASS: all 14 sizes, stable streaming height, screen-edge resizing, and welcome preview with both streams disabled")
    }
}
