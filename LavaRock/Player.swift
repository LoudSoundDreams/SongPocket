// 2022-03-19

@preconcurrency import MusicKit
import MediaPlayer

// We’re using our own observation so we can handle not having access to the player, and respond later when we integrate it.
@MainActor @Observable final class PlayerState {
	private init() {}
	
	var is_playing: Bool { // UIKit views need to manually pull this value …
		let _ = _signal_state // … but this pushes SwiftUI views that mention this property to redraw.
		guard let mp = MPMusicPlayerController._appQueuePlayer else { return false }
		switch mp.playbackState {
			case .playing:
				return true
			case .stopped, .paused, .interrupted, .seekingBackward, .seekingForward:
				fallthrough
			@unknown default:
				return false
		}
	}
	private var _signal_state = false
	
	/*
	 As of iOS 18.3 developer beta 1, a `MusicKit.Song.id` looks like this: i.KoDG5DYT3ZP1NWD
	 But a `queue.currentEntry.id` never matches that, and looks like “pXBAgpg1z::o9WiHejiP”. It changes each time the program runs.
	 `queue.currentEntry.item.id` doesn’t match either: “593338428”. (This stays the same each time the program runs.)
	 Workaround: Each time we set the queue, keep our own records so we can figure out whether this `MusicKit.Song` we’re checking corresponds to `queue.currentEntry.id`.
	 */
	var uSong_current: USong? {
		let _ = _signal_now_playing
		return MPMusicPlayerController._appQueuePlayer?.nowPlayingItem?.persistentID
	}
	private var _signal_now_playing = false
}
extension PlayerState {
	@ObservationIgnored static let shared = PlayerState()
	func watch() {
		guard let mp = MPMusicPlayerController._appQueuePlayer else { return }
		// As of iOS 18.3 RC, MusicKit only emits `objectWillChange` events. That’s only useful when we use both `@ObservedObject` and MusicKit state; otherwise, state won’t yet have changed when we check it. So observe Media Player’s “did change” notifications for these.
		NotificationCenter.default.addObserver_once(self, selector: #selector(mp_state), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: mp)
		NotificationCenter.default.addObserver_once(self, selector: #selector(mp_now_playing), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: mp) // Because we still use Media Player to check the current song.
	}
	@objc private func mp_state() {
		_signal_state.toggle()
		post()
	}
	@objc private func mp_now_playing() {
		_signal_now_playing.toggle()
		post()
	}
	private func post() {
		NotificationCenter.default.post(name: .player_state, object: nil)
	}
}

@MainActor extension MPMusicPlayerController {
	static var _appQueuePlayer: MPMusicPlayerApplicationController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return applicationQueuePlayer
	}
}

@MainActor extension ApplicationMusicPlayer {
	static var is_empty: Bool {
#if targetEnvironment(simulator)
		return false
#else
		return nil == _shared?.queue.currentEntry
#endif
	}
	
	static var _shared: ApplicationMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
}

@MainActor enum Tape {
	private static let player: ApplicationMusicPlayer? = ._shared
	
	static func play_now(
		_ uSs_to_play: [USong],
		starting_at uS_start: USong? = nil
	) async {
		guard let player else { return }
		
		let mk_to_play: [MKSong] = await {
			var result: [MKSong] = []
			for uSong in uSs_to_play {
				guard let mkSong = await AppleCatalog.shared.mkSong_fetched(uSong: uSong) else { continue }
				result.append(mkSong)
			}
			return result
		}()
		let mk_start: MKSong? = await {
			guard let uS_start else { return nil } // MusicKit lets us pass `nil` for `startingAt:`.
			return await AppleCatalog.shared.mkSong_fetched(uSong: uS_start)
		}()
		
		player.queue = ApplicationMusicPlayer.Queue(for: mk_to_play, startingAt: mk_start) // Slow.
		guard let _ = try? await player.play() else { return }
		
		player.state.repeatMode = ApplicationMusicPlayer.RepeatMode.none // Not `.none`; this property is optional. As of iOS 18.1 developer beta 7, do this after calling `play`, not before; otherwise, it might do nothing.
	}
	
	static func play_later(_ uSs_to_append: [USong]) {
		Task {
			guard let player else { return }
			
			let mk_to_append: [MKSong] = await {
				var result: [MKSong] = []
				for uSong in uSs_to_append {
					guard let mkSong = await AppleCatalog.shared.mkSong_fetched(uSong: uSong) else { continue }
					result.append(mkSong)
				}
				return result
			}()
			
			if nil == player.queue.currentEntry {
				player.queue = ApplicationMusicPlayer.Queue(for: mk_to_append)
				guard let _ = try? await player.prepareToPlay() else { return }
			} else {
				guard let _ = try? await player.queue.insert(mk_to_append, position: .tail) else { return }
			}
			
			let rumbler = UINotificationFeedbackGenerator()
			rumbler.notificationOccurred(.success)
		}
	}
	
	static func resume() async {
		try? await player?.play()
	}
	static func pause() {
		player?.pause()
	}
	static func rewind() {
		player?.restartCurrentEntry()
	}
	static func previous() {
		Task {
			try? await player?.skipToPreviousEntry()
		}
	}
	static func next() {
		Task {
			try? await player?.skipToNextEntry()
		}
	}
	static func jump_back_15() {
		player?.playbackTime -= 15
	}
	static func jump_forward_15() {
		player?.playbackTime += 15
	}
}
