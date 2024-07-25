// 2020-08-22

import CoreData

enum Database {
	@MainActor static let viewContext = container.viewContext
	private static let container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "LavaRock")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			container.viewContext.automaticallyMergesChangesFromParent = true
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	static func renumber(_ items: [NSManagedObject]) {
		items.enumerated().forEach { (currentIndex, item) in
			item.setValue(Int64(currentIndex), forKey: "index")
		}
	}
}

// MARK: - Collection

extension Collection {
	// Similar to `Album.fetchRequest_sorted`.
	static func fetchRequest_sorted() -> NSFetchRequest<Collection> {
		let result = fetchRequest()
		result.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return result
	}
	
	// Similar to `Album.songs`.
	final func albums(sorted: Bool) -> [Album] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! Album }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
}

// MARK: - Album

extension Album {
	// Similar to `Collection.fetchRequest_sorted`.
	static func fetchRequest_sorted() -> NSFetchRequest<Album> {
		let result = fetchRequest()
		result.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return result
	}
	
	// Similar to `Collection.albums`.
	final func songs(sorted: Bool) -> [Song] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! Song }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
	
	convenience init?(atEndOf collection: Collection, albumID: AlbumID) {
		guard let context = collection.managedObjectContext else { return nil }
		self.init(context: context)
		index = Int64(collection.contents?.count ?? 0)
		container = collection
		albumPersistentID = albumID
	}
	
	// Use `init(atEndOf:albumID:)` if possible. It’s faster.
	convenience init?(atBeginningOf collection: Collection, albumID: AlbumID) {
		guard let context = collection.managedObjectContext else { return nil }
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = collection
		albumPersistentID = albumID
	}
	
	final func isAtBottom() -> Bool {
		return index >= (container?.contents ?? []).count - 1
	}
}

// MARK: - Song

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
	
	final func isAtBottom() -> Bool {
		return index >= (container?.contents ?? []).count - 1
	}
	
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
import MediaPlayer
extension Song {
	@MainActor final func songInfo() -> (some SongInfo)? {
#if targetEnvironment(simulator)
		return Sim_MusicLibrary.shared.songInfos[persistentID]
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
}

// MARK: - Managed object context

import MusicKit
extension NSManagedObjectContext {
	final func printLibrary(
		referencing: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>]
	) {
		fetchPlease(Collection.fetchRequest_sorted()).forEach { collection in
			print(collection.index, collection.title ?? "")
			
			collection.albums(sorted: true).forEach { album in
				let musicKitSection: MusicLibrarySection<MusicKit.Album, MusicKit.Song>? = referencing[MusicItemID(String(album.albumPersistentID))]
				print(" ", album.index, musicKitSection?.title ?? InterfaceText.unknownAlbum)
				
				album.songs(sorted: true).forEach { song in
					let _ = musicKitSection?.items ?? []
					print("   ", song.index)
				}
			}
		}
	}
	
	final func fetchPlease<T>(_ request: NSFetchRequest<T>) -> [T] {
		var result: [T] = []
		do {
			result = try fetch(request)
		} catch {
			fatalError("Couldn’t load items from Core Data using the fetch request: \(request)")
		}
		return result
	}
	
	final func savePlease() {
		guard hasChanges else { return }
		do {
			try save()
		} catch {
			fatalError("Crashed while trying to save changes synchronously: \(error)")
		}
	}
	
	// WARNING: Leaves gaps in the `Album` indices within each `Collection`, and doesn’t delete empty `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade() {
		fetchPlease(Album.fetchRequest()).forEach { album in
			if album.contents?.count == 0 {
				delete(album)
			}
		}
	}
	final func deleteEmptyCollections() {
		var all = fetchPlease(Collection.fetchRequest_sorted())
		all.enumerated().reversed().forEach { (index, collection) in
			if collection.contents?.count == 0 {
				delete(collection)
				all.remove(at: index)
			}
		}
		Database.renumber(all)
	}
	
	// MARK: - Migration
	
	final func migrateFromMulticollection() {
		// Databases created before version 2.5 can contain multiple `Collection`s, each with a non-default title.
#if DEBUG
		//		mockMulticollection()
#endif
		// Move all `Album`s into the first `Collection`, and give it the default title.
		
		let all = fetchPlease(Collection.fetchRequest_sorted())
		guard let top = all.first else { return }
		
		let rest = all.dropFirst()
		let defaultTitle = InterfaceText.tilde
		let needsChanges = !rest.isEmpty || (top.title != defaultTitle)
		guard needsChanges else { return }
		
		top.title = defaultTitle
		rest.forEach { collection in
			collection.albums(sorted: true).forEach { album in
				album.index = Int64(top.contents?.count ?? 0)
				album.container = top
			}
		}
		deleteEmptyCollections()
		savePlease()
	}
	private func mockMulticollection() {
		fetchPlease(Song.fetchRequest()).forEach { delete($0) }
		fetchPlease(Album.fetchRequest()).forEach { delete($0) }
		fetchPlease(Collection.fetchRequest()).forEach { delete($0) }
		
		let one = Collection(context: self)
		one.index = Int64(0)
		one.title = ""
		
		let two = Collection(context: self)
		two.index = Int64(1)
		two.title = nil
		
		let three = Collection(context: self)
		three.index = Int64(2)
		three.title = one.title // Duplicate titles allowed
		
		let alpha = Album(context: self)
		alpha.container = one; alpha.index = Int64(0)
		alpha.albumPersistentID = Int64.max
		alpha.releaseDateEstimate = nil // Absence of release date allowed
		
		let bravo = Album(context: self)
		bravo.container = one; bravo.index = Int64(1)
		bravo.albumPersistentID = Int64.min
		bravo.releaseDateEstimate = Date.now
		
		let charlie = Album(context: self)
		charlie.container = two; charlie.index = Int64(0)
		charlie.albumPersistentID = Int64.max - 1
		bravo.releaseDateEstimate = Date.distantPast
		
		let delta = Album(context: self)
		delta.container = three; delta.index = Int64(0)
		delta.albumPersistentID = Int64.max - 2
		delta.releaseDateEstimate = Date.distantFuture
		
		let uno = Song(context: self)
		uno.container = alpha; uno.index = Int64(0)
		uno.persistentID = Int64.min
		let dos = Song(context: self)
		dos.container = bravo; dos.index = Int64(0)
		dos.persistentID = Int64.max
		let tres = Song(context: self)
		tres.container = charlie; tres.index = Int64(0)
		tres.persistentID = Int64(42)
		let cuatro = Song(context: self)
		cuatro.container = delta; cuatro.index = Int64(0)
		cuatro.persistentID = Int64(-10000)
	}
}
