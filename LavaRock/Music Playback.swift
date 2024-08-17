// 2022-03-19

@preconcurrency import MusicKit
import os

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
		state.shuffleMode = .none // As of iOS 17.6 developer beta 3, you must do this before setting `queue`, not after. Otherwise, if you happen to set the queue with the same contents, this does nothing.
		state.repeatMode = RepeatMode.none // As of iOS 17.6 developer beta 3, this line of code sometimes does nothing; I haven’t figured out the exact conditions. It’s more reliable if we run it before setting `queue`, not after.
		queue = Queue(for: playables, startingAt: startingAt) // Slow.
		Task { try? await play() }
	}
	
	final func playLater(_ playables: [some PlayableMusicItem]) {
		Task {
			try? await queue.insert(playables, position: .tail)
			
			let impactor = UIImpactFeedbackGenerator(style: .heavy)
			impactor.impactOccurred()
			
			guard playables.count >= 2 else { return }
			try? await Task.sleep(for: .seconds(0.2))
			
			impactor.impactOccurred()
		}
	}
	
	final func shuffleAll() {
		let tracks = Crate.shared.mkSections.values.compactMap { $0.tracks }.flatMap { $0 }.shuffled() // Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
		playNow(tracks) // Can get stuck “Loading…” when offline, even when song is downloaded.
	}
	final func shuffleNow(_ albumID: AlbumID) {
		guard let tracks = Crate.shared.mkSection(albumID: albumID)?.tracks else { return }
		playNow(tracks.shuffled())
	}
}

import MediaPlayer
extension MPMusicPlayerController {
	static var _system: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return .systemMusicPlayer
	}
}

@MainActor extension Song {
	final func playAlbumStartingHere() async {
		guard
			let player = SystemMusicPlayer._shared,
			let rowItem = await musicKitSong(),
			let songsInAlbum = container?.songs(sorted: true)
		else { return }
		let mkSongs: [MusicKit.Song] = await {
			var result: [MusicKit.Song] = []
			for song in songsInAlbum {
				guard let musicItem = await song.musicKitSong() else { continue }
				result.append(musicItem)
			}
			return result
		}()
		
		player.playNow(mkSongs, startingAt: rowItem)
	}
	final func playRestOfAlbumLater() async {
		guard
			let player = SystemMusicPlayer._shared,
			let rowItem = await musicKitSong(),
			let songsInAlbum = container?.songs(sorted: true)
		else { return }
		let toAppend: [MusicKit.Song] = await {
			var mkSongs: [MusicKit.Song] = []
			for song in songsInAlbum {
				guard let musicItem = await song.musicKitSong() else { continue }
				musicItems.append(musicItem)
			}
			let result = mkSongs.drop(while: { $0.id != rowItem.id })
			return Array(result)
		}()
		
		player.playLater(toAppend)
	}
	
	final func musicKitSong() async -> MusicKit.Song? { // Slow; 11ms in 2024.
		var request = MusicLibraryRequest<MusicKit.Song>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(persistentID)))
		guard
			let response = try? await request.response(),
			response.items.count == 1
		else { return nil }
		return response.items.first
	}
}
