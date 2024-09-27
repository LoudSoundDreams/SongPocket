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
			
			state.shuffleMode = .off // Not `.none`; this property is an optional.
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
			guard let _ = try? await queue.insert(toAppend, position: .tail) else { return }
			
			let impactor = UIImpactFeedbackGenerator(style: .heavy)
			impactor.impactOccurred()
			
			guard toAppend.count >= 2 else { return }
			try? await Task.sleep(for: .seconds(0.2))
			
			impactor.impactOccurred()
		}
	}
	
	/*
	 final func shuffleAll() {
	 let mkSongs = Librarian.shared.mkSections.values.compactMap { $0.items }.flatMap { $0 }.shuffled() // Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
	 playNow(mkSongs) // Can get stuck “Loading…” when offline, even when song is downloaded.
	 }
	 */
}

import MediaPlayer
@MainActor extension MPMusicPlayerController {
	static var nowPlayingID: SongID? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return applicationQueuePlayer.nowPlayingItem?.songID
	}
}
