import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService: HotkeyServiceProtocol {

    var onHotkeyDown: (() -> Void)?
    var onHotkeyUp: ((TimeInterval) -> Void)?
    var onEnterPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var enterHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var keyDownTime: Date?

    init() { register() }

    func unregister() {
        unregisterEnterHotkey()
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        eventHandlerRef = nil
        hotKeyRef = nil
    }

    func registerEnterHotkey() {
        guard enterHotKeyRef == nil else { return }
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = fourCharCode("VMHK")
        hotKeyID.id = 2 // Enter için ayrı bir ID

        RegisterEventHotKey(
            UInt32(kVK_Return),
            0, // Modifier yok
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &enterHotKeyRef
        )
    }

    func unregisterEnterHotkey() {
        if let ref = enterHotKeyRef {
            UnregisterEventHotKey(ref)
            enterHotKeyRef = nil
        }
    }

    // MARK: - Kayıt

    private func register() {
        let (keyCode, modifiers) = savedHotkey()

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = fourCharCode("VMHK")
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else { return }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return noErr }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in service.handleCarbonEvent(event) }
                return noErr
            },
            2,
            &eventTypes,
            selfPointer,
            &eventHandlerRef
        )
    }

    // MARK: - Olay

    private func handleCarbonEvent(_ event: EventRef) {
        var hotKeyID = EventHotKeyID()
        GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard hotKeyID.id == 1 || hotKeyID.id == 2 else { return }

        let kind = GetEventKind(event)
        
        if hotKeyID.id == 2 {
            if kind == UInt32(kEventHotKeyPressed) {
                onEnterPressed?()
            }
            return
        }

        if kind == UInt32(kEventHotKeyPressed) {
            if keyDownTime == nil {
                keyDownTime = Date()
                onHotkeyDown?()
            }
        } else if kind == UInt32(kEventHotKeyReleased) {
            let duration = keyDownTime.map { Date().timeIntervalSince($0) } ?? 0
            keyDownTime = nil
            onHotkeyUp?(duration)
        }
    }

    // MARK: - Yardımcı

    /// UserDefaults'tan kayıtlı kısayolu oku — yoksa ⌥Space varsayılan
    private func savedHotkey() -> (keyCode: UInt32, modifiers: UInt32) {
        let keyCode: UInt32
        let modifiers: UInt32

        if let kc = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? Int {
            keyCode = UInt32(kc)
        } else {
            keyCode = UInt32(kVK_Space)
        }

        if let mod = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? Int {
            modifiers = UInt32(mod)
        } else {
            modifiers = UInt32(optionKey)
        }

        return (keyCode, modifiers)
    }

    private func fourCharCode(_ s: String) -> FourCharCode {
        s.utf8.reduce(0) { ($0 << 8) | FourCharCode($1) }
    }
}
