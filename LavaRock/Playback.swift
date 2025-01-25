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
		return nil == _shared?.queue.currentEntry
#endif
	}
	
	final func play_now(
		_ uSongs_to_play: [USong],
		starting_at uSong_start: USong? = nil
	) async {
		let mkSongs_to_play: [MKSong] = await {
			var result: [MKSong] = []
			for uSong in uSongs_to_play {
				guard let mkSong = await AppleCatalog.shared.mkSong_fetched(uSong: uSong) else { continue }
				result.append(mkSong)
			}
			return result
		}()
		let start: MKSong? = await {
			guard let uSong_start else { return nil } // MusicKit lets us pass `nil` for `startingAt:`.
			return await AppleCatalog.shared.mkSong_fetched(uSong: uSong_start)
		}()
		
		queue = Queue(for: mkSongs_to_play, startingAt: start) // Slow.
		guard let _ = try? await play() else { return }
		
		state.repeatMode = RepeatMode.none // Not `.none`; this property is optional. As of iOS 18.1 developer beta 7, do this after calling `play`, not before; otherwise, it might do nothing.
	}
	
	final func play_later(_ uSongs_to_append: [USong]) async {
		let mkSongs_to_append: [MKSong] = await {
			var result: [MKSong] = []
			for uSong in uSongs_to_append {
				guard let mkSong = await AppleCatalog.shared.mkSong_fetched(uSong: uSong) else { continue }
				result.append(mkSong)
			}
			return result
		}()
		
		if nil == queue.currentEntry {
			queue = Queue(for: mkSongs_to_append)
			guard let _ = try? await prepareToPlay() else { return }
		} else {
			guard let _ = try? await queue.insert(mkSongs_to_append, position: .tail) else { return }
		}
		
		let rumbler = UINotificationFeedbackGenerator()
		rumbler.notificationOccurred(.success)
	}
	
	/*
	 As of iOS 18.3 developer beta 1, a `MusicKit.Song.id` looks like this: i.KoDG5DYT3ZP1NWD
	 But a `queue.currentEntry.id` never matches that, and looks like “pXBAgpg1z::o9WiHejiP”. It changes each time the program runs.
	 `queue.currentEntry.item.id` doesn’t match either: “593338428”. (This stays the same each time the program runs.)
	 Workaround: Each time we set the queue, keep our own records so we can figure out whether this `MusicKit.Song` we’re checking corresponds to `queue.currentEntry.id`.
	 */
	@MainActor static var uSong_current: USong? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return MPMusicPlayerController.applicationQueuePlayer.nowPlayingItem?.persistentID
	}
}

// We’re using our own observation so we can handle not having access to the player, and respond later when we integrate it.
@MainActor @Observable final class PlayerState {
	private init() {}
	private(set) var signal = false { didSet {
		NotificationCenter.default.post(name: Self.changed, object: nil)
	}}
	@ObservationIgnored private var cancellables: Set<AnyCancellable> = []
}
extension PlayerState {
	@ObservationIgnored static let shared = PlayerState()
	func watch() {
		ApplicationMusicPlayer.shared.state.objectWillChange
			.sink { [weak self] in self?.signal.toggle() }
			.store(in: &cancellables)
		
		// As of iOS 18.3 RC, MusicKit only emits `objectWillChange` events. That’s only useful when we use both `@ObservedObject` and MusicKit state; otherwise, state won’t yet have changed when we check it. So observe Media Player’s “did change” notifications for these.
		let player = MPMusicPlayerController.applicationQueuePlayer
		NotificationCenter.default.addObserver(self, selector: #selector(mp_now_playing), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player) // Because we still use Media Player to check the current song.
		NotificationCenter.default.addObserver(self, selector: #selector(mp_state), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player) // Because we still use UIKit to indicate the repeat mode.
	}
	@objc private func mp_now_playing() {
		signal.toggle()
	}
	@objc private func mp_state() {
		signal.toggle()
	}
	@ObservationIgnored static let changed = Notification.Name("LR_PlayerState")
}
