import AppKit
import Carbon.HIToolbox

@MainActor
final class PasteboardService: PasteboardServiceProtocol {
    private var lastTypedLength = 0
    private var savedClipboard: String?

    func copy(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func copyAndPaste(text: String) {
        copy(text: text)
        simulatePaste()
    }

    func typePartial(text: String) {
        guard AXIsProcessTrusted() else { return }
        guard !text.isEmpty else { return }

        if lastTypedLength > 0 {
            sendBackspaces(lastTypedLength)
        }

        typeText(text)
        lastTypedLength = text.count
    }

    func beginSession() {
        savedClipboard = NSPasteboard.general.string(forType: .string)
        lastTypedLength = 0
    }

    func endSession(finalText: String, shouldPaste: Bool) {
        let typedInline = lastTypedLength > 0 && AXIsProcessTrusted()

        if !finalText.isEmpty {
            if typedInline {
                sendBackspaces(lastTypedLength)
                typeText(finalText)
                if !shouldPaste {
                    copy(text: finalText)
                }
            } else if shouldPaste {
                copy(text: finalText)
                simulatePaste()
            } else {
                copy(text: finalText)
            }
        }

        lastTypedLength = 0

        if let saved = savedClipboard, shouldPaste {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(saved, forType: .string)
            }
        }
        savedClipboard = nil
    }

    func cancelSession() {
        if lastTypedLength > 0 && AXIsProcessTrusted() {
            sendBackspaces(lastTypedLength)
        }
        lastTypedLength = 0
        if let saved = savedClipboard {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(saved, forType: .string)
            savedClipboard = nil
        }
    }

    private func simulatePaste() {
        guard AXIsProcessTrusted() else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cgSessionEventTap)
        keyUp?.post(tap: .cgSessionEventTap)
    }

    private func typeText(_ text: String) {
        guard !text.isEmpty else { return }
        let utf16Text = Array(text.utf16)
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        keyDown?.keyboardSetUnicodeString(stringLength: utf16Text.count, unicodeString: utf16Text)
        keyUp?.keyboardSetUnicodeString(stringLength: utf16Text.count, unicodeString: utf16Text)
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
