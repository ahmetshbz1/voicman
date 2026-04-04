import SwiftUI
import Combine

struct RecordingView: View {
    @ObservedObject var viewModel: RecordingViewModel
    var onTap: (() -> Void)?
    var onSecondaryTap: (() -> Void)?
    var onCloseTap: (() -> Void)?
    
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        panelContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.25), value: viewModel.isExpanded)
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
        VStack(spacing: 0) {
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
                .buttonStyle(HoverableTapStyle())
                .padding(.leading, 12)
                .onHover { isHovered in
                    if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                AudioWave(level: viewModel.state == .paused ? 0 : viewModel.audioLevel)
                    .frame(width: 44, height: 22)
                    .padding(.leading, 10)

                if viewModel.isExpanded {
                    Spacer()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(statusOpacity))
                        .lineLimit(1)
                        .truncationMode(.head)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                        .padding(.trailing, 16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.isExpanded = true
                        }
                        .animation(.easeOut(duration: 0.1), value: viewModel.partialText)
                        .animation(.easeOut(duration: 0.15), value: viewModel.state)
                }

                if viewModel.state == .paused || viewModel.isExpanded {
                    Button { onSecondaryTap?() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    .buttonStyle(HoverableTapStyle())
                    .padding(.trailing, 12)
                    .transition(.scale.combined(with: .opacity))
                    .onHover { isHovered in
                        if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }

                inlineCloseButton
                    .padding(.trailing, 10)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                viewModel.isExpanded.toggle()
            }

            if viewModel.isExpanded {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            TextEditor(text: Binding(
                                get: { viewModel.partialText },
                                set: { 
                                    viewModel.isUserEdited = true
                                    viewModel.partialText = $0 
                                }
                            ))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .focused($isTextFieldFocused)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                                // Yeterli alan açmak için minimum yükseklik:
                                .frame(minHeight: 100, maxHeight: .infinity, alignment: .topLeading)
                            
                            Color.clear
                                .frame(height: 1)
                                .id("bottomAnchor")
                        }
                    }
                    .onChange(of: viewModel.partialText) { oldValue, newValue in
                        if viewModel.state == .recording {
                            withAnimation(.easeOut(duration: 0.15)) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .onChange(of: viewModel.isExpanded) { oldValue, expanded in
            if expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isTextFieldFocused = true
                }
            }
        }
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
        .buttonStyle(HoverableTapStyle())
        .onHover { isHovered in
            if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
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

private struct HoverableTapStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .brightness(isHovered ? 0.2 : 0) // Hover olduğunda rengi biraz aydınlatır
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
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
                    .fill(.white)
                    .frame(width: 2, height: barHeight(for: index))
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
}

private struct TypingIndicator: View {
    @State private var active = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(i == active ? 0.8 : 0.15))
                    .frame(width: i == active ? 6 : 4, height: i == active ? 6 : 4)
                    .offset(y: i == active ? -1 : 0)
                    .animation(.easeInOut(duration: 0.18), value: active)
            }
        }
        .onReceive(timer) { _ in active = (active + 1) % 3 }
        .onDisappear { timer.upstream.connect().cancel() }
    }
}
