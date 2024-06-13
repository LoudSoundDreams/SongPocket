// 2020-08-16

import CoreData

extension Song {
	convenience init?(atEndOf album: Album, songID: SongID) {
		guard let context = album.managedObjectContext else { return nil }
		self.init(context: context)
		index = Int64(album.contents?.count ?? 0)
		container = album
		persistentID = songID
	}
	
	// Use `init(atEndOf:songID:)` if possible. It’s faster.
	convenience init?(atBeginningOf album: Album, songID: SongID) {
		guard let context = album.managedObjectContext else { return nil }
		
		album.songs(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = album
		persistentID = songID
	}
	
	// MARK: -
	
	final func isAtBottomOfAlbum() -> Bool {
		guard
			let myID = songInfo()?.songID,
			let album = container,
			let bottomSong = album.songs(sorted: true).last,
			let bottomSongInfo = bottomSong.songInfo()
		else {
			// Better to accidentally leave “Play Rest of Album Last” enabled than accidentally disable it.
			return false
		}
		let result = myID == bottomSongInfo.songID
		return result
	}
	
	// MARK: - Sorting
	
	final func precedesInUserCustomOrder(_ other: Song) -> Bool {
		// Checking song index first and collection index last is slightly faster than vice versa.
		guard index == other.index else {
			return index < other.index
		}
		
		let myAlbum = container!
		let otherAlbum = other.container!
		guard myAlbum.index == other.index else {
			return myAlbum.index < otherAlbum.index
		}
		
		let myCollection = myAlbum.container!
		let otherCollection = otherAlbum.container!
		return myCollection.index < otherCollection.index
	}
}

// MARK: - Apple Music

@preconcurrency import MusicKit
extension Song {
	@MainActor final func musicKitSong() async -> MusicKit.Song? {
		var request = MusicLibraryRequest<MusicKit.Song>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(persistentID)))
		guard
			let response = try? await request.response(),
			response.items.count == 1
		else { return nil }
		return response.items.first
	}
	
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
		
		player.queue = SystemMusicPlayer.Queue(for: musicItems, startingAt: rowItem)
		try? await player.play()
		
		// As of iOS 17.2 beta, if setting the queue effectively did nothing, you must do these after calling `play`, not before.
		player.state.repeatMode = MusicPlayer.RepeatMode.none
		player.state.shuffleMode = .off
	}
	@MainActor final func play() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		player.queue = SystemMusicPlayer.Queue(for: [musicItem])
		try? await player.play()
		
		player.state.repeatMode = MusicPlayer.RepeatMode.none
		player.state.shuffleMode = .off
	}
	@MainActor final func playLast() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		guard let _ =
				try? await player.queue.insert([musicItem], position: .tail)
		else { return }
		
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
	}
	@MainActor final func playRestOfAlbumLast() async {
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
}

import MediaPlayer
extension Song {
	final func songInfo() -> (any SongInfo)? {
#if targetEnvironment(simulator)
		return Sim_SongInfo.everyInfo[persistentID]
#else
		return mpMediaItem()
#endif
	}
	private func mpMediaItem() -> MPMediaItem? {
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(MPMediaPropertyPredicate(
			value: persistentID,
			forProperty: MPMediaItemPropertyPersistentID))
		guard
			let queriedSongs = songsQuery.items,
			queriedSongs.count == 1
		else { return nil }
		return queriedSongs.first
	}
	
	final func isInPlayer() -> Bool {
#if targetEnvironment(simulator)
		let sim_info = songInfo() as! Sim_SongInfo
		return sim_info == Sim_SongInfo.current
#else
		// I could compare MusicKit’s now-playing `Song` to this instance’s Media Player identifier, but haven’t found a simple way. We could request this instance’s MusicKit `Song`, but that requires `await`ing.
		return persistentID == MPMusicPlayerController._system?.nowPlayingItem?.songID
#endif
	}
}
