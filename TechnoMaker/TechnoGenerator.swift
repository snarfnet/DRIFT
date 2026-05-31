import Foundation
import AVFoundation

class TechnoGenerator: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var tempo: Double = 120  // ディープテクノ向けにデフォルト遅めに
    @Published var intensity: Double = 0.5  // 0=minimal, 1=industrial
    @Published var key: Int = 0  // C, C#, D, etc
    @Published var isPlaying = false
    @Published var currentStep: Int?
    @Published var generatedPattern: TechnoPattern?
    @Published var style: TechnoStyle = .drift  // スタイル選択

    private var engine: AVAudioEngine?
    private var mixer: AVAudioMixerNode?
    private var reverbUnit: AVAudioUnitReverb?
    private var interruptionObserver: NSObjectProtocol?
    private var playbackTimer: Timer?
    private var stepIndex = 0
    private let keys = [261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440.00, 466.16, 493.88]
    private var activePlayers: [AVAudioPlayer] = []

    // オシレーター状態
    private var phase: Float = 0
    private var drumGains: [Float] = [0, 0, 0]
    private var drumEnvelopes: [(startTime: Date, duration: Double)] = []

    override init() {
        super.init()
    }

    private func setupAudio() {
        let newEngine = AVAudioEngine()
        engine = newEngine
        mixer = newEngine.mainMixerNode
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("Audio session error: \(error)")
        }

        if interruptionObserver != nil { return }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let typeRaw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
            if type == .ended {
                try? AVAudioSession.sharedInstance().setActive(true, options: [])
                if self.isPlaying, let engine = self.engine, !engine.isRunning {
                    try? engine.start()
                    for node in self.playerPool { node.play() }
                }
            }
        }
    }

    func generateTechno() {
        let baseKey = keys[key]

        // ドラムパターン生成
        let drums = generateDrumPattern()

        // ベースラインを生成
        let bassLine = generateBassLine(key: baseKey)

        // メロディーを生成（スタイルに応じて）
        let melody = intensity > 0.3 ? generateMelody(key: baseKey) : nil

        generatedPattern = TechnoPattern(
            drums: drums,
            bass: bassLine,
            melody: melody,
            tempo: tempo
        )
        currentStep = nil
    }

    private func generateDrumPattern() -> DrumPattern {
        let stepCount = 16

        switch style {
        case .drift:
            // Paucity スタイル：ミニマル、低めのエネルギー
            var kickPattern = [Bool](repeating: false, count: stepCount)
            kickPattern[0] = true      // 最初のビート
            if intensity > 0.3 { kickPattern[8] = true }     // 裏拍
            if intensity > 0.7 { kickPattern[4] = true; kickPattern[12] = true }

            // ハイハット：疎く、サステイン感
            var hihatPattern = [Bool](repeating: false, count: stepCount)
            let hihatStep = Int(8 - intensity * 3)
            for i in stride(from: 0, to: stepCount, by: hihatStep) {
                hihatPattern[i] = true
            }

            // スネア：控えめ
            var snarePattern = [Bool](repeating: false, count: stepCount)
            snarePattern[4] = true
            snarePattern[12] = true

            return DrumPattern(kick: kickPattern, hihat: hihatPattern, snare: snarePattern)

        case .deep:
            // ミニマル：超シンプル
            var kickPattern = [Bool](repeating: false, count: stepCount)
            kickPattern[0] = true
            if intensity > 0.5 { kickPattern[8] = true }

            var hihatPattern = [Bool](repeating: false, count: stepCount)
            hihatPattern[0] = true
            hihatPattern[8] = true

            var snarePattern = [Bool](repeating: false, count: stepCount)
            snarePattern[4] = true
            snarePattern[12] = true

            return DrumPattern(kick: kickPattern, hihat: hihatPattern, snare: snarePattern)

        case .minimal:
            // インダストリアル：複雑で激しい
            var kickPattern = [Bool](repeating: false, count: stepCount)
            for i in stride(from: 0, to: stepCount, by: max(2, Int(4 - intensity * 3))) {
                kickPattern[i] = true
            }

            var hihatPattern = [Bool](repeating: false, count: stepCount)
            for i in 0..<stepCount {
                if i % 2 == 0 { hihatPattern[i] = true }
            }

            var snarePattern = [Bool](repeating: false, count: stepCount)
            for i in stride(from: 2, to: stepCount, by: 4) {
                snarePattern[i] = true
                if intensity > 0.6 { snarePattern[(i + 2) % stepCount] = true }
            }

            return DrumPattern(kick: kickPattern, hihat: hihatPattern, snare: snarePattern)
        }
    }

    private func generateBassLine(key: Double) -> [Double] {
        let stepCount = 16
        var bassLine = [Double]()

        // スケール：C, E, G, A（マイナーペンタトニック相当）
        let scaleOffsets = [0, 3, 7, 9]  // semitones
        let baseFreq = key

        switch style {
        case .drift:
            // Paucity スタイル：長いノート、サブベース強調
            for step in 0..<stepCount {
                let patternPhase = (step / 2) % 4  // 2ステップごとに変える
                let semitoneOffset = scaleOffsets[patternPhase]
                let frequency = baseFreq * pow(2.0, Double(semitoneOffset) / 12.0)
                bassLine.append(frequency * 0.5)  // サブベース（1オクターブ下）
            }

        case .deep:
            // ミニマル：シンプル、ルート音が中心
            for step in 0..<stepCount {
                let patternPhase = (step / 4) % 2
                let semitoneOffset = patternPhase == 0 ? 0 : 7
                let frequency = baseFreq * pow(2.0, Double(semitoneOffset) / 12.0)
                bassLine.append(frequency)
            }

        case .minimal:
            // インダストリアル：複雑で変化が多い
            for step in 0..<stepCount {
                let patternPhase = step % 4
                let semitoneOffset = scaleOffsets[patternPhase]
                let frequency = baseFreq * pow(2.0, Double(semitoneOffset) / 12.0)

                // ステップごとに微細な変化
                if intensity > 0.5 && step % 2 == 1 {
                    bassLine.append(frequency * 1.05)
                } else {
                    bassLine.append(frequency)
                }
            }
        }

        return bassLine
    }

    private func generateMelody(key: Double) -> [Double]? {
        let stepCount = 16
        var melody = [Double]()

        // メロディースケール（より高い音）
        let scaleOffsets = [12, 15, 19, 21]  // 1オクターブ上
        let baseFreq = key

        switch style {
        case .drift:
            // Paucity スタイル：控えめ、たまに現れる
            if intensity > 0.4 {
                for step in 0..<stepCount {
                    if step % 4 == 0 {  // 4ステップに1回だけ
                        let offset = scaleOffsets[step / 4 % 4]
                        let frequency = baseFreq * pow(2.0, Double(offset) / 12.0)
                        melody.append(frequency)
                    } else {
                        melody.append(0)  // 沈黙
                    }
                }
            } else {
                return nil  // メロディーなし
            }

        case .deep:
            // ミニマル：ほぼメロディーなし
            if intensity > 0.6 {
                for step in 0..<stepCount {
                    if step == 0 || step == 8 {
                        melody.append(baseFreq * pow(2.0, Double(12) / 12.0))
                    } else {
                        melody.append(0)
                    }
                }
            } else {
                return nil
            }

        case .minimal:
            // インダストリアル：頻繁でダイナミック
            for step in 0..<stepCount {
                let patternPhase = (step / 8) % 4
                let semitoneOffset = scaleOffsets[patternPhase]
                let frequency = baseFreq * pow(2.0, Double(semitoneOffset) / 12.0)
                melody.append(frequency)
            }
        }

        return melody.filter { $0 > 0 }.isEmpty ? nil : melody
    }

    func playTechno(onNote: @escaping (Double, String) -> Void) {
        guard let pattern = generatedPattern else { return }

        // 既存の再生を安全に停止
        if isPlaying {
            playbackTimer?.invalidate()
            playbackTimer = nil
        }

        // Ensure audio engine is ready before starting playback
        ensureEngineReady()
        guard isEngineConfigured else { return }

        isPlaying = true
        stepIndex = 0
        currentStep = 0

        let secondsPerStep = (60.0 / tempo) / 4
        playbackTimer = Timer.scheduledTimer(withTimeInterval: secondsPerStep, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let step = self.stepIndex % 16
            self.currentStep = step
            self.stepIndex += 1
            return

            // ドラム
            if pattern.drums.kick[step] {
                self.playKick()
            }
            if pattern.drums.hihat[step] {
                self.playHihat()
            }
            if pattern.drums.snare[step] {
                self.playSnare()
            }

            // ベース
            if step < pattern.bass.count {
                self.playBass(freq: pattern.bass[step])
            }

            // メロディー
            if let melody = pattern.melody, step < melody.count {
                if melody[step] > 0 && step % 2 == 0 {
                    self.playMelody(freq: melody[step])
                }
            }

            self.stepIndex += 1
        }
    }

    func stopTechno() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        stepIndex = 0
        currentStep = nil
        drumEnvelopes.removeAll()
        teardownEngine()
    }

    // マスター音量生成用バッファ
    private var sampleRate = 44100.0
    private var audioBuffer = [Float]()
    private var bufferIndex = 0

    // 再利用可能なプレイヤーノードプール
    private var playerPool: [AVAudioPlayerNode] = []
    private let poolSize = 12
    private var poolIndex = 0
    private var isEngineConfigured = false
    private var outputFormat: AVAudioFormat?

    private func ensureEngineReady() {
        guard !isEngineConfigured else { return }
        configureAudioSession()
        sampleRate = 44100
        isEngineConfigured = true
        return
        setupAudio()
        guard let engine = engine, let mixer = mixer else { return }

        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        let safeSampleRate = hwFormat.sampleRate > 0 ? hwFormat.sampleRate : 44100
        let safeChannels = AVAudioChannelCount(min(max(hwFormat.channelCount, 1), 2))
        guard let safeFormat = AVAudioFormat(
            standardFormatWithSampleRate: safeSampleRate,
            channels: safeChannels
        ) else { return }

        sampleRate = safeFormat.sampleRate
        outputFormat = safeFormat

        // プレイヤーノードをアタッチ＆ミキサーに接続（engine.start() 前に全接続を完了）
        for _ in 0..<poolSize {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: safeFormat)
            playerPool.append(node)
        }

        // 全ノード接続後に prepare → start
        engine.prepare()

        do {
            try engine.start()
            for node in playerPool {
                node.play()
            }
        } catch {
            print("Engine start error: \(error)")
            for node in playerPool {
                if node.engine != nil { engine.detach(node) }
            }
            playerPool.removeAll()
            poolIndex = 0
            return
        }
        isEngineConfigured = true
    }

    private func teardownEngine() {
        for node in playerPool {
            node.stop()
        }
        engine?.stop()
        for node in playerPool {
            if node.engine != nil {
                engine?.detach(node)
            }
        }
        playerPool.removeAll()
        activePlayers.forEach { $0.stop() }
        activePlayers.removeAll()
        poolIndex = 0
        isEngineConfigured = false
        outputFormat = nil
        engine = nil
        mixer = nil
    }

    // 808 キック音生成（スタイル依存）
    private func playKick() {
        let duration: Double
        let startFreq: Double
        let endFreq: Double

        switch style {
        case .drift:
            duration = 0.8      // 長く深い
            startFreq = 180.0
            endFreq = 40.0
        case .deep:
            duration = 0.4
            startFreq = 150.0
            endFreq = 60.0
        case .minimal:
            duration = 0.3
            startFreq = 200.0
            endFreq = 50.0
        }

        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let progress = Float(i) / Float(sampleCount)
            let freq = startFreq - ((startFreq - endFreq) * Double(progress))

            let phase = Float(2.0 * .pi * freq * Double(i) / sampleRate)
            var sample = sin(phase)

            // アタックエンベロープ
            let attack = min(1.0, Float(i) / Float(sampleRate * 0.05))
            let decay = 1.0 - progress

            samples[i] = sample * attack * decay * 0.8
        }

        playAudioSamples(samples)
    }

    // スネア音生成（ノイズ + ピッチ）
    private func playSnare() {
        let duration = 0.2
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        var rng = UInt32(Date().timeIntervalSince1970 * 1000)
        for i in 0..<sampleCount {
            let progress = Float(i) / Float(sampleCount)

            // ホワイトノイズ
            rng = rng &* 1103515245 &+ 12345
            let noise = Float(Int32(rng >> 16) % 32768) / 16384.0 - 1.0

            // ピッチ（200Hz）
            let phase = Float(2.0 * .pi * 200.0 * Double(i) / sampleRate)
            let pitch = sin(phase) * 0.3

            samples[i] = (noise * 0.7 + pitch) * (1.0 - progress) * 0.6
        }

        playAudioSamples(samples)
    }

    // ハイハット音生成（高周波ノイズ）
    private func playHihat() {
        let duration = 0.1
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        var rng = UInt32(Date().timeIntervalSince1970 * 1000)
        for i in 0..<sampleCount {
            let progress = Float(i) / Float(sampleCount)

            // ホワイトノイズ
            rng = rng &* 1103515245 &+ 12345
            let noise = Float(Int32(rng >> 16) % 32768) / 16384.0 - 1.0

            // ハイパス（高周波強調）
            let filtered = abs(noise) > 0.5 ? noise : 0

            samples[i] = filtered * (1.0 - progress) * 0.5
        }

        playAudioSamples(samples)
    }

    // ベース音生成（太いサイン波 + フィルター + スタイル依存）
    private func playBass(freq: Double) {
        let duration: Double
        let decayShape: Float

        switch style {
        case .drift:
            duration = 0.5      // 長めのサステイン
            decayShape = 0.2    // ゆっくり減衰
        case .deep:
            duration = 0.25
            decayShape = 0.4
        case .minimal:
            duration = 0.2
            decayShape = 0.6
        }

        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let progress = Float(i) / Float(sampleCount)
            let phase = Float(2.0 * .pi * freq * Double(i) / sampleRate)

            // サイン波 + サブハーモニック + 3倍音
            var sample = sin(phase)
            sample += sin(phase * 0.5) * 0.4      // サブベース
            sample += sin(phase * 3.0) * 0.15     // 3倍音

            // スタイルに応じた減衰エンベロープ
            let envelope = 1.0 - pow(progress, decayShape)
            samples[i] = sample * envelope * 0.75
        }

        playAudioSamples(samples)
    }

    // メロディー音生成（より高周波）
    private func playMelody(freq: Double) {
        let duration = 0.2
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let progress = Float(i) / Float(sampleCount)
            let phase = Float(2.0 * .pi * freq * Double(i) / sampleRate)

            // 複合波形：サイン + わずかなノイズ
            var sample = sin(phase) * 0.8
            var rng = UInt32(i)
            rng = rng &* 1103515245 &+ 12345
            let noise = Float(Int32(rng >> 16) % 32768) / 16384.0 - 1.0
            sample += noise * 0.1

            samples[i] = sample * (1.0 - progress * 0.2) * 0.6
        }

        playAudioSamples(samples)
    }

    private func playAudioSamples(_ samples: [Float]) {
        guard !samples.isEmpty, isEngineConfigured else { return }
        activePlayers.removeAll { !$0.isPlaying }

        do {
            let player = try AVAudioPlayer(data: wavData(from: samples))
            player.delegate = self
            player.prepareToPlay()
            activePlayers.append(player)
            player.play()
        } catch {
            print("Audio player error: \(error)")
        }
        return

        guard !playerPool.isEmpty, let format = outputFormat else { return }
        guard let engine = engine else { return }

        // Restart engine if it stopped unexpectedly
        if !engine.isRunning {
            do {
                try engine.start()
                for node in playerPool { node.play() }
            } catch {
                return
            }
        }

        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }

        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        for ch in 0..<channelCount {
            for (index, sample) in samples.enumerated() {
                channelData[ch][index] = sample
            }
        }

        let index = poolIndex % poolSize
        guard index < playerPool.count else { return }
        let node = playerPool[index]
        poolIndex += 1
        guard node.engine != nil else { return }
        node.scheduleBuffer(buffer, completionHandler: nil)
    }

    private func wavData(from samples: [Float]) -> Data {
        let clamped = samples.map { Int16(max(-1, min(1, $0)) * Float(Int16.max)) }
        let dataSize = UInt32(clamped.count * 2)
        var data = Data()

        func appendString(_ value: String) {
            data.append(value.data(using: .ascii)!)
        }

        func appendUInt16(_ value: UInt16) {
            var little = value.littleEndian
            data.append(Data(bytes: &little, count: MemoryLayout<UInt16>.size))
        }

        func appendUInt32(_ value: UInt32) {
            var little = value.littleEndian
            data.append(Data(bytes: &little, count: MemoryLayout<UInt32>.size))
        }

        appendString("RIFF")
        appendUInt32(36 + dataSize)
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate) * 2)
        appendUInt16(2)
        appendUInt16(16)
        appendString("data")
        appendUInt32(dataSize)

        for sample in clamped {
            var little = sample.littleEndian
            data.append(Data(bytes: &little, count: MemoryLayout<Int16>.size))
        }

        return data
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        activePlayers.removeAll { $0 === player }
    }
}

enum TechnoStyle {
    case drift          // Paucity のようなスロー系
    case deep           // ディープテクノ
    case minimal        // ミニマルテクノ
}

struct DrumPattern {
    let kick: [Bool]
    let hihat: [Bool]
    let snare: [Bool]
}

struct TechnoPattern {
    let drums: DrumPattern
    let bass: [Double]
    let melody: [Double]?
    let tempo: Double
}
