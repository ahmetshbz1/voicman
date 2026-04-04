import SwiftUI
import Combine

@MainActor
final class RecordingViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case recording
        case transcribing
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isVisible: Bool = false
    @Published var audioLevel: Float = 0
    @Published var partialText: String = ""

    func transition(to newState: State) {
        state = newState
        if newState != .idle {
            isVisible = true
        }
        if newState == .recording {
            partialText = ""
        }
    }

    func hide() {
        isVisible = false
        state = .idle
        partialText = ""
    }
}
