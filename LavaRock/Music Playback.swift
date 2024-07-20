// 2022-03-19

@preconcurrency import MusicKit

extension SystemMusicPlayer {
	@MainActor static var _shared: SystemMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
	
	@MainActor static var isEmpty: Bool {
#if targetEnvironment(simulator)
		return false
#else
		return _shared?.queue.currentEntry == nil
#endif
	}
	
	final func playNow<ToPlay>(
		_ musicKitSongs: [ToPlay],
		startingAt: ToPlay? = nil
	) where ToPlay: PlayableMusicItem {
		state.shuffleMode = .none // As of iOS 17.6 developer beta 3, you must do this before setting `queue`, not after. Otherwise, if you happen to set the queue with the same contents, this does nothing.
		state.repeatMode = RepeatMode.none // As of iOS 17.6 developer beta 3, this line of code sometimes does nothing; I haven’t figured out the exact conditions. It’s more reliably if we run it before setting `queue`, not after.
		queue = Queue(for: musicKitSongs, startingAt: startingAt)
		Task { try? await play() }
	}
	@MainActor final func shuffleAll() {
		let musicKitSongs = Crate.shared.musicKitSections.values.flatMap { $0.items }.shuffled() // Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
		playNow(musicKitSongs) // TO DO: Can get stuck “Loading…” when offline, even when song is downloaded.
	}
	@MainActor final func shuffleNow(_ albumID: AlbumID) {
		guard let musicKitSection = Crate.shared.musicKitSection(albumID) else { return }
		playNow(musicKitSection.items.shuffled())
	}
}

import MediaPlayer
extension MPMusicPlayerController {
	static var _system: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return .systemMusicPlayer
	}
}

extension Song {
	@MainActor final func playAlbumStartingHere() async {
		guard
			let player = SystemMusicPlayer._shared,
			let rowItem = await musicKitSong(),
			let songsInAlbum = container?.songs(sorted: true)
		else { return }
		let musicItems: [MusicKit.Song] = await {
			var result: [MusicKit.Song] = []
			for song in songsInAlbum {
				guard let musicItem = await song.musicKitSong() else { continue }
				result.append(musicItem)
			}
			return result
		}()
		
		player.playNow(musicItems, startingAt: rowItem)
	}
	@MainActor final func playLater() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		guard let _ =
				try? await player.queue.insert([musicItem], position: .tail)
		else { return }
		
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
	}
	@MainActor final func playRestOfAlbumLater() async {
		guard
			let player = SystemMusicPlayer._shared,
			let rowItem = await musicKitSong(),
			let songsInAlbum = container?.songs(sorted: true)
		else { return }
		let toAppend: [MusicKit.Song] = await {
			var musicItems: [MusicKit.Song] = []
			for song in songsInAlbum {
				guard let musicItem = await song.musicKitSong() else { continue }
				musicItems.append(musicItem)
			}
			let result = musicItems.drop(while: { $0.id != rowItem.id })
			return Array(result)
		}()
		
		guard let _ =
				try? await player.queue.insert(toAppend, position: .tail)
		else { return }
		
		let impactor = UIImpactFeedbackGenerator(style: .heavy)
		impactor.impactOccurred()
		try? await Task.sleep(nanoseconds: 0_200_000_000)
		
		impactor.impactOccurred()
	}
	
	@MainActor final func musicKitSong() async -> MusicKit.Song? {
		var request = MusicLibraryRequest<MusicKit.Song>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(persistentID)))
		guard
			let response = try? await request.response(),
			response.items.count == 1
		else { return nil }
		return response.items.first
	}
}
