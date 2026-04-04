import AppKit
import Carbon.HIToolbox
import os.log

@MainActor
final class PasteboardService: PasteboardServiceProtocol {

    private let log = Logger(subsystem: "com.ahmetshbz.voicman", category: "PasteboardService")
    private var lastTypedLength = 0
    private var savedClipboard: String?

    func copy(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        log.info("Metin panoya kopyalandı.")
    }

    func copyAndPaste(text: String) {
        copy(text: text)
        simulatePaste()
    }

    /// Konuşma sırasında anlık olarak aktif input'a yazar.
    /// Önceki partial text'i siler (backspace), yeni text'i yapıştırır.
    func typePartial(text: String) {
        guard AXIsProcessTrusted() else { return }
        guard !text.isEmpty else { return }

        // Önceki yazılanı sil
        if lastTypedLength > 0 {
            sendBackspaces(lastTypedLength)
        }

        // Yeni metni yapıştır
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        simulatePaste()

        lastTypedLength = text.count
    }

    /// Kayıt başında çağır — mevcut clipboard'u sakla
    func beginSession() {
        savedClipboard = NSPasteboard.general.string(forType: .string)
        lastTypedLength = 0
    }

    /// Kayıt bitiminde çağır — clipboard'u geri yükle, son metni yapıştır
    func endSession(finalText: String, shouldPaste: Bool) {
        if shouldPaste && !finalText.isEmpty {
            // Önceki partial'ı sil, final'ı yaz
            if lastTypedLength > 0 {
                sendBackspaces(lastTypedLength)
            }
            copy(text: finalText)
            simulatePaste()
        } else if !finalText.isEmpty {
            // Sadece kopyala, partial'ı silme (zaten orada)
            copy(text: finalText)
        }

        lastTypedLength = 0

        // Orijinal clipboard'u geri yükle
        if let saved = savedClipboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(saved, forType: .string)
            }
            savedClipboard = nil
        }
    }

    /// Partial session'ı iptal et (hata/iptal durumu)
    func cancelSession() {
        if lastTypedLength > 0 {
            sendBackspaces(lastTypedLength)
        }
        lastTypedLength = 0
        if let saved = savedClipboard {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(saved, forType: .string)
            savedClipboard = nil
        }
    }

    // MARK: - Özel

    private func simulatePaste() {
        guard AXIsProcessTrusted() else {
            log.warning("Accessibility izni yok.")
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cgSessionEventTap)
        keyUp?.post(tap: .cgSessionEventTap)
    }

    private func sendBackspaces(_ count: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: true)
            let up   = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: false)
            down?.post(tap: .cgSessionEventTap)
            up?.post(tap: .cgSessionEventTap)
        }
    }
}
