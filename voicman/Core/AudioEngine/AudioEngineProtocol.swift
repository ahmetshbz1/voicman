import AVFoundation

@MainActor
protocol AudioEngineProtocol: AnyObject {
    func startCapture(
        onBuffer: @MainActor @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void,
        onError: @MainActor @escaping (Error) -> Void
    )
    func stop()
}
