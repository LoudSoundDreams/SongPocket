// 2022-03-19

import MusicKit

@MainActor extension ApplicationMusicPlayer {
	static var _shared: ApplicationMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
	
	static var isEmpty: Bool {
#if targetEnvironment(simulator)
		return false
#else
		return _shared?.queue.currentEntry == nil
#endif
	}
	
	final func playNow(_ idsToPlay: [SongID], startingAt idStart: SongID? = nil) {
		Task {
			let toPlay: [MKSong] = await {
				var result: [MKSong] = []
				for mpID in idsToPlay {
					guard let mkSong = await Librarian.shared.mkSong_fetched(mpID: mpID) else { continue }
					result.append(mkSong)
				}
				return result
			}()
			let start: MKSong? = await {
				guard let idStart else { return nil } // MusicKit lets us pass `nil` for `startingAt:`.
				return await Librarian.shared.mkSong_fetched(mpID: idStart)
			}()
			
			let oldRepeatMode: RepeatMode? = state.repeatMode
			queue = Queue(for: toPlay, startingAt: start) // Slow.
			guard let _ = try? await play() else { return }
			
			state.repeatMode = oldRepeatMode
		}
	}
	
	final func playLater(_ idsToAppend: [SongID]) {
		Task {
			let toAppend: [MKSong] = await {
				var result: [MKSong] = []
				for mpID in idsToAppend {
					guard let mkSong = await Librarian.shared.mkSong_fetched(mpID: mpID) else { continue }
					result.append(mkSong)
				}
				return result
			}()
			
			if queue.currentEntry == nil {
				queue = Queue(for: toAppend)
				guard let _ = try? await prepareToPlay() else { return }
			} else {
				guard let _ = try? await queue.insert(toAppend, position: .tail) else { return }
			}
			
			let rumbler = UINotificationFeedbackGenerator()
			rumbler.notificationOccurred(.success)
		}
	}
}

import MediaPlayer
@MainActor extension MPMusicPlayerController {
	static var idSongCurrent: SongID? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return applicationQueuePlayer.nowPlayingItem?.songID
	}
}
