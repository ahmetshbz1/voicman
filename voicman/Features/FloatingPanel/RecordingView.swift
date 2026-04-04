import SwiftUI
import Combine

struct RecordingView: View {
    @ObservedObject var viewModel: RecordingViewModel
    var onTap: (() -> Void)?
    var onSecondaryTap: (() -> Void)?
    var onCloseTap: (() -> Void)?

    var body: some View {
        panelContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var panelContent: some View {
        Group {
            switch viewModel.state {
            case .idle:         idlePanel
            case .recording, .paused: activePanel
            case .transcribing: transcribingPanel
            case .error:        errorPanel
            }
        }
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

    private var activePanel: some View {
        HStack(spacing: 0) {
            Button { onTap?() } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 30, height: 30)
                    Image(systemName: viewModel.state == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(TapStyle())
            .padding(.leading, 12)

            AudioWave(level: viewModel.state == .paused ? 0 : viewModel.audioLevel)
                .frame(width: 44, height: 22)
                .padding(.leading, 10)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(statusOpacity))
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
                .padding(.trailing, 16)
                .animation(.easeOut(duration: 0.1), value: viewModel.partialText)
                .animation(.easeOut(duration: 0.15), value: viewModel.state)

            if viewModel.state == .paused {
                Button { onSecondaryTap?() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(TapStyle())
                .padding(.trailing, 12)
                .transition(.scale.combined(with: .opacity))
            }

            inlineCloseButton
                .padding(.trailing, 10)
        }
        .panelChrome()
    }

    private var statusText: String {
        if viewModel.state == .paused {
            return viewModel.partialText.isEmpty ? "Duraklatıldı" : viewModel.partialText
        }
        return viewModel.partialText.isEmpty ? "Dinliyor..." : viewModel.partialText
    }

    private var statusOpacity: Double {
        if viewModel.state == .paused && viewModel.partialText.isEmpty {
            return 0.5
        }
        return viewModel.partialText.isEmpty ? 0.35 : 0.85
    }

    private var transcribingPanel: some View {
        HStack(spacing: 10) {
            TypingIndicator()
            Text("Yazılıyor...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
            Spacer(minLength: 0)
            inlineCloseButton
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
            Spacer(minLength: 0)
            inlineCloseButton
        }
        .panelChrome()
    }

    private var inlineCloseButton: some View {
        Button { onCloseTap?() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .frame(width: 22, height: 22)
                .background(Circle().fill(.white.opacity(0.06)))
        }
        .buttonStyle(TapStyle())
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
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(barGradient(for: index))
                    .frame(width: 4, height: barHeight(for: index))
            }
        }
        .frame(height: 22)
        .onReceive(timer) { _ in phase += 0.15 }
        .onDisappear { timer.upstream.connect().cancel() }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let normalizedLevel = CGFloat(max(level, 0.06))
        let wave = (sin(phase + Double(index) * 0.9) + 1) / 2
        let base = CGFloat(8 + index % 2)
        return min(max(base + normalizedLevel * 12 * wave, 7), 22)
    }

    private func barGradient(for index: Int) -> LinearGradient {
        let colors: [Color] = index.isMultiple(of: 2)
            ? [.red.opacity(0.9), .orange.opacity(0.65)]
            : [.pink.opacity(0.85), .orange.opacity(0.5)]
        return LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
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
