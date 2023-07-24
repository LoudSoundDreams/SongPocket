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
			mergeChanges(toMatchInAnyOrder: (
				Enabling.sim_emptyLibrary
				? []
				: [
					Sim_SongInfo(
						albumID: walpurgisNightAlbumID,
						composer: "FRANTS",
						albumArtist: "GFriend",
						albumTitle: "回:Walpurgis Night",
						coverArtFileName: "Walpurgis Night",
						discCount: 2,
						discNumber: 1,
						trackNumber: 1,
						title: "Amazingly few discotheques provide jukeboxes.",
						artist: "Five Boxing Wizards",
						dateAdded: .now,
						releaseDate: .now
					),
					Sim_SongInfo(
						albumID: walpurgisNightAlbumID,
						composer: "노주환 & 이원종",
						albumArtist: "GFriend",
						albumTitle: "回:Walpurgis Night",
						coverArtFileName: "Walpurgis Night",
						discCount: 1,
						discNumber: 1,
						trackNumber: 900,
						title: "Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.",
						artist: "GFriend",
						dateAdded: .now,
						releaseDate: .now
					),
					Sim_SongInfo(
						albumID: Sim_AlbumIDDispenser.takeNumber(),
						composer: "",
						albumArtist: nil,
						albumTitle: nil,
						coverArtFileName: "Planetary Pieces",
						discCount: 0,
						discNumber: 0,
						trackNumber: 0,
						title: nil,
						artist: nil,
						dateAdded: .now,
						releaseDate: nil
					),
					Sim_SongInfo(
						albumID: Sim_AlbumIDDispenser.takeNumber(),
						composer: "이민수",
						albumArtist: "IU",
						albumTitle: "Real",
						coverArtFileName: "Real",
						discCount: 1,
						discNumber: 1,
						trackNumber: 3,
						title: "좋은 날",
						artist: "IU",
						dateAdded: .now,
						releaseDate: nil
					),
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
