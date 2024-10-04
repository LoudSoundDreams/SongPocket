// 2020-08-22

import CoreData

enum ZZZDatabase {
	@MainActor static let viewContext = container.viewContext
	
	static func renumber(_ items: [NSManagedObject]) {
		items.enumerated().forEach { (currentIndex, item) in
			item.setValue(Int64(currentIndex), forKey: "index")
		}
	}
	
	static func destroy() {
		let coordinator = container.persistentStoreCoordinator
		coordinator.persistentStores.forEach { store in
			try! coordinator.destroyPersistentStore(
				at: store.url!,
				type: NSPersistentStore.StoreType(rawValue: store.type))
		}
	}
	
	private static let container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "LavaRock")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			container.viewContext.automaticallyMergesChangesFromParent = true
			if let error = error as NSError? {
				/*
				 Project template suggestions for an error here:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 */
				fatalError("Core Data couldn’t load some persistent store. \(error), \(error.userInfo)")
			}
		})
		return container
	}()
}

// MARK: - Collection

extension ZZZCollection {
	fileprivate static func fetchRequest_sorted() -> NSFetchRequest<ZZZCollection> {
		let result = fetchRequest()
		result.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return result
	}
	
	// Similar to `Album.songs`.
	final func albums(sorted: Bool) -> [ZZZAlbum] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! ZZZAlbum }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
}

// MARK: - Album

extension ZZZAlbum {
	static func fetchRequest_sorted() -> NSFetchRequest<ZZZAlbum> {
		let result = fetchRequest()
		result.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return result
	}
	
	// Similar to `Collection.albums`.
	final func songs(sorted: Bool) -> [ZZZSong] {
		guard let contents else { return [] }
		
		let unsorted = contents.map { $0 as! ZZZSong }
		guard sorted else { return unsorted }
		
		return unsorted.sorted { $0.index < $1.index }
	}
	
	convenience init?(atBeginningOf collection: ZZZCollection, albumID: AlbumID) {
		guard let context = collection.managedObjectContext else { return nil }
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = collection
		albumPersistentID = albumID
	}
	
	final func promoteSongs(with idsToPromote: Set<SongID>) {
		var mySongs = songs(sorted: true)
		let rsToPromote = mySongs.indices { idsToPromote.contains($0.persistentID) }
		guard let front: Int = rsToPromote.ranges.first?.first else { return }
		let target: Int = (rsToPromote.ranges.count == 1)
		? max(front-1, 0)
		: front
		
		mySongs.moveSubranges(rsToPromote, to: target)
		ZZZDatabase.renumber(mySongs)
		managedObjectContext!.savePlease()
	}
	final func demoteSongs(with idsToDemote: Set<SongID>) {
		var mySongs = songs(sorted: true)
		let rsToDemote = mySongs.indices { idsToDemote.contains($0.persistentID) }
		guard let back: Int = rsToDemote.ranges.last?.last else { return }
		let target: Int = (rsToDemote.ranges.count == 1)
		? min(back+1, mySongs.count-1)
		: back
		
		mySongs.moveSubranges(rsToDemote, to: target+1) // This method puts the last in-range element before the `to:` index.
		ZZZDatabase.renumber(mySongs)
		managedObjectContext!.savePlease()
	}
}

// MARK: - Song

extension ZZZSong {
	convenience init?(atBeginningOf album: ZZZAlbum, songID: SongID) {
		guard let context = album.managedObjectContext else { return nil }
		
		album.songs(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = album
		persistentID = songID
	}
}

// MARK: - Managed object context

import MusicKit
extension NSManagedObjectContext {
	final func printLibrary(referencing: [MusicItemID: MKSection]) {
		fetchPlease(ZZZCollection.fetchRequest_sorted()).forEach { collection in
			print(collection.index, collection.title ?? "")
			
			collection.albums(sorted: true).forEach { album in
				let mkSection: MKSection? = referencing[MusicItemID(String(album.albumPersistentID))]
				print(" ", album.index, album.albumPersistentID, mkSection?.title ?? "")
				
				album.songs(sorted: true).forEach { song in
					print("   ", song.index, song.persistentID)
				}
			}
		}
	}
	
	final func fetchCollection() -> ZZZCollection? {
		return fetchPlease(ZZZCollection.fetchRequest_sorted()).first
	}
	final func fetchAlbum(id albumIDToMatch: AlbumID) -> ZZZAlbum? {
		let request = ZZZAlbum.fetchRequest()
		request.predicate = NSPredicate(format: "albumPersistentID = %lld", albumIDToMatch)
		return fetchPlease(request).first
	}
	final func fetchSong(mpID: SongID) -> ZZZSong? {
		let request = ZZZSong.fetchRequest()
		// As of Xcode 16.0 RC, `#Predicate` produces the bogus warning: Type 'ReferenceWritableKeyPath<ZZZSong, Int64>' does not conform to the 'Sendable' protocol
//		request.predicate = NSPredicate(#Predicate<ZZZSong> {
//			mpID == $0.persistentID
//		})
		request.predicate = NSPredicate(format: "persistentID = %lld", mpID)
		return fetchPlease(request).first
	}
	final func fetchPlease<T>(_ request: NSFetchRequest<T>) -> [T] {
		var result: [T] = []
		do {
			result = try fetch(request)
		} catch {
			fatalError("Core Data couldn’t fetch: \(request). \(error)")
		}
		return result
	}
	
	final func savePlease() {
		guard !WorkingOn.plainDatabase else { return }
		guard hasChanges else { return }
		do {
			try save()
		} catch {
			fatalError("Core Data couldn’t save. \(error)")
		}
	}
	
	// MARK: - Migration
	
	final func migrateFromMulticollection() {
		// Databases created before version 2.5 can contain multiple `Collection`s, each with a non-default title.
#if DEBUG
		//		mockMulticollection()
#endif
		// Move all `Album`s into the first `Collection`, and give it the default title.
		
		let all = fetchPlease(ZZZCollection.fetchRequest_sorted())
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
			delete(collection)
		}
		savePlease()
	}
	private func mockMulticollection() {
		fetchPlease(ZZZSong.fetchRequest()).forEach { delete($0) }
		fetchPlease(ZZZAlbum.fetchRequest()).forEach { delete($0) }
		fetchPlease(ZZZCollection.fetchRequest()).forEach { delete($0) }
		
		let one = ZZZCollection(context: self)
		one.index = Int64(0)
		one.title = ""
		
		let two = ZZZCollection(context: self)
		two.index = Int64(1)
		two.title = nil
		
		let three = ZZZCollection(context: self)
		three.index = Int64(2)
		three.title = one.title // Duplicate titles allowed
		
		let alpha = ZZZAlbum(context: self)
		alpha.container = one; alpha.index = Int64(0)
		alpha.albumPersistentID = Int64.max
		alpha.releaseDateEstimate = nil // Absence of release date allowed
		
		let bravo = ZZZAlbum(context: self)
		bravo.container = one; bravo.index = Int64(1)
		bravo.albumPersistentID = Int64.min
		bravo.releaseDateEstimate = Date.now
		
		let charlie = ZZZAlbum(context: self)
		charlie.container = two; charlie.index = Int64(0)
		charlie.albumPersistentID = Int64.max - 1
		bravo.releaseDateEstimate = Date.distantPast
		
		let delta = ZZZAlbum(context: self)
		delta.container = three; delta.index = Int64(0)
		delta.albumPersistentID = Int64.max - 2
		delta.releaseDateEstimate = Date.distantFuture
		
		let uno = ZZZSong(context: self)
		uno.container = alpha; uno.index = Int64(0)
		uno.persistentID = Int64.min
		let dos = ZZZSong(context: self)
		dos.container = bravo; dos.index = Int64(0)
		dos.persistentID = Int64.max
		let tres = ZZZSong(context: self)
		tres.container = charlie; tres.index = Int64(0)
		tres.persistentID = Int64(42)
		let cuatro = ZZZSong(context: self)
		cuatro.container = delta; cuatro.index = Int64(0)
		cuatro.persistentID = Int64(-10000)
	}
}
