import Carbon.HIToolbox
import XCTest
@testable import voicman

@MainActor
final class HotkeyServiceTests: XCTestCase {
    func test_handleRegisteredHotKey_callsHotkeyDownOnlyOnceUntilRelease() {
        let sut = HotkeyService()
        var downCallCount = 0
        sut.onHotkeyDown = {
            downCallCount += 1
        }

        sut.handleRegisteredHotKey(id: .main, kind: UInt32(kEventHotKeyPressed))
        sut.handleRegisteredHotKey(id: .main, kind: UInt32(kEventHotKeyPressed))

        XCTAssertEqual(downCallCount, 1)
    }

    func test_handleRegisteredHotKey_callsHotkeyUpWithDurationOnRelease() {
        let sut = HotkeyService()
        let expectation = expectation(description: "hotkey up called")
        var receivedDuration: TimeInterval?
        sut.onHotkeyUp = { duration in
            receivedDuration = duration
            expectation.fulfill()
        }

        sut.handleRegisteredHotKey(id: .main, kind: UInt32(kEventHotKeyPressed))
        sut.handleRegisteredHotKey(id: .main, kind: UInt32(kEventHotKeyReleased))

        wait(for: [expectation], timeout: 0.1)
        XCTAssertNotNil(receivedDuration)
        XCTAssertGreaterThanOrEqual(receivedDuration ?? -1, 0)
    }

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

    func test_handleRegisteredHotKey_doesNotCallEnterHandlerOnRelease() {
        let sut = HotkeyService()
        var didCallEnter = false
        sut.onEnterPressed = {
            didCallEnter = true
        }

        sut.handleRegisteredHotKey(id: .enter, kind: UInt32(kEventHotKeyReleased))

        XCTAssertFalse(didCallEnter)
    }

    func test_handleRegisteredHotKey_doesNotCallEscapeHandlerOnRelease() {
        let sut = HotkeyService()
        var didCallEscape = false
        sut.onEscapePressed = {
            didCallEscape = true
        }

        sut.handleRegisteredHotKey(id: .escape, kind: UInt32(kEventHotKeyReleased))

        XCTAssertFalse(didCallEscape)
    }

    func test_handleRegisteredHotKey_callsHotkeyUpWithZeroDurationWhenReleasedWithoutPress() {
        let sut = HotkeyService()
        let expectation = expectation(description: "hotkey up called")
        var receivedDuration: TimeInterval?
        sut.onHotkeyUp = { duration in
            receivedDuration = duration
            expectation.fulfill()
        }

        sut.handleRegisteredHotKey(id: .main, kind: UInt32(kEventHotKeyReleased))

        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(receivedDuration, 0)
    }
}
