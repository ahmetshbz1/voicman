import SwiftUI
import Carbon.HIToolbox

struct ShortcutRecorderView: View {

    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32

    @State private var isRecording = false
    // NSEvent.addLocalMonitorForEvents Any? döndürdüğü için Any zorunlu
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Kısayol Tuşu")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Tıkla ve kombinasyonu bas")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: toggleRecording) {
                HStack(spacing: 7) {
                    if isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                        Text("Kaydediliyor...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.red)
                    } else {
                        Text(displayString)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary.opacity(0.85))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isRecording ? Color.red.opacity(0.12) : Color.primary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isRecording ? Color.red.opacity(0.5) : Color.primary.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: isRecording)
            }
            .buttonStyle(ScaleButtonStyle())
            .focusEffectDisabled()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onDisappear { stopRecording() }
    }

    // MARK: - Kayıt

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                self.stopRecording()
                return nil
            }
            let newMods = carbonModifiers(from: event.modifierFlags)
            guard newMods != 0 else { return nil }

            self.keyCode = UInt32(event.keyCode)
            self.modifiers = newMods
            self.stopRecording()
            self.persist()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func persist() {
        UserDefaults.standard.set(Int(keyCode),   forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "hotkeyModifiers")
    }

    // MARK: - Yardımcı

    private var displayString: String {
        guard keyCode != 0 else { return "Ayarlanmadı" }
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option)  { result |= UInt32(optionKey)  }
        if flags.contains(.shift)   { result |= UInt32(shiftKey)   }
        if flags.contains(.command) { result |= UInt32(cmdKey)     }
        return result
    }

    private func keyCodeToString(_ kc: UInt32) -> String {
        switch Int(kc) {
        case kVK_Space:  return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab:    return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_F1:     return "F1"
        case kVK_F2:     return "F2"
        case kVK_F3:     return "F3"
        case kVK_F4:     return "F4"
        case kVK_F5:     return "F5"
        case kVK_F6:     return "F6"
        case kVK_F7:     return "F7"
        case kVK_F8:     return "F8"
        case kVK_F9:     return "F9"
        case kVK_F10:    return "F10"
        case kVK_F11:    return "F11"
        case kVK_F12:    return "F12"
        default:         return "?\(kc)"
        }
    }
}
