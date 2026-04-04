import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService: HotkeyServiceProtocol {
    enum RegisteredHotKeyID: UInt32 {
        case main = 1
        case enter = 2
        case escape = 3
    }

    var onHotkeyDown: (() -> Void)?
    var onHotkeyUp: ((TimeInterval) -> Void)?
    var onEnterPressed: (() -> Void)?
    var onEscapePressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var enterHotKeyRef: EventHotKeyRef?
    private var escapeHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var keyDownTime: Date?

    init() { register() }

    func unregister() {
        unregisterEnterHotkey()
        unregisterEscapeHotkey()
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        eventHandlerRef = nil
        hotKeyRef = nil
    }

    func registerEnterHotkey() {
        guard enterHotKeyRef == nil else { return }
        enterHotKeyRef = registerAuxiliaryHotkey(keyCode: UInt32(kVK_Return), id: .enter)
    }

    func registerEscapeHotkey() {
        guard escapeHotKeyRef == nil else { return }
        escapeHotKeyRef = registerAuxiliaryHotkey(keyCode: UInt32(kVK_Escape), id: .escape)
    }

    func unregisterEnterHotkey() {
        if let ref = enterHotKeyRef {
            UnregisterEventHotKey(ref)
            enterHotKeyRef = nil
        }
    }

    func unregisterEscapeHotkey() {
        if let ref = escapeHotKeyRef {
            UnregisterEventHotKey(ref)
            escapeHotKeyRef = nil
        }
    }

    // MARK: - Kayıt

    private func register() {
        let (keyCode, modifiers) = savedHotkey()

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = fourCharCode("VMHK")
        hotKeyID.id = RegisteredHotKeyID.main.rawValue

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
        guard let id = RegisteredHotKeyID(rawValue: hotKeyID.id) else { return }

        let kind = GetEventKind(event)

        handleRegisteredHotKey(id: id, kind: kind)
    }

    func handleRegisteredHotKey(id: RegisteredHotKeyID, kind: UInt32) {
        if id == .enter {
            if kind == UInt32(kEventHotKeyPressed) {
                onEnterPressed?()
            }
            return
        }

        if id == .escape {
            if kind == UInt32(kEventHotKeyPressed) {
                onEscapePressed?()
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

    private func registerAuxiliaryHotkey(keyCode: UInt32, id: RegisteredHotKeyID) -> EventHotKeyRef? {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = fourCharCode("VMHK")
        hotKeyID.id = id.rawValue

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            0,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr else { return nil }
        return ref
    }
}
