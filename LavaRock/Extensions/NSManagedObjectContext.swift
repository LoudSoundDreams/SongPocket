//
//  NSManagedObjectContext.swift
//  LavaRock
//
//  Created by h on 2020-08-22.
//

import CoreData
import MediaPlayer

extension NSManagedObjectContext {
	final func tryToSave() {
		performAndWait {
			guard hasChanges else { return }
			do {
				try save()
			} catch {
				fatalError("Crashed while trying to save changes synchronously.")
			}
		}
	}
	
	final func objectsFetched<T>(for request: NSFetchRequest<T>) -> [T] {
		var result: [T] = []
		performAndWait {
			do {
				result = try fetch(request)
			} catch {
				fatalError("Couldn’t load items from Core Data using the fetch request: \(request)")
			}
		}
		return result
	}
	
	final func printAllSongs() {
		var allSongs = Song.allFetched(sorted: true, inAlbum: nil, context: self)
		allSongs.sort { $0.container!.index < $1.container!.index }
		allSongs.sort { $0.container!.container!.index < $1.container!.container!.index }
		allSongs.forEach {
			print(
				$0.container!.container!.index,
				$0.container!.index,
				$0.index,
				$0.persistentID,
				$0.libraryTitle ?? ""
			)
		}
	}
	
	final func songInPlayer() -> Song? {
		let currentSongID: SongID? = {
#if targetEnvironment(simulator)
			return Sim_Global.currentSong?.songInfo()?.songID
#else
			guard
				let nowPlayingItem = MPMusicPlayerController.systemMusicPlayerIfAuthorized?.nowPlayingItem
			else { return nil }
			return SongID(bitPattern: nowPlayingItem.persistentID)
#endif
		}()
		guard let currentSongID else {
			return nil
		}
		
		let request = Song.fetchRequest()
		request.predicate = NSPredicate(
			format: "persistentID == %lld",
			currentSongID
		)
		let songsContainingPlayhead = objectsFetched(for: request)
		guard
			songsContainingPlayhead.count == 1,
			let song = songsContainingPlayhead.first
		else {
			return nil
		}
		return song
	}
	
	final func combine(
		_ idsOfCollectionsToCombine: [NSManagedObjectID],
		index: Int64
	) -> Collection {
		let result = Collection(context: self)
		result.title = LRString.tilde
		result.index = index
		
		let toCombine = idsOfCollectionsToCombine.map { object(with: $0) } as! [Collection]
		var contentsOfResult = toCombine.flatMap { $0.albums(sorted: true) }
		contentsOfResult.reindex()
		contentsOfResult.forEach { $0.container = result }
		
		deleteEmptyCollections()
		
		return result
	}
	
	// Use `Collection(afterAllOtherCount:title:context:)` if possible. It’s faster.
	final func newCollection(
		index: Int64,
		title: String
	) -> Collection {
		let toDisplace: [Collection] = {
			let predicate = NSPredicate(
				format: "index >= %lld",
				index)
			return Collection.allFetched(sorted: false, predicate: predicate, context: self)
		}()
		toDisplace.forEach { $0.index += 1 }
		
		let result = Collection(context: self)
		result.title = title
		result.index = index
		return result
	}
	
	// WARNING: Leaves gaps in the `Album` indices within each `Collection`, and doesn’t delete empty `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade() {
		let all = Album.allFetched(sorted: false, inCollection: nil, context: self)
		
		all.forEach { album in
			if album.isEmpty() {
				delete(album)
			}
		}
	}
	
	final func deleteEmptyCollections() {
		var all = Collection.allFetched(sorted: true, context: self)
		
		all.enumerated().reversed().forEach { (index, collection) in
			if collection.isEmpty() {
				delete(collection)
				all.remove(at: index)
			}
		}
		
		all.reindex()
	}
}
