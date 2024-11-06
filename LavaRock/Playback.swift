// 2022-03-19

import MusicKit

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
	
	final func play_now(_ ids_to_play: [MPIDSong], starting_at id_start: MPIDSong? = nil) {
		Task {
			let to_play: [MKSong] = await {
				var result: [MKSong] = []
				for mpID in ids_to_play {
					guard let mkSong = await Librarian.shared.mkSong_fetched(mpidSong: mpID) else { continue }
					result.append(mkSong)
				}
				return result
			}()
			let start: MKSong? = await {
				guard let id_start else { return nil } // MusicKit lets us pass `nil` for `startingAt:`.
				return await Librarian.shared.mkSong_fetched(mpidSong: id_start)
			}()
			
			queue = Queue(for: to_play, startingAt: start) // Slow.
			guard let _ = try? await play() else { return }
			
			state.repeatMode = RepeatMode.none // Not `.none`; this property is optional. As of iOS 18.1 developer beta 7, do this after calling `play`, not before; otherwise, it might do nothing.
		}
	}
	
	final func play_later(_ ids_to_append: [MPIDSong]) {
		Task {
			let to_append: [MKSong] = await {
				var result: [MKSong] = []
				for mpID in ids_to_append {
					guard let mkSong = await Librarian.shared.mkSong_fetched(mpidSong: mpID) else { continue }
					result.append(mkSong)
				}
				return result
			}()
			
			if queue.currentEntry == nil {
				queue = Queue(for: to_append)
				guard let _ = try? await prepareToPlay() else { return }
			} else {
				guard let _ = try? await queue.insert(to_append, position: .tail) else { return }
			}
			
			let rumbler = UINotificationFeedbackGenerator()
			rumbler.notificationOccurred(.success)
		}
	}
}

import MediaPlayer
@MainActor extension MPMusicPlayerController {
	static var mpidSong_current: MPIDSong? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return applicationQueuePlayer.nowPlayingItem?.id_song
	}
}
