import AppKit
import Carbon.HIToolbox

@MainActor
final class PasteboardService: PasteboardServiceProtocol {
    private var savedClipboard: String?

    func copy(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func copyAndPaste(text: String) {
        copy(text: text)
        simulatePaste()
    }

    func beginSession() {
        savedClipboard = NSPasteboard.general.string(forType: .string)
    }

    func endSession(finalText: String, shouldPaste: Bool, shouldCopy: Bool) {
        if !finalText.isEmpty {
            if shouldPaste {
                copy(text: finalText)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.simulatePaste()
                }
            } else if shouldCopy {
                copy(text: finalText)
            }
        }

        if let saved = savedClipboard, shouldPaste && !shouldCopy {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(saved, forType: .string)
            }
        }
        savedClipboard = nil
    }

    func cancelSession() {
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
}
