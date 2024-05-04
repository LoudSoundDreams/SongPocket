// 2020-07-10

import CoreData

extension Album {
	convenience init(
		atEndOf collection: Collection,
		albumID: AlbumID,
		context: NSManagedObjectContext
	) {
		self.init(context: context)
		albumPersistentID = albumID
		index = Int64(collection.contents?.count ?? 0)
		container = collection
	}
	
	// Use `init(atEndOf:albumID:context:)` if possible. It’s faster.
	convenience init(
		atBeginningOf collection: Collection,
		albumID: AlbumID,
		context: NSManagedObjectContext
	) {
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		albumPersistentID = albumID
		index = 0
		container = collection
	}
	
	// MARK: - All instances
	
	static func allFetched(
		sorted: Bool,
		inCollection: Collection?,
		context: NSManagedObjectContext
	) -> [Album] {
		let fetchRequest = fetchRequest()
		if sorted {
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		}
		if let inCollection {
			fetchRequest.predicate = NSPredicate(format: "container == %@", inCollection)
		}
		return context.objectsFetched(for: fetchRequest)
	}
	
	// MARK: - Songs
	
	// Similar to `Collection.albums`.
	final func songs(sorted: Bool) -> [Song] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! Song }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
	
	final func songsAreInDefaultOrder() -> Bool {
		let infos = songs(sorted: true).compactMap { $0.songInfo() } // Don’t let `Song`s that we’ll delete later disrupt an otherwise in-order `Album`; just skip over them.
		
		let sortedInfos = infos.sorted {
			$0.precedesInDefaultOrder(inSameAlbum: $1)
		}
		
		return infos.indices.allSatisfy { index in
			infos[index].songID == sortedInfos[index].songID
		}
	}
	
	final func sortSongsByDefaultOrder() {
		let songs = songs(sorted: false)
		
		// Behavior is undefined if you compare `Song`s that correspond to `SongInfo`s from different albums.
		// `Song`s that don’t have a corresponding `SongInfo` will end up at an undefined position in the result. `Song`s that do will still be in the correct order relative to each other.
		func sortedByDefaultOrder(inSameAlbum: [Song]) -> [Song] {
			var songsAndInfos = songs.map {
				(song: $0,
				 info: $0.songInfo()) // Can be `nil`
			}
			
			songsAndInfos.sort { leftTuple, rightTuple in
				guard let leftInfo = leftTuple.info, let rightInfo = rightTuple.info else { return true }
				return leftInfo.precedesInDefaultOrder(inSameAlbum: rightInfo)
			}
			
			return songsAndInfos.map { tuple in tuple.song }
		}
		
		let sortedSongs = sortedByDefaultOrder(inSameAlbum: songs)
		Database.renumber(sortedSongs)
	}
	
	// MARK: Creating
	
	final func createSongsAtEnd(with songIDs: [SongID]) {
		songIDs.forEach {
			let _ = Song(
				atEndOf: self,
				songID: $0,
				context: managedObjectContext!)
		}
	}
	
	// Use `createSongsAtEnd` if possible. It’s faster.
	final func createSongsAtBeginning(with songIDs: [SongID]) {
		songIDs.reversed().forEach {
			let _ = Song(
				atBeginningOf: self,
				songID: $0,
				context: managedObjectContext!)
		}
	}
	
	// MARK: - Predicates
	
	final func precedesByNewestFirst(_ other: Album) -> Bool {
		// Leave elements in the same order if they both have no release date, or the same release date.
		
		// Move unknown release date to the end
		guard let otherDate = other.releaseDateEstimate else { return true }
		guard let myDate = releaseDateEstimate else { return false }
		
		return myDate > otherDate
	}
}

// MARK: - Media Player

import MediaPlayer
extension Album {
	final func representativeSongInfo() -> SongInfo? {
#if targetEnvironment(simulator)
		return songs(sorted: true).first?.songInfo()
#else
		return mpMediaItemCollection()?.representativeItem
#endif
	}
	private func mpMediaItemCollection() -> MPMediaItemCollection? {
		let albumsQuery = MPMediaQuery.albums()
		albumsQuery.addFilterPredicate(MPMediaPropertyPredicate(
			value: albumPersistentID,
			forProperty: MPMediaItemPropertyAlbumPersistentID))
		guard
			let queriedAlbums = albumsQuery.collections,
			queriedAlbums.count == 1
		else { return nil }
		return queriedAlbums.first
	}
	
	// MARK: - Formatted attributes
	
	final func titleFormatted() -> String {
		guard
			let albumTitle = representativeSongInfo()?.albumTitleOnDisk,
			albumTitle != ""
		else { return LRString.unknownAlbum }
		return albumTitle
	}
	
	final func releaseDateEstimateFormatted() -> String {
		guard let releaseDateEstimate else { return LRString.emDash }
		return releaseDateEstimate.formatted(date: .abbreviated, time: .omitted)
	}
}
