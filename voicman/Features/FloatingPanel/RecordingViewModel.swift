import SwiftUI
import Combine

@MainActor
final class RecordingViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case recording
        case paused
        case transcribing
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isVisible: Bool = false
    @Published var isDragging: Bool = false
    @Published var audioLevel: Float = 0
    @Published var partialText: String = ""
    @Published var isExpanded: Bool = false
    var isUserEdited: Bool = false

    func transition(to newState: State) {
        let previousState = state
        state = newState
        if newState != .idle {
            isVisible = true
        }
        if newState == .recording && previousState == .idle {
            partialText = ""
            isUserEdited = false
            isExpanded = false
        }
        if newState == .paused {
            audioLevel = 0
        }
        if newState == .transcribing || newState == .idle {
            isExpanded = false
        }
    }

    func updateTextFromEngine(_ text: String) {
        guard !isUserEdited else { return }
        partialText = text
    }

    func hide() {
        isVisible = false
        isDragging = false
        state = .idle
        partialText = ""
        isUserEdited = false
    }
}
