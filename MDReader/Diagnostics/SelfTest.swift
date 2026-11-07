import AppKit
import AVFoundation

/// `MDReader --selftest [export.m4a]` reads the clipboard and drives the player the way the
/// buttons do, printing PASS/FAIL for each step, then quits. It plays audio out loud.
@MainActor
enum SelfTest {
    static var isRequested: Bool { CommandLine.arguments.contains("--selftest") }

    static func run(_ player: PlayerController) {
        setvbuf(stdout, nil, _IONBF, 0)
        Task {
            var test = Checklist()
            await exercisePlayback(player, &test)
            await exerciseExport(player, &test)
            await exerciseVoicePreviews(player.voicePreview, &test)
            print(test.failures == 0 ? "SELFTEST OK" : "SELFTEST FAILED (\(test.failures))")
            exit(test.failures == 0 ? 0 : 1)
        }
    }

    private static func exercisePlayback(_ player: PlayerController, _ test: inout Checklist) async {
        player.rate = 1
        player.text = NSPasteboard.general.string(forType: .string) ?? ""

        let started = Date()
        player.play()
        await wait(upTo: 900) { player.isPlaying || player.phase.isFailure }
        test.check(player.isPlaying, "playing after \(seconds(since: started))")
        for (index, chunk) in player.chunks.enumerated() {
            print(String(format: "  [%2d @ %6.2fs] %@", index, player.chunkStarts[index], chunk))
        }

        await sleep(3)
        let a = player.currentTime
        test.check(2.5...3.6 ~= a, "advances in real time: \(time(a)) after 3s")

        player.skip(by: 10)
        test.check(abs(player.currentTime - (a + 10)) < 0.3, "+10s: \(time(a)) → \(time(player.currentTime))")
        await sleep(1)
        let b = player.currentTime
        player.skip(by: -10)
        test.check(abs(player.currentTime - (b - 10)) < 0.3, "−10s: \(time(b)) → \(time(player.currentTime))")
        player.skip(by: -100)
        test.check(player.currentTime == 0, "−10s stops at 0")

        player.nextParagraph()
        test.check(player.currentChunkIndex == 1, "next paragraph → 1")
        player.nextParagraph()
        player.previousParagraph()
        test.check(player.currentChunkIndex == 1, "previous paragraph → 1")

        player.rate = 2.5
        let c = player.currentTime
        await sleep(2)
        test.check(4.2...5.6 ~= player.currentTime - c, "2.5×: \(time(player.currentTime - c)) of audio in 2s")
        player.adjustRate(by: -PlayerController.speedStep)
        test.check(player.rate == 2.25, "speed step → \(player.rate)×")
        player.rate = 1

        player.pause()
        let paused = player.currentTime
        await sleep(1)
        test.check(!player.isPlaying && player.currentTime == paused, "pause holds \(time(paused))")
        player.play()
        test.check(player.isPlaying && abs(player.currentTime - paused) < 0.2, "resumes from cache")

        player.seek(to: player.duration - 1)
        await sleep(1.6)
        test.check(!player.isPlaying && player.currentTime == player.duration, "stops at the end")
        player.play()
        await sleep(0.3)
        test.check(player.isPlaying && player.currentTime < 1, "play after the end restarts")
        player.stop()
        test.check(!player.isPlaying && player.currentTime == 0, "stop rewinds")
    }

    private static func exerciseExport(_ player: PlayerController, _ test: inout Checklist) async {
        let path = CommandLine.arguments.drop { $0 != "--selftest" }.dropFirst().first
            ?? NSTemporaryDirectory() + "mdreader-selftest.m4a"
        do {
            try await player.exportAudio(to: URL(filePath: path))
            let file = try AVAudioFile(forReading: URL(filePath: path))
            let length = Double(file.length) / file.fileFormat.sampleRate
            test.check(abs(length - player.duration) < 0.5, "export \(time(length)) → \(path)")
        } catch {
            test.check(false, "export: \(error.localizedDescription)")
        }
    }

    private static func exerciseVoicePreviews(_ previewer: VoicePreviewer, _ test: inout Checklist) async {
        for voice in ["bf_emma", "ef_dora"] {
            let started = Date()
            previewer.play(voice)
            await wait(upTo: 120) { previewer.state == .playing || previewer.state.isFailure }
            await wait(upTo: 30) { previewer.state != .playing }
            test.check(previewer.state == .idle, "voice sample \(voice) after \(seconds(since: started))")
        }
    }

    // MARK: Helpers

    private struct Checklist {
        let started = Date()
        var failures = 0

        mutating func check(_ passed: Bool, _ label: String) {
            print(String(format: "[%6.2f]", Date().timeIntervalSince(started)), passed ? "PASS" : "FAIL", label)
            if !passed { failures += 1 }
        }
    }

    private static func wait(upTo timeout: TimeInterval, until condition: () -> Bool) async {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while !condition(), Date() < deadline {
            await sleep(0.05)
        }
    }

    private static func sleep(_ seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private static func time(_ seconds: TimeInterval) -> String { String(format: "%.2fs", seconds) }

    private static func seconds(since date: Date) -> String { time(Date().timeIntervalSince(date)) }
}

private extension PlayerController.Phase {
    var isFailure: Bool { if case .failed = self { true } else { false } }
}

private extension VoicePreviewer.State {
    var isFailure: Bool { if case .failed = self { true } else { false } }
}
