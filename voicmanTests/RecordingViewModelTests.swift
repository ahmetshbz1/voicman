import XCTest
@testable import voicman

@MainActor
final class RecordingViewModelTests: XCTestCase {
    func test_transition_toRecordingFromIdle_resetsTransientStateAndMakesViewVisible() {
        let sut = RecordingViewModel()
        sut.partialText = "eski"
        sut.isUserEdited = true
        sut.isExpanded = true

        sut.transition(to: .recording)

        XCTAssertEqual(sut.state, .recording)
        XCTAssertTrue(sut.isVisible)
        XCTAssertEqual(sut.partialText, "")
        XCTAssertFalse(sut.isUserEdited)
        XCTAssertFalse(sut.isExpanded)
    }

    func test_transition_toPaused_zeroesAudioLevel() {
        let sut = RecordingViewModel()
        sut.audioLevel = 0.8

        sut.transition(to: .paused)

        XCTAssertEqual(sut.state, .paused)
        XCTAssertEqual(sut.audioLevel, 0)
    }

    func test_transition_toTranscribing_collapsesExpandedState() {
        let sut = RecordingViewModel()
        sut.isExpanded = true

        sut.transition(to: .transcribing)

        XCTAssertFalse(sut.isExpanded)
    }

    func test_updateTextFromEngine_doesNotOverwriteUserEditedContent() {
        let sut = RecordingViewModel()
        sut.partialText = "manuel"
        sut.isUserEdited = true

        sut.updateTextFromEngine("engine")

        XCTAssertEqual(sut.partialText, "manuel")
    }

    func test_updateTextFromEngine_overwritesPartialTextWhenUserDidNotEdit() {
        let sut = RecordingViewModel()
        sut.partialText = "eski"
        sut.isUserEdited = false

        sut.updateTextFromEngine("yeni")

        XCTAssertEqual(sut.partialText, "yeni")
    }

    func test_hide_resetsViewModelToIdleState() {
        let sut = RecordingViewModel()
        sut.transition(to: .recording)
        sut.partialText = "metin"
        sut.isUserEdited = true
        sut.isDragging = true

        sut.hide()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.isVisible)
        XCTAssertFalse(sut.isDragging)
        XCTAssertEqual(sut.partialText, "")
        XCTAssertFalse(sut.isUserEdited)
    }
}
