// 2022-03-19

@preconcurrency import MusicKit
import MediaPlayer
import SwiftUI
import Combine

@MainActor extension ApplicationMusicPlayer {
	static var _shared: ApplicationMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
	
	static var is_empty: Bool {
#if targetEnvironment(simulator)
		return false
#else
		return _shared?.queue.currentEntry == nil
#endif
	}
	
	final func play_now(
		_ uSongs_to_play: [USong],
		starting_at uSong_start: USong? = nil
	) async {
		let mkSongs_to_play: [MKSong] = await {
			var result: [MKSong] = []
			for uSong in uSongs_to_play {
				guard let mkSong = await AppleLibrary.shared.mkSong_fetched(uSong: uSong) else { continue }
				result.append(mkSong)
			}
			return result
		}()
		let start: MKSong? = await {
			guard let uSong_start else { return nil } // MusicKit lets us pass `nil` for `startingAt:`.
			return await AppleLibrary.shared.mkSong_fetched(uSong: uSong_start)
		}()
		
		queue = Queue(for: mkSongs_to_play, startingAt: start) // Slow.
		guard let _ = try? await play() else { return }
		
		state.repeatMode = RepeatMode.none // Not `.none`; this property is optional. As of iOS 18.1 developer beta 7, do this after calling `play`, not before; otherwise, it might do nothing.
	}
	
	final func play_later(_ uSongs_to_append: [USong]) async {
		let mkSongs_to_append: [MKSong] = await {
			var result: [MKSong] = []
			for uSong in uSongs_to_append {
				guard let mkSong = await AppleLibrary.shared.mkSong_fetched(uSong: uSong) else { continue }
				result.append(mkSong)
			}
			return result
		}()
		
		if queue.currentEntry == nil {
			queue = Queue(for: mkSongs_to_append)
			guard let _ = try? await prepareToPlay() else { return }
		} else {
			guard let _ = try? await queue.insert(mkSongs_to_append, position: .tail) else { return }
		}
		
		let rumbler = UINotificationFeedbackGenerator()
		rumbler.notificationOccurred(.success)
	}
	
	@MainActor enum StatusNowPlaying {
		case not_playing, paused, playing
		init(uSong: USong) {
			guard
				/*
				 As of iOS 18.3 developer beta 1, a `MusicKit.Song.id` looks like this: i.KoDG5DYT3ZP1NWD
				 But a `queue.currentEntry.id` never matches that, and looks like “pXBAgpg1z::o9WiHejiP”. It changes each time the program runs.
				 `queue.currentEntry.item.id` doesn’t match either: “593338428”. (This stays the same each time the program runs.)
				 Workaround: Each time we set the queue, keep our own records so we can figure out whether this `MusicKit.Song` we’re checking corresponds to `queue.currentEntry.id`.
				 */
				uSong == MPMusicPlayerController.uSong_current,
				let state = _shared?.state
			else { self = .not_playing; return }
			switch state.playbackStatus {
				case .playing:
					self = .playing
				case .stopped, .paused, .interrupted, .seekingBackward, .seekingForward:
					self = .paused
				@unknown default:
					self = .paused
			}
		}
		var foreground_color: Color {
			switch self {
				case .not_playing: return Color.primary
				case .playing: return Color.accentColor
				case .paused: return Color.accentColor.opacity(.one_half)
			}
		}
	}
}

@MainActor extension MPMusicPlayerController {
	static var uSong_current: USong? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return applicationQueuePlayer.nowPlayingItem?.persistentID
	}
}

@MainActor @Observable final class PlayerState {
	@ObservationIgnored static let shared = PlayerState()
	var signal = false { didSet { // Value is meaningless; we’re using this to tell SwiftUI to redraw views. As of iOS 18.3 beta 1, setting the property to the same value again doesn’t trigger observers.
		Task { // We’re responding to `objectWillChange` events, which aren’t what we actually want. This might wait for the next turn of the run loop, when the value might actually have changed.
			NotificationCenter.default.post(name: Self.musicKit, object: nil)
		}
	}}
	private init() {}
	@ObservationIgnored private var cancellables: Set<AnyCancellable> = []
}
extension PlayerState {
	func watch() {
		ApplicationMusicPlayer._shared?.state.objectWillChange
			.sink { [weak self] in self?.signal.toggle() }
			.store(in: &cancellables)
		ApplicationMusicPlayer._shared?.queue.objectWillChange
			.sink { [weak self] in self?.signal.toggle() }
			.store(in: &cancellables)
	}
	static let musicKit = Notification.Name("LR_MusicKitPlayerStateOrQueue")
}
