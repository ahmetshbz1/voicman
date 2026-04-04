import XCTest
import Carbon.HIToolbox
@testable import voicman

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    private let defaultsKeys = [
        "hotkeyKeyCode",
        "hotkeyModifiers",
        "hasCompletedOnboarding"
    ]

    override func setUp() {
        super.setUp()
        clearDefaults()
    }

    override func tearDown() {
        clearDefaults()
        super.tearDown()
    }

    func test_hotkeyDisplayString_usesSavedShortcut() {
        UserDefaults.standard.set(Int(kVK_Return), forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(Int(optionKey | shiftKey), forKey: "hotkeyModifiers")

        let sut = OnboardingViewModel()

        XCTAssertEqual(sut.hotkeyDisplayString(), "⌥⇧↩")
    }

    func test_hotkeyDisplayString_usesDefaultShortcutWhenNoSavedValueExists() {
        let sut = OnboardingViewModel()

        XCTAssertEqual(sut.hotkeyDisplayString(), "⌥Space")
    }

    func test_next_advancesStep() {
        let sut = OnboardingViewModel()

        sut.next()

        XCTAssertEqual(sut.step, .microphone)
    }

    func test_next_onLastStep_finishesOnboarding() {
        let sut = OnboardingViewModel()
        sut.step = .complete

        sut.next()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
    }

    func test_finish_marksOnboardingCompletedAndCallsCompletion() {
        let sut = OnboardingViewModel()
        var didComplete = false
        sut.onComplete = {
            didComplete = true
        }

        sut.finish()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
        XCTAssertTrue(didComplete)
    }

    private func clearDefaults() {
        for key in defaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
