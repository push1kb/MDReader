import MediaPlayer

/// Wires the player to media keys, AirPods and Control Center, and keeps Now Playing up to date.
@MainActor
final class NowPlayingBridge {
    private weak var controller: PlayerController?

    func attach(to controller: PlayerController) {
        self.controller = controller
        let commands = MPRemoteCommandCenter.shared()
        let skip = NSNumber(value: PlayerController.skipInterval)
        commands.skipForwardCommand.preferredIntervals = [skip]
        commands.skipBackwardCommand.preferredIntervals = [skip]

        handle(commands.playCommand) { $0.play() }
        handle(commands.pauseCommand) { $0.pause() }
        handle(commands.togglePlayPauseCommand) { $0.togglePlayPause() }
        handle(commands.stopCommand) { $0.stop() }
        handle(commands.skipForwardCommand) { $0.skip(by: PlayerController.skipInterval) }
        handle(commands.skipBackwardCommand) { $0.skip(by: -PlayerController.skipInterval) }
        handle(commands.nextTrackCommand) { $0.nextParagraph() }
        handle(commands.previousTrackCommand) { $0.previousParagraph() }
        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            return self?.perform { $0.seek(to: event.positionTime) } ?? .noActionableNowPlayingItem
        }
    }

    func update(from controller: PlayerController) {
        let center = MPNowPlayingInfoCenter.default()
        guard controller.hasAudio else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
            return
        }
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: controller.chunks.first.map { String($0.prefix(80)) } ?? "MDReader",
            MPMediaItemPropertyArtist: "MDReader",
            MPMediaItemPropertyPlaybackDuration: controller.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: controller.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: controller.isPlaying ? Double(controller.rate) : 0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]
        center.playbackState = controller.isPlaying ? .playing : .paused
    }

    private func handle(_ command: MPRemoteCommand, _ action: @escaping @MainActor (PlayerController) -> Void) {
        command.addTarget { [weak self] _ in
            self?.perform(action) ?? .noActionableNowPlayingItem
        }
    }

    /// Remote commands are delivered on the main thread.
    private nonisolated func perform(_ action: @MainActor (PlayerController) -> Void) -> MPRemoteCommandHandlerStatus {
        MainActor.assumeIsolated {
            guard let controller else { return .noActionableNowPlayingItem }
            action(controller)
            return .success
        }
    }
}
