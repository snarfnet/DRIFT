import SwiftUI

struct ContentView: View {
    @StateObject private var generator = TechnoGenerator()
    private let keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var body: some View {
        ZStack {
            DetroitBackplate()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HeaderDeck(isPlaying: generator.isPlaying, tempo: generator.tempo)

                    TransportDeck(
                        isPlaying: generator.isPlaying,
                        hasPattern: generator.generatedPattern != nil,
                        generateAction: { generator.generateTechno() },
                        playAction: togglePlayback
                    )

                    MachinePanel(title: "PATCH BAY") {
                        StyleSelector(style: $generator.style)
                        TempoDriveDeck(tempo: $generator.tempo, intensity: $generator.intensity)
                        KeySelector(key: $generator.key, labels: keys)
                    }

                    if let pattern = generator.generatedPattern {
                        SequencerPanel(pattern: pattern, currentStep: generator.isPlaying ? generator.currentStep : nil)
                    } else {
                        EmptySequencerPanel()
                    }

                    MixerPanel()
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, RuntimeEnvironment.isNativeDevice ? 84 : 28)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if RuntimeEnvironment.isNativeDevice {
                AdRail()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.72))
            }
        }
        .preferredColorScheme(.dark)
    }

    private func togglePlayback() {
        if generator.isPlaying {
            generator.stopTechno()
        } else if generator.generatedPattern != nil {
            generator.playTechno { _, _ in }
        }
    }
}

private struct DetroitBackplate: View {
    var body: some View {
        ZStack {
            Image("DetroitMachineBackdrop")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.34))
                .overlay(
                    LinearGradient(
                        colors: [.clear, .driftOil.opacity(0.55), .driftOil],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            CircuitGrid()
                .stroke(Color.driftCyan.opacity(0.08), lineWidth: 1)
                .ignoresSafeArea()

            RadialGradient(
                colors: [.driftAmber.opacity(0.24), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()
        }
    }
}

private struct HeaderDeck: View {
    let isPlaying: Bool
    let tempo: Double

    var body: some View {
        MachinePanel(title: "SALVAGED UNIT") {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("DRIFT")
                        .font(.system(size: 45, weight: .black, design: .monospaced))
                        .tracking(8)
                        .foregroundStyle(LinearGradient(colors: [.driftBone, .driftCyan], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .driftCyan.opacity(0.45), radius: 12)

                    Text("TECHNO ENGINE")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.driftAmber)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusLamp(isOn: isPlaying)
                    Text("\(tempo, specifier: "%.0f") BPM")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.driftCyan)
                }
            }

            LedScope(isPlaying: isPlaying)
        }
    }
}

private struct TransportDeck: View {
    let isPlaying: Bool
    let hasPattern: Bool
    let generateAction: () -> Void
    let playAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            DeckButton(title: "GENERATE", icon: "waveform.path", color: .driftAmber, action: generateAction)
            DeckButton(title: isPlaying ? "STOP" : "PLAY", icon: isPlaying ? "stop.fill" : "play.fill", color: isPlaying ? .driftRed : .driftCyan, action: playAction)
                .opacity(hasPattern || isPlaying ? 1 : 0.42)
                .disabled(!hasPattern && !isPlaying)
        }
    }
}

private struct StyleSelector: View {
    @Binding var style: TechnoStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PanelLabel("STYLE")
            HStack(spacing: 8) {
                StyleButton(title: "DRIFT", selected: style == .drift) { style = .drift }
                StyleButton(title: "DEEP", selected: style == .deep) { style = .deep }
                StyleButton(title: "MINIMAL", selected: style == .minimal) { style = .minimal }
            }
        }
    }
}

private struct TempoDriveDeck: View {
    @Binding var tempo: Double
    @Binding var intensity: Double

    private var tempoProgress: Double { (tempo - 80) / 80 }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RotorPlate()
                MeterRing(progress: intensity, color: .driftCyan, lineWidth: 15).padding(13)
                MeterRing(progress: tempoProgress, color: .driftAmber, lineWidth: 9).padding(38)

                VStack(spacing: 3) {
                    Text("\(tempo, specifier: "%.0f")")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.driftBone)
                    Text("BPM")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.driftAmber)
                    Text("\(intensity * 100, specifier: "%.0f")% DRIVE")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(.driftCyan)
                        .padding(.top, 6)
                }
            }
            .frame(width: 250, height: 250)
            .frame(maxWidth: .infinity)

            SliderRow(label: "TEMPO", value: $tempo, range: 80...160, color: .driftAmber, valueText: String(format: "%.0f BPM", tempo))
            SliderRow(label: "DRIVE", value: $intensity, range: 0...1, color: .driftCyan, valueText: String(format: "%.0f%%", intensity * 100))
        }
    }
}

private struct KeySelector: View {
    @Binding var key: Int
    let labels: [String]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PanelLabel("ROOT KEY")
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(labels.indices, id: \.self) { index in
                    Button {
                        key = index
                    } label: {
                        Text(labels[index])
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(key == index ? .driftOil : .driftBone.opacity(0.72))
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(key == index ? Color.driftAmber : Color.driftSteel.opacity(0.72))
                            .clipShape(ChippedRect())
                            .overlay(ChippedRect().stroke(key == index ? Color.driftBone.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1))
                            .shadow(color: key == index ? Color.driftAmber.opacity(0.35) : .clear, radius: 9)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SequencerPanel: View {
    let pattern: TechnoPattern
    let currentStep: Int?

    var body: some View {
        MachinePanel(title: "16 STEP SEQUENCER") {
            HStack {
                PanelLabel("PATTERN")
                Spacer()
                Text(currentStep.map { "STEP \($0 + 1)" } ?? "ARMED")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(currentStep == nil ? .driftAmber : .driftOil)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(currentStep == nil ? Color.driftAmber.opacity(0.16) : Color.driftAmber)
                    .clipShape(ChippedRect())
            }

            StepNumbers(currentStep: currentStep)
            PatternRow(label: "KICK", pattern: pattern.drums.kick, color: .driftAmber, currentStep: currentStep)
            PatternRow(label: "SNARE", pattern: pattern.drums.snare, color: .driftRed, currentStep: currentStep)
            PatternRow(label: "HIHAT", pattern: pattern.drums.hihat, color: .driftCyan, currentStep: currentStep)
        }
    }
}

private struct EmptySequencerPanel: View {
    var body: some View {
        MachinePanel(title: "16 STEP SEQUENCER") {
            HStack(spacing: 4) {
                ForEach(0..<16, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index % 4 == 0 ? Color.driftAmber.opacity(0.18) : Color.white.opacity(0.07))
                        .frame(height: 36)
                }
            }
            Text("GENERATE TO PATCH A NEW LOOP")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(1)
                .foregroundColor(.white.opacity(0.45))
        }
    }
}

private struct MixerPanel: View {
    var body: some View {
        MachinePanel(title: "SCRAP MIXER") {
            HStack(spacing: 10) {
                MiniChannel(title: "KICK", color: .driftAmber, level: 0.74)
                MiniChannel(title: "SNARE", color: .driftRed, level: 0.55)
                MiniChannel(title: "HIHAT", color: .driftCyan, level: 0.86)
                MasterMeter()
            }
        }
    }
}

private struct MachinePanel<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Rivet()
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.driftBone.opacity(0.58))
                Spacer()
                Rivet()
            }
            content
        }
        .padding(14)
        .background(
            ZStack {
                ChippedRect()
                    .fill(LinearGradient(colors: [.driftPanel, .driftSteel.opacity(0.88), .driftOil.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
                CircuitGrid().stroke(Color.white.opacity(0.035), lineWidth: 1)
            }
        )
        .clipShape(ChippedRect())
        .overlay(ChippedRect().stroke(Color.white.opacity(0.12), lineWidth: 1))
        .overlay(ChippedRect().stroke(Color.driftRust.opacity(0.32), lineWidth: 2).padding(2))
        .shadow(color: .black.opacity(0.65), radius: 16, x: 0, y: 12)
    }
}

private struct DeckButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .tracking(1.2)
            }
            .foregroundColor(title == "STOP" ? .driftBone : .driftOil)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(LinearGradient(colors: [color, color.opacity(0.72), .driftRust.opacity(0.34)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(ChippedRect())
            .overlay(ChippedRect().stroke(Color.white.opacity(0.24), lineWidth: 1))
            .shadow(color: color.opacity(0.28), radius: 12)
        }
        .buttonStyle(.plain)
    }
}

private struct StyleButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .tracking(1)
                .foregroundColor(selected ? .driftOil : .driftBone.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(selected ? Color.driftCyan : Color.driftSteel.opacity(0.62))
                .clipShape(ChippedRect())
                .overlay(ChippedRect().stroke(selected ? Color.driftBone.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
                    .foregroundColor(.white.opacity(0.62))
                Spacer()
                Text(valueText)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(color)
            }
            Slider(value: $value, in: range)
                .tint(color)
        }
        .padding(10)
        .background(Color.black.opacity(0.26))
        .clipShape(ChippedRect())
        .overlay(ChippedRect().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private struct PatternRow: View {
    let label: String
    let pattern: [Bool]
    let color: Color
    let currentStep: Int?

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(color)
                Spacer()
            }

            HStack(spacing: 4) {
                ForEach(pattern.indices, id: \.self) { index in
                    let on = pattern[index]
                    let active = currentStep == index
                    RoundedRectangle(cornerRadius: 3)
                        .fill(active ? color : (on ? color.opacity(0.86) : Color.white.opacity(0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(active ? Color.white.opacity(0.9) : Color.white.opacity(0.08), lineWidth: active ? 2 : 1))
                        .frame(height: 28)
                        .scaleEffect(active ? 1.12 : 1)
                        .shadow(color: (active || on) ? color.opacity(0.42) : .clear, radius: active ? 12 : 6)
                }
            }
            .animation(.easeOut(duration: 0.08), value: currentStep)
        }
    }
}

private struct StepNumbers: View {
    let currentStep: Int?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<16, id: \.self) { index in
                Text("\(index + 1)")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(currentStep == index ? .driftOil : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 16)
                    .background(currentStep == index ? Color.driftAmber : Color.black.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }
}

private struct MiniChannel: View {
    let title: String
    let color: Color
    let level: Double

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(color)

            ZStack(alignment: .bottom) {
                ChippedRect().fill(Color.black.opacity(0.42))
                ChippedRect().fill(color.opacity(0.85)).frame(height: CGFloat(82 * level))
            }
            .frame(width: 14, height: 82)
            .overlay(ChippedRect().stroke(Color.white.opacity(0.12), lineWidth: 1))

            Knob(level: level, color: color)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MasterMeter: View {
    var body: some View {
        VStack(spacing: 7) {
            Text("MASTER")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.driftBone.opacity(0.68))

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<3, id: \.self) { column in
                    VStack(spacing: 3) {
                        ForEach((0..<8).reversed(), id: \.self) { row in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(row < 2 ? Color.driftRed : (row < 5 ? Color.driftAmber : Color.driftCyan))
                                .opacity(row + column < 7 ? 0.96 : 0.22)
                                .frame(width: 8, height: 6)
                        }
                    }
                }
            }

            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.driftCyan)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AdRail: View {
    var body: some View {
        AdMobBannerView()
            .frame(width: 320, height: 50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color.driftPanel.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

private struct LedScope: View {
    let isPlaying: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<30, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index % 5 == 0 ? Color.driftAmber : Color.driftCyan)
                    .frame(width: 5, height: CGFloat(isPlaying ? ((index * 9) % 30 + 8) : ((index * 5) % 14 + 5)))
                    .opacity(isPlaying ? 0.96 : 0.28)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .bottomLeading)
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(ChippedRect())
        .overlay(ChippedRect().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private struct RotorPlate: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [.driftSteel, .driftPanel, .driftOil], center: .center, startRadius: 20, endRadius: 145))
                .overlay(Circle().stroke(Color.driftRust.opacity(0.72), lineWidth: 7))
                .overlay(Circle().stroke(Color.black.opacity(0.72), lineWidth: 13).padding(-2))
                .shadow(color: .black.opacity(0.85), radius: 24, x: 0, y: 18)

            ForEach(0..<48, id: \.self) { index in
                Rectangle()
                    .fill(index % 4 == 0 ? Color.white.opacity(0.24) : Color.white.opacity(0.08))
                    .frame(width: 2, height: index % 4 == 0 ? 13 : 7)
                    .offset(y: -112)
                    .rotationEffect(.degrees(Double(index) * 7.5))
            }

            ForEach(0..<8, id: \.self) { index in
                CablePath(offset: CGFloat(index - 4) * 12)
                    .stroke(index % 2 == 0 ? Color.driftCyan.opacity(0.26) : Color.driftAmber.opacity(0.22), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }

            Circle()
                .fill(Color.black.opacity(0.46))
                .frame(width: 90, height: 90)
                .overlay(Circle().stroke(Color.driftCyan.opacity(0.45), lineWidth: 2))
        }
    }
}

private struct MeterRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Circle()
            .trim(from: 0.08, to: CGFloat(0.08 + 0.84 * min(max(progress, 0), 1)))
            .stroke(AngularGradient(colors: [color.opacity(0.35), color, color.opacity(0.88)], center: .center), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(102))
    }
}

private struct Knob: View {
    let level: Double
    let color: Color

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.driftSteel, .driftOil], center: .center, startRadius: 4, endRadius: 24))
            .frame(width: 46, height: 46)
            .overlay(Circle().trim(from: 0.05, to: CGFloat(level)).stroke(color, lineWidth: 4).rotationEffect(.degrees(100)))
            .overlay(Rectangle().fill(Color.white.opacity(0.22)).frame(width: 2, height: 16).offset(y: -10).rotationEffect(.degrees(level * 260 - 130)))
    }
}

private struct StatusLamp: View {
    let isOn: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isOn ? Color.driftRed : Color.driftCyan.opacity(0.72))
                .frame(width: 9, height: 9)
                .shadow(color: isOn ? .driftRed.opacity(0.8) : .driftCyan.opacity(0.5), radius: 8)
            Text(isOn ? "RUNNING" : "READY")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(1)
        }
        .foregroundColor(isOn ? .driftRed : .driftCyan)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.34))
        .clipShape(Capsule())
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

private struct Rivet: View {
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.driftBone.opacity(0.55), .driftSteel, .black], center: .topLeading, startRadius: 1, endRadius: 8))
            .frame(width: 10, height: 10)
    }
}

private struct CircuitGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 28
        for x in stride(from: rect.minX, through: rect.maxX, by: spacing) {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        for y in stride(from: rect.minY, through: rect.maxY, by: spacing) {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

private struct CablePath: Shape {
    let offset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.midX + offset, y: rect.minY + 28),
            control1: CGPoint(x: rect.midX - 32, y: rect.midY - 34),
            control2: CGPoint(x: rect.midX + offset + 34, y: rect.midY - 70)
        )
        return path
    }
}

private struct ChippedRect: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 7, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 9))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 5))
        path.addLine(to: CGPoint(x: rect.maxX - 18, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 8, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 10))
        path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.minY + 5))
        path.closeSubpath()
        return path
    }
}

private extension Color {
    static let driftOil = Color(red: 0.025, green: 0.027, blue: 0.03)
    static let driftPanel = Color(red: 0.105, green: 0.11, blue: 0.115)
    static let driftSteel = Color(red: 0.25, green: 0.25, blue: 0.23)
    static let driftBone = Color(red: 0.84, green: 0.82, blue: 0.72)
    static let driftAmber = Color(red: 0.96, green: 0.63, blue: 0.18)
    static let driftCyan = Color(red: 0.18, green: 0.84, blue: 0.92)
    static let driftRust = Color(red: 0.66, green: 0.25, blue: 0.13)
    static let driftRed = Color(red: 1.0, green: 0.2, blue: 0.14)
}

#Preview {
    ContentView()
}
