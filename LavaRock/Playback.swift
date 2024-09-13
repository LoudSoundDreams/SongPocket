// 2022-03-19

@preconcurrency import MusicKit

@MainActor extension SystemMusicPlayer {
	static var _shared: SystemMusicPlayer? {
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
	
	final func playNow<ToPlay: PlayableMusicItem>(_ playables: [ToPlay], startingAt: ToPlay? = nil) {
		let oldRepeatMode: RepeatMode? = state.repeatMode
		queue = Queue(for: playables, startingAt: startingAt) // Slow.
		Task {
			guard let _ = try? await play() else { return }
			
			state.shuffleMode = .off // Not `.none`; this property is an optional.
			state.repeatMode = oldRepeatMode
		}
	}
	
	final func playLater(_ playables: [some PlayableMusicItem], actuallyNextNotLater: Bool) {
		Task {
			let position: SystemMusicPlayer.Queue.EntryInsertionPosition = actuallyNextNotLater
			? .afterCurrentEntry
			: .tail // As of iOS 18 RC, this always fails, printing: appendQueueDescriptor failed error=<MPMusicPlayerControllerErrorDomain.6 "Failed to prepare queue for append" {}>
			guard let _ = try? await queue.insert(playables, position: position) else { return }
			
			let impactor = UIImpactFeedbackGenerator(style: .heavy)
			impactor.impactOccurred()
			
			guard playables.count >= 2 else { return }
			try? await Task.sleep(for: .seconds(0.2))
			
			impactor.impactOccurred()
		}
	}
	
	final func shuffleAll() {
		let mkSongs = Librarian.shared.mkSections.values.compactMap { $0.items }.flatMap { $0 }.shuffled() // Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
		playNow(mkSongs) // Can get stuck “Loading…” when offline, even when song is downloaded.
	}
	final func shuffleNow(_ albumID: AlbumID) {
		guard let mkSongs = Librarian.shared.mkSection(albumID: albumID)?.items else { return }
		playNow(mkSongs.shuffled())
	}
}

import MediaPlayer
@MainActor extension MPMusicPlayerController {
	static var _system: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return .systemMusicPlayer
	}
	
	static var nowPlayingID: SongID? {
		return _system?.nowPlayingItem?.songID
	}
}
