//
//  Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData

extension Song: LibraryItem {
	@MainActor final func containsPlayhead() -> Bool {
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.objectID
#else
		guard
			let songInPlayer = managedObjectContext?.songInPlayer()
		else { return false }
		return objectID == songInPlayer.objectID
#endif
	}
}

extension Song {
	convenience init(
		atEndOf album: Album,
		songID: SongID,
		context: NSManagedObjectContext
	) {
		self.init(context: context)
		persistentID = songID
		index = Int64(album.contents?.count ?? 0)
		container = album
	}
	
	// Use `init(atEndOf:songID:context:)` if possible. It’s faster.
	convenience init(
		atBeginningOf album: Album,
		songID: SongID,
		context: NSManagedObjectContext
	) {
		album.songs(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		persistentID = songID
		index = 0
		container = album
	}
	
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
	
	// MARK: - All instances
	
	static func allFetched(
		sorted: Bool,
		inAlbum: Album?,
		context: NSManagedObjectContext
	) -> [Song] {
		let fetchRequest = fetchRequest()
		if sorted {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		if let inAlbum {
			fetchRequest.predicate = NSPredicate(format: "container == %@", inAlbum)
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// MARK: - Predicates
	
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
@MainActor extension Song {
	final func musicKitSong() async -> MusicKit.Song? {
		var request = MusicLibraryRequest<MusicKit.Song>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(persistentID)))
		guard
			let response = try? await request.response(),
			response.items.count == 1
		else {
			return nil
		}
		
		return response.items.first
	}
	
	final func play() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		player.queue = SystemMusicPlayer.Queue(for: [musicItem])
		try? await player.play()
		
		player.state.repeatMode = MusicPlayer.RepeatMode.none
		player.state.shuffleMode = .off
	}
	
	final func playLast() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		guard let _ =
				try? await player.queue.insert([musicItem], position: .tail)
		else { return }
		
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
	}
	
	final func playRestOfAlbumLast() async {
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
		// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
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
	@MainActor func avatarStatus() -> AvatarStatus {
		guard
			containsPlayhead(),
			let __player = MPMusicPlayerController._system
		else {
			return .notPlaying
		}
#if targetEnvironment(simulator)
		return .playing
#else
		if __player.playbackState == .playing {
			return .playing
		} else {
			return .paused
		}
#endif
	}
	
	final func songInfo() -> SongInfo? {
#if targetEnvironment(simulator)
		// To match `mpMediaItem`
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		return Sim_SongInfo.dict[persistentID]
#else
		return mpMediaItem()
#endif
	}
	
	final func mpMediaItem() -> MPMediaItem? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(MPMediaPropertyPredicate(
			value: persistentID,
			forProperty: MPMediaItemPropertyPersistentID))
		guard
			let queriedSongs = songsQuery.items,
			queriedSongs.count == 1
		else {
			return nil
		}
		
		return queriedSongs.first
	}
}
