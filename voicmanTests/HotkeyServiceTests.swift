import Carbon.HIToolbox
import XCTest
@testable import voicman

@MainActor
final class HotkeyServiceTests: XCTestCase {
    func test_handleRegisteredHotKey_callsEscapeHandlerOnEscapePress() {
        let sut = HotkeyService()
        var didCallEscape = false
        sut.onEscapePressed = {
            didCallEscape = true
        }

        sut.handleRegisteredHotKey(id: .escape, kind: UInt32(kEventHotKeyPressed))

        XCTAssertTrue(didCallEscape)
    }

    func test_handleRegisteredHotKey_callsEnterHandlerOnEnterPress() {
        let sut = HotkeyService()
        var didCallEnter = false
        sut.onEnterPressed = {
            didCallEnter = true
        }

        sut.handleRegisteredHotKey(id: .enter, kind: UInt32(kEventHotKeyPressed))

        XCTAssertTrue(didCallEnter)
    }
}
