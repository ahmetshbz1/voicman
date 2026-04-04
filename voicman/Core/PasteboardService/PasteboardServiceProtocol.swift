import Foundation

@MainActor
protocol PasteboardServiceProtocol: AnyObject {
    func copy(text: String)
    func copyAndPaste(text: String)
    func typePartial(text: String)
    func beginSession()
    func endSession(finalText: String, shouldPaste: Bool)
    func cancelSession()
}
