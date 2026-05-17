import SwiftUI

struct ContentView: View {
    @StateObject private var generator = TechnoGenerator()

    private let keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var body: some View {
        ZStack {
            ConsoleBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HeaderPanel(isPlaying: generator.isPlaying, tempo: generator.tempo)

                    PlaybackStrip(
                        isPlaying: generator.isPlaying,
                        hasPattern: generator.generatedPattern != nil,
                        generateAction: { generator.generateTechno() },
                        playAction: {
                            if generator.isPlaying {
                                generator.stopTechno()
                            } else if generator.generatedPattern != nil {
                                generator.playTechno { _, _ in }
                            }
                        }
                    )

                    InstrumentPanel {
                        VStack(spacing: 18) {
                            StyleSelector(style: $generator.style)

                            DualDial(
                                tempo: $generator.tempo,
                                intensity: $generator.intensity
                            )

                            KeySelector(
                                key: $generator.key,
                                labels: keys
                            )
                        }
                    }

                    if let pattern = generator.generatedPattern {
                        PatternPanel(
                            pattern: pattern,
                            currentStep: generator.isPlaying ? generator.currentStep : nil
                        )
                    } else {
                        EmptyPatternPanel()
                    }

                    ChannelStrip()
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct ConsoleBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.driftBlack, .driftGraphite, .driftBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                Path { path in
                    let spacing: CGFloat = 22
                    for x in stride(from: CGFloat.zero, through: proxy.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }
                    for y in stride(from: CGFloat.zero, through: proxy.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.025), lineWidth: 1)
            }

            RadialGradient(
                colors: [.driftTeal.opacity(0.16), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

private struct HeaderPanel: View {
    let isPlaying: Bool
    let tempo: Double

    var body: some View {
        InstrumentPanel {
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DRIFT")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .tracking(10)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.driftTeal, .white.opacity(0.72)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("AUTO TECHNO ENGINE")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(.driftAcid)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        StatusPill(isPlaying: isPlaying)
                        Text("\(tempo, specifier: "%.0f") BPM")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.driftTeal)
                    }
                }

                Equalizer(isPlaying: isPlaying)
            }
        }
    }
}

private struct PlaybackStrip: View {
    let isPlaying: Bool
    let hasPattern: Bool
    let generateAction: () -> Void
    let playAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ActionButton(
                title: "GENERATE",
                icon: "sparkles",
                colors: [.driftAcid, .driftAcid.opacity(0.72)],
                foreground: .black,
                action: generateAction
            )

            ActionButton(
                title: isPlaying ? "STOP" : "PLAY",
                icon: isPlaying ? "stop.fill" : "play.fill",
                colors: isPlaying ? [.driftRed, .driftRed.opacity(0.72)] : [.driftTeal, .driftTeal.opacity(0.72)],
                foreground: .driftBlack,
                action: playAction
            )
            .opacity(hasPattern || isPlaying ? 1 : 0.45)
            .disabled(!hasPattern && !isPlaying)
        }
    }
}

private struct StyleSelector: View {
    @Binding var style: TechnoStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelLabel("STYLE")

            HStack(spacing: 8) {
                StyleButton(title: "DRIFT", isSelected: style == .drift) { style = .drift }
                StyleButton(title: "DEEP", isSelected: style == .deep) { style = .deep }
                StyleButton(title: "MINIMAL", isSelected: style == .minimal) { style = .minimal }
            }
        }
    }
}

private struct DualDial: View {
    @Binding var tempo: Double
    @Binding var intensity: Double

    private var tempoProgress: Double {
        (tempo - 80) / 80
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.driftSteel, .driftBlack],
                            center: .center,
                            startRadius: 28,
                            endRadius: 150
                        )
                    )
                    .overlay(Circle().stroke(.black.opacity(0.9), lineWidth: 8))
                    .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1))
                    .shadow(color: .black.opacity(0.75), radius: 18, x: 0, y: 14)

                Ring(progress: intensity, color: .driftTeal, lineWidth: 16)
                    .padding(14)

                Ring(progress: tempoProgress, color: .driftAcid, lineWidth: 10)
                    .padding(38)

                VStack(spacing: 4) {
                    Text("\(tempo, specifier: "%.0f")")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("BPM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.driftAcid)
                    Text("\(intensity * 100, specifier: "%.0f")% DRIVE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.driftTeal)
                        .padding(.top, 6)
                }

                TickRing()
                    .padding(4)
            }
            .frame(width: 250, height: 250)

            VStack(spacing: 14) {
                SliderRow(label: "TEMPO", value: $tempo, range: 80...160, color: .driftAcid, valueText: "\(tempo, specifier: "%.0f") BPM")
                SliderRow(label: "INTENSITY", value: $intensity, range: 0...1, color: .driftTeal, valueText: "\(intensity * 100, specifier: "%.0f")%")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct Ring: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0.08, to: CGFloat(0.08 + (0.84 * progress)))
            .stroke(
                AngularGradient(colors: [color.opacity(0.35), color, color.opacity(0.9)], center: .center),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(102))
    }
}

private struct TickRing: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2

            ZStack {
                ForEach(0..<48, id: \.self) { index in
                    Rectangle()
                        .fill(index % 4 == 0 ? Color.white.opacity(0.22) : Color.white.opacity(0.09))
                        .frame(width: 2, height: index % 4 == 0 ? 12 : 7)
                        .offset(y: -radius + 12)
                        .rotationEffect(.degrees(Double(index) * 7.5))
                }
            }
            .frame(width: size, height: size)
        }
    }
}

private struct KeySelector: View {
    @Binding var key: Int
    let labels: [String]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelLabel("KEY")

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(labels.indices, id: \.self) { index in
                    Button {
                        key = index
                    } label: {
                        Text(labels[index])
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(key == index ? .driftBlack : .driftTeal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(key == index ? Color.driftTeal : Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(key == index ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PatternPanel: View {
    let pattern: TechnoPattern
    let currentStep: Int?

    var body: some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    PanelLabel("16 STEP PATTERN")
                    Spacer()
                    Text(currentStepText)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(currentStep == nil ? .driftAcid : .driftBlack)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(currentStep == nil ? Color.driftAcid.opacity(0.11) : Color.driftAcid)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                StepIndexStrip(currentStep: currentStep)

                VStack(spacing: 10) {
                    PatternRow(label: "KICK", pattern: pattern.drums.kick, color: .driftAcid, symbol: "hexagon", currentStep: currentStep)
                    PatternRow(label: "SNARE", pattern: pattern.drums.snare, color: .driftRed, symbol: "circle", currentStep: currentStep)
                    PatternRow(label: "HIHAT", pattern: pattern.drums.hihat, color: .driftTeal, symbol: "triangle", currentStep: currentStep)
                }
            }
        }
    }

    private var currentStepText: String {
        guard let currentStep else { return "1-16" }
        return "STEP \(currentStep + 1)"
    }
}

private struct StepIndexStrip: View {
    let currentStep: Int?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<16, id: \.self) { index in
                Text("\(index + 1)")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(currentStep == index ? .driftBlack : .white.opacity(0.28))
                    .frame(maxWidth: .infinity)
                    .frame(height: 16)
                    .background(currentStep == index ? Color.driftAcid : Color.white.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: currentStep == index ? Color.driftAcid.opacity(0.55) : .clear, radius: 8, x: 0, y: 0)
            }
        }
        .animation(.easeOut(duration: 0.08), value: currentStep)
    }
}

private struct EmptyPatternPanel: View {
    var body: some View {
        InstrumentPanel {
            VStack(alignment: .leading, spacing: 12) {
                PanelLabel("16 STEP PATTERN")
                HStack(spacing: 4) {
                    ForEach(0..<16, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 34)
                    }
                }
                Text("GENERATE TO ARM THE SEQUENCER")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.38))
            }
        }
    }
}

private struct PatternRow: View {
    let label: String
    let pattern: [Bool]
    let color: Color
    let symbol: String
    let currentStep: Int?

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(color)

                Spacer()
            }

            HStack(spacing: 4) {
                ForEach(pattern.indices, id: \.self) { index in
                    let isActive = currentStep == index
                    let isOn = pattern[index]

                    RoundedRectangle(cornerRadius: 3)
                        .fill(cellFill(isOn: isOn, isActive: isActive))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(cellStroke(isOn: isOn, isActive: isActive), lineWidth: isActive ? 2 : 1)
                        )
                        .overlay(alignment: .top) {
                            if isActive {
                                Rectangle()
                                    .fill(Color.white.opacity(0.55))
                                    .frame(height: 3)
                            }
                        }
                        .scaleEffect(isActive ? 1.12 : 1)
                        .shadow(color: cellGlow(isOn: isOn, isActive: isActive), radius: isActive ? 12 : 7, x: 0, y: 0)
                        .frame(height: 28)
                }
            }
            .animation(.easeOut(duration: 0.08), value: currentStep)
        }
    }

    private func cellFill(isOn: Bool, isActive: Bool) -> Color {
        if isActive && isOn { return color }
        if isActive { return Color.white.opacity(0.18) }
        return isOn ? color : Color.white.opacity(0.07)
    }

    private func cellStroke(isOn: Bool, isActive: Bool) -> Color {
        if isActive { return .white.opacity(0.86) }
        return Color.white.opacity(isOn ? 0.28 : 0.06)
    }

    private func cellGlow(isOn: Bool, isActive: Bool) -> Color {
        if isActive { return (isOn ? color : .white).opacity(0.62) }
        return isOn ? color.opacity(0.38) : .clear
    }
}

private struct ChannelStrip: View {
    var body: some View {
        InstrumentPanel {
            HStack(spacing: 10) {
                MiniChannel(title: "KICK", color: .driftAcid, level: 0.72)
                MiniChannel(title: "SNARE", color: .driftRed, level: 0.52)
                MiniChannel(title: "HIHAT", color: .driftTeal, level: 0.84)
                MasterMeter()
            }
        }
    }
}

private struct MiniChannel: View {
    let title: String
    let color: Color
    let level: Double

    var body: some View {
        VStack(spacing: 9) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(color)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.45))
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(height: CGFloat(86 * level))
            }
            .frame(width: 12, height: 86)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.08), lineWidth: 1))

            Circle()
                .fill(
                    RadialGradient(colors: [.driftSteel, .black], center: .center, startRadius: 4, endRadius: 24)
                )
                .frame(width: 48, height: 48)
                .overlay(Circle().trim(from: 0.05, to: CGFloat(level)).stroke(color, lineWidth: 4).rotationEffect(.degrees(100)))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MasterMeter: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("MASTER")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.64))

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<3, id: \.self) { column in
                    VStack(spacing: 3) {
                        ForEach((0..<8).reversed(), id: \.self) { row in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(row < 2 ? Color.driftRed : (row < 5 ? Color.driftAcid : Color.driftTeal))
                                .opacity(row + column < 7 ? 0.95 : 0.2)
                                .frame(width: 8, height: 6)
                        }
                    }
                }
            }

            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.driftTeal)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InstrumentPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.075), Color.black.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.6), lineWidth: 1)
                    .padding(2)
            )
            .shadow(color: .black.opacity(0.42), radius: 12, x: 0, y: 10)
    }
}

private struct StatusPill: View {
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isPlaying ? Color.driftRed : Color.white.opacity(0.22))
                .frame(width: 8, height: 8)
                .shadow(color: isPlaying ? Color.driftRed.opacity(0.75) : .clear, radius: 7, x: 0, y: 0)

            Text(isPlaying ? "PLAYING" : "READY")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(1.2)
        }
        .foregroundColor(isPlaying ? .driftRed : .white.opacity(0.45))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.36))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private struct Equalizer: View {
    let isPlaying: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<28, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index % 5 == 0 ? Color.driftAcid : Color.driftTeal)
                    .frame(width: 5, height: CGFloat(isPlaying ? ((index * 9) % 28 + 8) : ((index * 5) % 15 + 5)))
                    .opacity(isPlaying ? 0.95 : 0.3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .bottomLeading)
        .padding(10)
        .background(Color.black.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

private struct PanelLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .tracking(2)
            .foregroundColor(.white.opacity(0.62))
    }
}

private struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let valueText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.64))
                Spacer()
                Text(valueText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }

            Slider(value: $value, in: range)
                .tint(color)
        }
    }
}

private struct StyleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .tracking(1)
                .foregroundColor(isSelected ? .driftBlack : .driftTeal)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color.driftAcid : Color.black.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.driftAcid.opacity(0.8) : Color.driftTeal.opacity(0.26), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: isSelected ? Color.driftAcid.opacity(0.28) : .clear, radius: 10, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .tracking(1.3)
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.26), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: colors.first?.opacity(0.26) ?? .clear, radius: 12, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

private extension Color {
    static let driftBlack = Color(red: 0.025, green: 0.028, blue: 0.03)
    static let driftGraphite = Color(red: 0.105, green: 0.112, blue: 0.115)
    static let driftSteel = Color(red: 0.15, green: 0.16, blue: 0.16)
    static let driftTeal = Color(red: 0.34, green: 0.83, blue: 0.78)
    static let driftAcid = Color(red: 0.86, green: 0.9, blue: 0.06)
    static let driftRed = Color(red: 1.0, green: 0.22, blue: 0.16)
}

#Preview {
    ContentView()
}
