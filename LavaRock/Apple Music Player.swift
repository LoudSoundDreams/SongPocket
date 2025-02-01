// 2022-03-19

@preconcurrency import MusicKit
import MediaPlayer

@MainActor extension ApplicationMusicPlayer {
	fileprivate static var _shared: ApplicationMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
}

// For clarity, separating “player” functionality into reading state in `LCD` and controlling playback in `Tape`.

// We’re using our own observation so we can handle not having authorization for the player, and respond later when we integrate it.
@MainActor @Observable final class LCD {
	private init() {}
	
	var is_playing: Bool { // UIKit views need to manually pull this value …
		let _ = _signal_state // … but this pushes SwiftUI views that mention this property to redraw.
		guard let mpPlayer else { return false }
		switch mpPlayer.playbackState {
			case .playing: return true
			case .stopped, .paused, .interrupted, .seekingBackward, .seekingForward: return false
			@unknown default: return false
		}
	}
	var repeat_is_on: Bool {
		let _ = _signal_state
		guard let mpPlayer else { return false }
		switch mpPlayer.repeatMode {
			case .one: return true
			case .default, .none, .all: return false
			@unknown default: return false
		}
	}
	private var _signal_state = 0
	
	var is_blank: Bool {
		let _ = _signal_now_playing
		return nil == uSong_current
	}
	/*
	 As of iOS 18.3 developer beta 1, a `MusicKit.Song.id` looks like this: i.KoDG5DYT3ZP1NWD
	 But a `queue.currentEntry.id` never matches that, and looks like “pXBAgpg1z::o9WiHejiP”. It changes each time the program runs.
	 `queue.currentEntry.item.id` doesn’t match either: “593338428”. (This stays the same each time the program runs.)
	 Workaround: Each time we set the queue, keep our own records so we can figure out whether this `MusicKit.Song` we’re checking corresponds to `queue.currentEntry.id`.
	 */
	var uSong_current: USong? {
		let _ = _signal_now_playing
		return mpPlayer?.nowPlayingItem?.persistentID
	}
	private var _signal_now_playing = 0
}
extension LCD {
	@ObservationIgnored static let shared = LCD()
	private var mpPlayer: MPMusicPlayerApplicationController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return MPMusicPlayerController.applicationQueuePlayer
	}
	func watch() {
		guard let mpPlayer else { return }
		// As of iOS 18.3 RC, MusicKit only emits `objectWillChange` events. That’s only useful when we use both `@ObservedObject` and MusicKit state; otherwise, state won’t yet have changed when we check it. So observe Media Player’s “did change” notifications for these.
		NotificationCenter.default.addObserver_once(self, selector: #selector(mp_state), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: mpPlayer)
		NotificationCenter.default.addObserver_once(self, selector: #selector(mp_now_playing), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: mpPlayer) // As of iOS 18.3 RC, Media Player posts this when we delete the current song, even though `MPMusicPlayerController.nowPlayingItem` still returns the same value.
	}
	@objc private func mp_state() {
		_signal_state += 1
	}
	@objc private func mp_now_playing() {
		_signal_now_playing += 1
	}
}

// 2do: Magic Tap
// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor enum Tape {
	private static var mkPlayer: ApplicationMusicPlayer? {
		ApplicationMusicPlayer._shared
	}
	
	static func play_now(
		_ uSs_to_play: [USong],
		starting_at uS_start: USong? = nil
	) async {
		guard let mkPlayer else { return }
		
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
		
		mkPlayer.queue = ApplicationMusicPlayer.Queue(for: mk_to_play, startingAt: mk_start) // Slow.
		guard let _ = try? await mkPlayer.play() else { return }
		
		repeat_off() // As of iOS 18.1 developer beta 7, do this after calling `play`, not before; otherwise, it might do nothing.
	}
	
	static func play_later(_ uSs_to_append: [USong]) {
		Task {
			guard let mkPlayer else { return }
			
			let mk_to_append: [MKSong] = await {
				var result: [MKSong] = []
				for uSong in uSs_to_append {
					guard let mkSong = await AppleCatalog.shared.mkSong_fetched(uSong: uSong) else { continue }
					result.append(mkSong)
				}
				return result
			}()
			
			if nil == mkPlayer.queue.currentEntry {
				mkPlayer.queue = ApplicationMusicPlayer.Queue(for: mk_to_append)
				guard let _ = try? await mkPlayer.prepareToPlay() else { return }
			} else {
				guard let _ = try? await mkPlayer.queue.insert(mk_to_append, position: .tail) else { return }
			}
			
			let rumbler = UINotificationFeedbackGenerator()
			rumbler.notificationOccurred(.success)
		}
	}
	
	static func resume() async {
		try? await mkPlayer?.play()
	}
	static func pause() {
		mkPlayer?.pause()
	}
	static func rewind() {
		mkPlayer?.restartCurrentEntry()
	}
	static func previous() {
		Task {
			try? await mkPlayer?.skipToPreviousEntry()
		}
	}
	static func next() {
		Task {
			try? await mkPlayer?.skipToNextEntry()
		}
	}
	static func jump_back_15() {
		mkPlayer?.playbackTime -= 15
	}
	static func jump_forward_15() {
		mkPlayer?.playbackTime += 15
	}
	static func repeat_off() {
		mkPlayer?.state.repeatMode = ApplicationMusicPlayer.RepeatMode.none // Not simply `.none`; this property is optional.
	}
	static func repeat_1() {
		mkPlayer?.state.repeatMode = .one
	}
}
