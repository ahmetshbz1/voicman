import Foundation

/// Global klavye kısayolu olaylarını yayınlar.
@MainActor
protocol HotkeyServiceProtocol: AnyObject {
    /// Tuş basıldığında çağrılır.
    var onHotkeyDown: (() -> Void)? { get set }
    /// Tuş bırakıldığında çağrılır. Parametre: basılı tutma süresi (saniye).
    var onHotkeyUp: ((TimeInterval) -> Void)? { get set }
    /// Yalnızca Enter (Return) basıldığında tetiklenir (Global)
    var onEnterPressed: (() -> Void)? { get set }
    /// Yalnızca Escape basıldığında tetiklenir (Global)
    var onEscapePressed: (() -> Void)? { get set }

    func unregister()
    func registerEnterHotkey()
    func registerEscapeHotkey()
    func unregisterEnterHotkey()
    func unregisterEscapeHotkey()
}
