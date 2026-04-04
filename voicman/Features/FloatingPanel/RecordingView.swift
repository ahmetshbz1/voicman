import SwiftUI
import Combine

struct RecordingView: View {
    @ObservedObject var viewModel: RecordingViewModel
    var onTap: (() -> Void)?

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:         idlePanel
            case .recording:    recordingPanel
            case .transcribing: transcribingPanel
            case .error:        errorPanel
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var idlePanel: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.3))
            Text("⌥Space")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
        }
        .panelChrome()
    }

    private var recordingPanel: some View {
        HStack(spacing: 0) {
            Button { onTap?() } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 30, height: 30)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white)
                        .frame(width: 10, height: 10)
                }
            }
            .buttonStyle(TapStyle())
            .padding(.leading, 12)

            // Canlı dalga
            AudioWave(level: viewModel.audioLevel)
                .frame(width: 44, height: 22)
                .padding(.leading, 10)

            // Partial text
            Text(viewModel.partialText.isEmpty ? "Dinliyor..." : viewModel.partialText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(viewModel.partialText.isEmpty ? 0.35 : 0.85))
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
                .padding(.trailing, 16)
                .animation(.easeOut(duration: 0.1), value: viewModel.partialText)
        }
        .panelChrome()
    }

    private var transcribingPanel: some View {
        HStack(spacing: 10) {
            TypingIndicator()
            Text("Yazılıyor...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .panelChrome()
    }

    private var errorPanel: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11)).foregroundStyle(.orange)
            Text("Hata")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .panelChrome()
    }
}

private struct PanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
    }
}

private extension View {
    func panelChrome() -> some View {
        modifier(PanelChrome())
    }
}

private struct TapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct AudioWave: View {
    var level: Float

    @State private var phase: Double = 0
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { ctx, size in
            let lev = CGFloat(max(level, 0.05))
            let midY = size.height / 2
            let amp = size.height * 0.4 * lev

            var path = Path()
            let steps = Int(size.width)
            for x in 0...steps {
                let xf = CGFloat(x)
                let norm = xf / size.width
                let envelope = sin(norm * Double.pi)
                let y = midY + sin(phase + norm * 4 * Double.pi) * amp * envelope
                if x == 0 { path.move(to: CGPoint(x: xf, y: y)) }
                else { path.addLine(to: CGPoint(x: xf, y: y)) }
            }

            ctx.stroke(path, with: .linearGradient(
                Gradient(colors: [.red.opacity(0.8), .orange.opacity(0.5)]),
                startPoint: CGPoint(x: 0, y: midY),
                endPoint: CGPoint(x: size.width, y: midY)
            ), lineWidth: 2)
        }
        .onReceive(timer) { _ in phase += 0.15 }
        .onDisappear { timer.upstream.connect().cancel() }
    }
}

private struct TypingIndicator: View {
    @State private var active = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.cyan.opacity(i == active ? 0.8 : 0.15))
                    .frame(width: i == active ? 6 : 4, height: i == active ? 6 : 4)
                    .offset(y: i == active ? -1 : 0)
                    .animation(.easeInOut(duration: 0.18), value: active)
            }
        }
        .onReceive(timer) { _ in active = (active + 1) % 3 }
        .onDisappear { timer.upstream.connect().cancel() }
    }
}
