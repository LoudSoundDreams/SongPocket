//
//  MusicLibrary.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer
import OSLog

final class MusicLibrary {
	private init() {}
	static let shared = MusicLibrary()
	
	let context = Database.viewContext
	
	private var library: MPMediaLibrary? = nil
	
	func beginWatching() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		library?.endGeneratingLibraryChangeNotifications()
		library = MPMediaLibrary.default()
		library?.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(mediaLibraryDidChange),
			name: .MPMediaLibraryDidChange,
			object: library)
		
		mergeChanges()
	}
	@objc private func mediaLibraryDidChange() { mergeChanges() }
	
	private func mergeChanges() {
		os_signpost(.begin, log: .merge, name: "1. Merge changes")
		defer {
			os_signpost(.end, log: .merge, name: "1. Merge changes")
		}
		
#if targetEnvironment(simulator)
		context.performAndWait {
			let walpurgisNightAlbumID = Sim_AlbumIDDispenser.takeNumber()
			let planetaryPiecesAlbumID = Sim_AlbumIDDispenser.takeNumber()
			let realAlbumID = Sim_AlbumIDDispenser.takeNumber()
			mergeChanges(toMatchInAnyOrder: (
				Enabling.sim_emptyLibrary
				? []
				: [
					Sim_SongInfo(
						albumID: walpurgisNightAlbumID,
						albumArtistOnDisk: "GFriend",
						albumTitleOnDisk: "回:Walpurgis Night",
						discCountOnDisk: 2,
						discNumberOnDisk: 1,
						trackNumberOnDisk: 1,
						titleOnDisk: "Amazingly few discotheques provide jukeboxes.",
						artistOnDisk: "Five Boxing Wizards",
						dateAddedOnDisk: .now,
						releaseDateOnDisk: .now,
						coverArtFileName: "Walpurgis Night"),
					Sim_SongInfo(
						albumID: walpurgisNightAlbumID,
						albumArtistOnDisk: "GFriend",
						albumTitleOnDisk: "回:Walpurgis Night",
						discCountOnDisk: 1,
						discNumberOnDisk: 1,
						trackNumberOnDisk: 900,
						titleOnDisk: "Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.",
						artistOnDisk: "GFriend",
						dateAddedOnDisk: .now,
						releaseDateOnDisk: .now,
						coverArtFileName: "Walpurgis Night"),
					Sim_SongInfo(
						albumID: planetaryPiecesAlbumID,
						albumArtistOnDisk: nil,
						albumTitleOnDisk: nil,
						discCountOnDisk: 0,
						discNumberOnDisk: 0,
						trackNumberOnDisk: 0,
						titleOnDisk: nil,
						artistOnDisk: nil,
						dateAddedOnDisk: .now,
						releaseDateOnDisk: nil,
						coverArtFileName: "Planetary Pieces"),
					Sim_SongInfo(
						albumID: realAlbumID,
						albumArtistOnDisk: "IU",
						albumTitleOnDisk: "Real",
						discCountOnDisk: 1,
						discNumberOnDisk: 1,
						trackNumberOnDisk: 3,
						titleOnDisk: "좋은 날",
						artistOnDisk: "IU",
						dateAddedOnDisk: .now,
						releaseDateOnDisk: nil,
						coverArtFileName: "Real"),
				]
			))
		}
#else
		let songsQuery = MPMediaQuery.songs()
		if let freshMediaItems = songsQuery.items {
			context.performAndWait {
				mergeChanges(toMatchInAnyOrder: freshMediaItems)
			}
		}
#endif
	}
	
	deinit {
		library?.endGeneratingLibraryChangeNotifications()
	}
}
