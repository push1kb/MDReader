import AVFoundation

/// Plays an `AudioClip` through AVAudioEngine: source node → time-pitch → mixer.
///
/// The clip lives in memory and a render callback copies samples from a play position, so seek,
/// pause and resume only move that position. Two Core Audio problems shaped this:
/// AVAudioPlayerNode's stop–schedule–play cycle stalls and throws "player did not see an IO cycle"
/// after a speed change, and AVAudioPlayer can't go above 2×.
@MainActor
final class AudioPlayback {
    var onFinish: () -> Void = {}

    var rate: Float = 1 {
        didSet { if rate != oldValue { replaceTimePitch() } }
    }

    var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = newValue }
    }

    var isPlaying: Bool { state.isPlaying }
    var duration: TimeInterval { Double(state.length) / sampleRate }
    var currentTime: TimeInterval { Double(state.position) / sampleRate }

    private let engine = AVAudioEngine()
    private let state = RenderState()
    private var source: AVAudioSourceNode?
    private var timePitch = AVAudioUnitTimePitch()
    private var sampleRate: Double = 24_000
    private var endWatcher: Task<Void, Never>?
    private var configurationObserver: NSObjectProtocol?

    init() {
        engine.attach(timePitch)
        // An output-device change (e.g. headphones) stops the engine; carry on if we were playing.
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state.isPlaying else { return }
                try? self.engine.start()
            }
        }
    }

    func load(_ clip: AudioClip) {
        unload()
        state.load(clip.samples)
        sampleRate = clip.sampleRate

        let state = self.state
        let source = AVAudioSourceNode(format: Self.format(sampleRate)) { _, _, frameCount, buffers in
            state.render(frameCount: Int(frameCount), into: buffers)
        }
        engine.attach(source)
        self.source = source
        connect()
        engine.prepare()
    }

    func unload() {
        pause()
        if let source { engine.detach(source) }
        source = nil
        state.unload()
    }

    func play() throws {
        guard source != nil, state.length > 0 else { return }
        if state.position >= state.length { state.position = 0 }
        if !engine.isRunning { try engine.start() }
        state.isPlaying = true
        watchForEnd()
    }

    func pause() {
        state.isPlaying = false
        endWatcher?.cancel()
        engine.pause()
    }

    func stop() {
        pause()
        state.position = 0
        timePitch.reset()
    }

    func seek(to time: TimeInterval) {
        state.position = Int(time * sampleRate).clamped(to: 0...state.length)
    }

    // MARK: Graph

    private static func format(_ sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    private func connect() {
        guard let source else { return }
        let format = Self.format(sampleRate)
        engine.disconnectNodeOutput(timePitch)
        engine.connect(source, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
    }

    /// Swaps in a new time-pitch unit for each rate. Changing `rate` on a running
    /// AVAudioUnitTimePitch intermittently makes it stop pulling input, which freezes playback.
    private func replaceTimePitch() {
        let wasRunning = engine.isRunning
        engine.pause()
        engine.detach(timePitch)
        timePitch = AVAudioUnitTimePitch()
        timePitch.rate = rate
        engine.attach(timePitch)
        connect()
        if wasRunning { try? engine.start() }
    }

    /// The render thread can't call into the main actor, so poll for the end of the clip.
    private func watchForEnd() {
        endWatcher?.cancel()
        endWatcher = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard let self else { return }
                guard self.state.didFinish else { continue }
                self.state.didFinish = false
                self.engine.pause()
                self.onFinish()
                return
            }
        }
    }
}
