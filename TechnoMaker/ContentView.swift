import SwiftUI

struct ContentView: View {
    @StateObject private var generator = TechnoGenerator()

    private let keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    var body: some View {
        ZStack {
            ConsoleBackground()

            VStack(spacing: 0) {
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
                    .padding(.bottom, 18)
                }

                if RuntimeEnvironment.isNativeDevice {
                    AdRail()
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct AdRail: View {
    var body: some View {
        AdMobBannerView()
            .frame(width: 320, height: 50)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.52), Color.driftCanopy.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                UnevenVine()
                    .stroke(Color.driftMoss.opacity(0.36), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .padding(.horizontal, 18)
                    .frame(height: 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.driftMoss.opacity(0.25), lineWidth: 1))
    }
}

private struct ConsoleBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.driftBlack, .driftCanopy, .driftGraphite, .driftBlack],
                startPoint: .top,
                endPoint: .bottom
            )

            RuinedSkyline()
                .opacity(0.72)

            GeometryReader { proxy in
                Path { path in
                    let spacing: CGFloat = 24
                    for x in stride(from: CGFloat.zero, through: proxy.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }
                    for y in stride(from: CGFloat.zero, through: proxy.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(Color.driftLeaf.opacity(0.035), lineWidth: 1)
            }

            RadialGradient(
                colors: [.driftLeaf.opacity(0.28), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )

            VineField()
                .opacity(0.58)
        }
        .ignoresSafeArea()
    }
}

private struct RuinedSkyline: View {
    private let towers: [(x: CGFloat, width: CGFloat, height: CGFloat, lean: CGFloat)] = [
        (0.02, 0.16, 0.42, -12),
        (0.18, 0.12, 0.32, 5),
        (0.34, 0.2, 0.5, -5),
        (0.58, 0.13, 0.36, 10),
        (0.72, 0.22, 0.46, -8)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                ForEach(towers.indices, id: \.self) { index in
                    let tower = towers[index]
                    let width = proxy.size.width * tower.width
                    let height = proxy.size.height * tower.height

                    ZStack(alignment: .top) {
                        UnevenTower(lean: tower.lean)
                            .fill(
                                LinearGradient(
                                    colors: [.driftConcrete.opacity(0.52), .driftBlack.opacity(0.92)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(UnevenTower(lean: tower.lean).stroke(Color.driftBone.opacity(0.09), lineWidth: 1))

                        WindowGrid(seed: index)
                            .padding(.top, 18)
                            .padding(.horizontal, 8)

                        MossCap()
                            .frame(height: 28)
                            .offset(y: -10)
                    }
                    .frame(width: width, height: height)
                    .position(
                        x: proxy.size.width * tower.x + width / 2,
                        y: proxy.size.height - height / 2
                    )
                }
            }
        }
    }
}

private struct UnevenTower: Shape {
    let lean: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + lean + 2, y: rect.minY + 18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38 + lean, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44 + lean, y: rect.minY + 24))
        path.addLine(to: CGPoint(x: rect.maxX + lean - 6, y: rect.minY + 12))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct WindowGrid: View {
    let seed: Int

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { column in
                        Rectangle()
                            .fill(windowColor(row: row, column: column))
                            .frame(height: 8)
                    }
                }
            }
        }
    }

    private func windowColor(row: Int, column: Int) -> Color {
        let lit = (row * 3 + column + seed) % 7 == 0
        return lit ? .driftAmber.opacity(0.44) : .driftBlack.opacity(0.42)
    }
}

private struct MossCap: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<18, id: \.self) { index in
                Capsule()
                    .fill(index % 3 == 0 ? Color.driftLeaf : Color.driftMoss)
                    .frame(width: CGFloat((index % 4) + 3), height: CGFloat((index * 5) % 18 + 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 5)
    }
}

private struct VineField: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                for vine in 0..<8 {
                    let startX = proxy.size.width * CGFloat(vine) / 7
                    path.move(to: CGPoint(x: startX, y: -20))
                    for step in 0..<9 {
                        let y = CGFloat(step) * proxy.size.height / 8
                        let x = startX + sin(CGFloat(step + vine) * 0.9) * 28
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.driftMoss.opacity(0.18), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            ForEach(0..<36, id: \.self) { index in
                Leaf()
                    .fill(index % 2 == 0 ? Color.driftLeaf.opacity(0.2) : Color.driftMoss.opacity(0.22))
                    .frame(width: CGFloat(index % 5 + 8), height: CGFloat(index % 7 + 12))
                    .rotationEffect(.degrees(Double((index * 37) % 90) - 45))
                    .position(
                        x: proxy.size.width * CGFloat((index * 29) % 100) / 100,
                        y: proxy.size.height * CGFloat((index * 17) % 100) / 100
                    )
            }
        }
    }
}

private struct Leaf: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY))
        return path
    }
}

private struct ChippedPad: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 5, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 9, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 8))
        path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.maxX - 18, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 7, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 9))
        path.addLine(to: CGPoint(x: rect.minX + 3, y: rect.minY + 4))
        path.closeSubpath()
        return path
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
                                    colors: [.driftBone, .driftLeaf, .driftRust],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .driftLeaf.opacity(0.42), radius: 8, x: 0, y: 0)

                        Text("AUTO TECHNO ENGINE")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(.driftAmber)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        StatusPill(isPlaying: isPlaying)
                        Text("\(tempo, specifier: "%.0f") BPM")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.driftLeaf)
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
                icon: "leaf.fill",
                colors: [.driftBone, .driftAmber, .driftRust],
                foreground: .driftBlack,
                action: generateAction
            )

            ActionButton(
                title: isPlaying ? "STOP" : "PLAY",
                icon: isPlaying ? "stop.fill" : "play.fill",
                colors: isPlaying ? [.driftRust, .driftRed.opacity(0.74)] : [.driftLeaf, .driftMoss.opacity(0.9), .driftCanopy],
                foreground: isPlaying ? .driftBone : .driftBlack,
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
                RotorBody()

                Ring(progress: intensity, color: .driftLeaf, lineWidth: 16)
                    .padding(14)

                Ring(progress: tempoProgress, color: .driftAmber, lineWidth: 10)
                    .padding(38)

                MossRing()
                    .padding(22)

                VStack(spacing: 4) {
                    Text("\(tempo, specifier: "%.0f")")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.driftBone)
                        .shadow(color: .driftAmber.opacity(0.4), radius: 5, x: 0, y: 0)
                    Text("BPM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.driftAmber)
                    Text("\(intensity * 100, specifier: "%.0f")% DRIVE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.driftLeaf)
                        .padding(.top, 6)
                }

                TickRing()
                    .padding(4)
            }
            .frame(width: 250, height: 250)

            VStack(spacing: 14) {
                SliderRow(label: "TEMPO", value: $tempo, range: 80...160, color: .driftAmber, valueText: String(format: "%.0f BPM", tempo))
                SliderRow(label: "INTENSITY", value: $intensity, range: 0...1, color: .driftLeaf, valueText: String(format: "%.0f%%", intensity * 100))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RotorBody: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.driftConcrete, .driftSteel, .driftBlack],
                        center: .center,
                        startRadius: 18,
                        endRadius: 150
                    )
                )
                .overlay(Circle().stroke(Color.driftRust.opacity(0.62), lineWidth: 7))
                .overlay(Circle().stroke(.black.opacity(0.82), lineWidth: 13).padding(-2))
                .overlay(Circle().stroke(Color.driftBone.opacity(0.12), lineWidth: 1).padding(6))
                .shadow(color: .black.opacity(0.85), radius: 24, x: 0, y: 18)

            ForEach(0..<10, id: \.self) { index in
                Capsule()
                    .fill(index % 2 == 0 ? Color.driftRust.opacity(0.38) : Color.driftMoss.opacity(0.42))
                    .frame(width: CGFloat(42 + (index % 4) * 12), height: 5)
                    .offset(y: CGFloat(-92 + index * 20))
                    .rotationEffect(.degrees(Double(index * 31)))
                    .blendMode(.screen)
            }

            ForEach(0..<7, id: \.self) { index in
                Path { path in
                    path.move(to: CGPoint(x: 125, y: 125))
                    path.addLine(to: CGPoint(x: 125 + CGFloat((index - 3) * 18), y: CGFloat(22 + index * 17)))
                }
                .stroke(Color.black.opacity(0.38), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }

            Circle()
                .fill(Color.black.opacity(0.36))
                .frame(width: 92, height: 92)
                .overlay(Circle().stroke(Color.driftMoss.opacity(0.42), lineWidth: 2))
        }
    }
}

private struct MossRing: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                ForEach(0..<24, id: \.self) { index in
                    Capsule()
                        .fill(index % 3 == 0 ? Color.driftLeaf.opacity(0.74) : Color.driftMoss.opacity(0.62))
                        .frame(width: CGFloat(index % 4 + 5), height: CGFloat(index % 5 + 12))
                        .offset(y: -size / 2 + 12)
                        .rotationEffect(.degrees(Double(index) * 15))
                }
            }
            .frame(width: size, height: size)
        }
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
                            .foregroundColor(key == index ? .driftBlack : .driftBone.opacity(0.76))
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                ZStack {
                                    ChippedPad()
                                        .fill(key == index ? Color.driftAmber : Color.driftConcrete.opacity(0.58))
                                    if key == index {
                                        Leaf()
                                            .fill(Color.driftMoss.opacity(0.3))
                                            .frame(width: 18, height: 24)
                                            .offset(x: 9, y: -3)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(key == index ? Color.driftBone.opacity(0.45) : Color.driftMoss.opacity(0.26), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .shadow(color: key == index ? Color.driftAmber.opacity(0.24) : .clear, radius: 8, x: 0, y: 0)
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
                        .foregroundColor(currentStep == nil ? .driftAmber : .driftBlack)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(currentStep == nil ? Color.driftAmber.opacity(0.13) : Color.driftAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                StepIndexStrip(currentStep: currentStep)

                VStack(spacing: 10) {
                    PatternRow(label: "KICK", pattern: pattern.drums.kick, color: .driftAmber, symbol: "hexagon", currentStep: currentStep)
                    PatternRow(label: "SNARE", pattern: pattern.drums.snare, color: .driftRust, symbol: "circle", currentStep: currentStep)
                    PatternRow(label: "HIHAT", pattern: pattern.drums.hihat, color: .driftLeaf, symbol: "triangle", currentStep: currentStep)
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
                    .background(currentStep == index ? Color.driftAmber : Color.driftConcrete.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: currentStep == index ? Color.driftAmber.opacity(0.55) : .clear, radius: 8, x: 0, y: 0)
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
                ChippedPad()
                    .fill(Color.black.opacity(0.48))
                ChippedPad()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.35), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: CGFloat(86 * level))
            }
            .frame(width: 12, height: 86)
            .overlay(ChippedPad().stroke(Color.driftMoss.opacity(0.32), lineWidth: 1))

            Circle()
                .fill(
                    RadialGradient(colors: [.driftConcrete, .driftBlack], center: .center, startRadius: 4, endRadius: 24)
                )
                .frame(width: 48, height: 48)
                .overlay(Circle().trim(from: 0.05, to: CGFloat(level)).stroke(color, lineWidth: 4).rotationEffect(.degrees(100)))
                .overlay(Leaf().fill(Color.driftMoss.opacity(0.22)).frame(width: 16, height: 22).offset(x: 14, y: -12))
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
                                .fill(row < 2 ? Color.driftRust : (row < 5 ? Color.driftAmber : Color.driftLeaf))
                                .opacity(row + column < 7 ? 0.95 : 0.2)
                                .frame(width: 8, height: 6)
                        }
                    }
                }
            }

            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.driftLeaf)
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
                            colors: [Color.driftConcrete.opacity(0.72), Color.driftCanopy.opacity(0.42), Color.black.opacity(0.34)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(alignment: .topLeading) {
                HStack(spacing: 4) {
                    ForEach(0..<6, id: \.self) { index in
                        Capsule()
                            .fill(index % 2 == 0 ? Color.driftMoss.opacity(0.42) : Color.driftLeaf.opacity(0.34))
                            .frame(width: CGFloat(index + 6), height: CGFloat((index * 3) % 12 + 8))
                    }
                }
                .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.driftBone.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.driftRust.opacity(0.28), lineWidth: 1)
                    .padding(2)
            )
            .shadow(color: .black.opacity(0.56), radius: 14, x: 0, y: 12)
    }
}

private struct StatusPill: View {
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isPlaying ? Color.driftRust : Color.driftMoss.opacity(0.6))
                .frame(width: 8, height: 8)
                .shadow(color: isPlaying ? Color.driftRust.opacity(0.75) : .clear, radius: 7, x: 0, y: 0)

            Text(isPlaying ? "PLAYING" : "READY")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(1.2)
        }
        .foregroundColor(isPlaying ? .driftRust : .driftBone.opacity(0.5))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.driftCanopy.opacity(0.62))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.driftMoss.opacity(0.28), lineWidth: 1))
    }
}

private struct Equalizer: View {
    let isPlaying: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<28, id: \.self) { index in
                EqualizerBar(index: index, isPlaying: isPlaying)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36, alignment: .bottomLeading)
        .padding(10)
        .background(Color.driftCanopy.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.driftMoss.opacity(0.22), lineWidth: 1))
    }
}

private struct EqualizerBar: View {
    let index: Int
    let isPlaying: Bool

    private var barColor: Color {
        index % 5 == 0 ? .driftAmber : .driftLeaf
    }

    private var barHeight: CGFloat {
        let height = isPlaying ? ((index * 9) % 28 + 8) : ((index * 5) % 15 + 5)
        return CGFloat(height)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor)
            .frame(width: 5, height: barHeight)
            .opacity(isPlaying ? 0.95 : 0.3)
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
        .padding(10)
        .background(Color.driftCanopy.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.driftMoss.opacity(0.2), lineWidth: 1))
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
                .foregroundColor(isSelected ? .driftBlack : .driftBone.opacity(0.68))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(StyleButtonBackground(isSelected: isSelected))
                .overlay(
                    ChippedPad()
                        .stroke(isSelected ? Color.driftBone.opacity(0.36) : Color.driftMoss.opacity(0.26), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: isSelected ? Color.driftAmber.opacity(0.24) : .clear, radius: 10, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

private struct StyleButtonBackground: View {
    let isSelected: Bool

    private var gradientColors: [Color] {
        if isSelected {
            return [Color.driftAmber, Color.driftLeaf.opacity(0.8)]
        }
        return [Color.driftConcrete.opacity(0.5), Color.driftCanopy.opacity(0.6)]
    }

    var body: some View {
        ZStack {
            ChippedPad()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if isSelected {
                UnevenVine()
                    .stroke(Color.driftMoss.opacity(0.52), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .padding(.horizontal, 10)
            }
        }
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .tracking(1.3)
            }
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(ActionButtonBackground(colors: colors))
                .overlay(
                    ChippedPad()
                        .stroke(Color.driftBone.opacity(0.28), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: colors.first?.opacity(0.26) ?? .clear, radius: 12, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButtonBackground: View {
    let colors: [Color]

    var body: some View {
        ZStack {
            ChippedPad()
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            Rectangle()
                .fill(Color.black.opacity(0.18))
                .frame(height: 7)
                .offset(y: 18)

            UnevenVine()
                .stroke(Color.driftMoss.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .padding(.horizontal, 18)
        }
    }
}

private struct UnevenVine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY + 4),
            control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.maxY)
        )
        return path
    }
}

private extension Color {
    static let driftBlack = Color(red: 0.025, green: 0.028, blue: 0.03)
    static let driftGraphite = Color(red: 0.095, green: 0.105, blue: 0.095)
    static let driftSteel = Color(red: 0.16, green: 0.155, blue: 0.135)
    static let driftConcrete = Color(red: 0.27, green: 0.28, blue: 0.24)
    static let driftCanopy = Color(red: 0.035, green: 0.12, blue: 0.07)
    static let driftMoss = Color(red: 0.22, green: 0.38, blue: 0.16)
    static let driftLeaf = Color(red: 0.47, green: 0.72, blue: 0.31)
    static let driftAmber = Color(red: 0.96, green: 0.68, blue: 0.22)
    static let driftRust = Color(red: 0.72, green: 0.22, blue: 0.13)
    static let driftBone = Color(red: 0.84, green: 0.82, blue: 0.72)
    static let driftTeal = Color(red: 0.34, green: 0.83, blue: 0.78)
    static let driftAcid = Color(red: 0.86, green: 0.9, blue: 0.06)
    static let driftRed = Color(red: 1.0, green: 0.22, blue: 0.16)
}

#Preview {
    ContentView()
}
