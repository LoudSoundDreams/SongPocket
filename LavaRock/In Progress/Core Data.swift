// 2020-08-22

import CoreData
import MusicKit

enum ZZZDatabase {
	@MainActor static let viewContext = container.viewContext
	
	static func renumber(_ items: [NSManagedObject]) {
		items.enumerated().forEach { (index, item) in
			item.setValue(Int64(index), forKey: "index")
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
	fileprivate static func fetch_request_sorted() -> NSFetchRequest<ZZZCollection> {
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
	
	/*
	 final func promote_albums(with ids_to_promote: Set<MPIDAlbum>) {
	 var my_albums = albums(sorted: true)
	 let rs_to_promote = my_albums.indices { ids_to_promote.contains($0.albumPersistentID) }
	 guard let front: Int = rs_to_promote.ranges.first?.first else { return }
	 let target: Int = (rs_to_promote.ranges.count == 1)
	 ? max(front-1, 0)
	 : front
	 
	 my_albums.moveSubranges(rs_to_promote, to: target)
	 ZZZDatabase.renumber(my_albums)
	 managedObjectContext!.save_please()
	 }
	 final func demote_albums(with ids_to_demote: Set<MPIDAlbum>) {
	 var my_albums = albums(sorted: true)
	 let rs_to_demote = my_albums.indices { ids_to_demote.contains($0.albumPersistentID) }
	 guard let back: Int = rs_to_demote.ranges.last?.last else { return }
	 let target: Int = (rs_to_demote.ranges.count == 1)
	 ? min(back+1, my_albums.count-1)
	 : back
	 
	 my_albums.moveSubranges(rs_to_demote, to: target+1) // This method puts the last in-range element before the `to:` index.
	 ZZZDatabase.renumber(my_albums)
	 managedObjectContext!.save_please()
	 }
	 
	 final func float_albums(with ids_to_float: Set<MPIDAlbum>) {
	 var my_albums = albums(sorted: true)
	 let rs_to_float = my_albums.indices { ids_to_float.contains($0.albumPersistentID) }
	 
	 my_albums.moveSubranges(rs_to_float, to: 0)
	 ZZZDatabase.renumber(my_albums)
	 managedObjectContext!.save_please()
	 }
	 final func sink_albums(with ids_to_sink: Set<MPIDAlbum>) {
	 var my_albums = albums(sorted: true)
	 let rs_to_sink = my_albums.indices { ids_to_sink.contains($0.albumPersistentID) }
	 
	 my_albums.moveSubranges(rs_to_sink, to: my_albums.count)
	 ZZZDatabase.renumber(my_albums)
	 managedObjectContext!.save_please()
	 }
	 */
}

// MARK: - Album

extension ZZZAlbum {
	static func fetch_request_sorted() -> NSFetchRequest<ZZZAlbum> {
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
	
	convenience init?(at_beginning_of collection: ZZZCollection, mpidAlbum: MPIDAlbum) {
		guard let context = collection.managedObjectContext else { return nil }
		
		collection.albums(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = collection
		albumPersistentID = mpidAlbum
	}
}

// MARK: - Song

extension ZZZSong {
	convenience init?(at_beginning_of album: ZZZAlbum, mpidSong: MPIDSong) {
		guard let context = album.managedObjectContext else { return nil }
		
		album.songs(sorted: false).forEach { $0.index += 1 }
		
		self.init(context: context)
		index = 0
		container = album
		persistentID = mpidSong
	}
}

// MARK: - Managed object context

extension NSManagedObjectContext {
	final func debug_Print(
		referencing_mkSections_by_musicItemID mkSections: [MusicItemID: MKSection]
	) {
		fetch_please(ZZZCollection.fetch_request_sorted()).forEach { collection in
			Print(collection.index, collection.title ?? "")
			
			collection.albums(sorted: true).forEach { album in
				let mkSection: MKSection? = mkSections[MusicItemID(String(album.albumPersistentID))]
				Print(" ", album.index, album.albumPersistentID, mkSection?.title ?? "")
				
				album.songs(sorted: true).forEach { song in
					Print("   ", song.index, song.persistentID)
				}
			}
		}
	}
	
	final func fetch_collection() -> ZZZCollection? {
		return fetch_please(ZZZCollection.fetch_request_sorted()).first
	}
	final func fetch_please<T>(_ request: NSFetchRequest<T>) -> [T] {
		var result: [T] = []
		do {
			result = try fetch(request)
		} catch {
			fatalError("Core Data couldn’t fetch: \(request). \(error)")
		}
		return result
	}
	
	// MARK: Migration
	
	final func migrate_to_single_collection() {
		// Databases created before version 2.5 can contain multiple `Collection`s, each with a non-default title.
#if DEBUG
		//		mock_multicollection()
#endif
		// Move all `Album`s into the first `Collection`, and give it the default title.
		
		let all = fetch_please(ZZZCollection.fetch_request_sorted())
		guard let top = all.first else { return }
		
		let rest = all.dropFirst()
		let title_default = InterfaceText._tilde
		let needs_changes = !rest.isEmpty || (top.title != title_default)
		guard needs_changes else { return }
		
		top.title = title_default
		rest.forEach { collection in
			collection.albums(sorted: true).forEach { album in
				album.index = Int64(top.contents?.count ?? 0)
				album.container = top
			}
			delete(collection)
		}
	}
	private func mock_multicollection() {
		fetch_please(ZZZSong.fetchRequest()).forEach { delete($0) }
		fetch_please(ZZZAlbum.fetchRequest()).forEach { delete($0) }
		fetch_please(ZZZCollection.fetchRequest()).forEach { delete($0) }
		
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
	
	@MainActor final func migrate_to_disk() {
		// Write data to persistent storage as if the app never used Core Data previously.
		
		// Exit early if there’s nothing to migrate. The rest of the app must handle empty persistent storage anyway.
		guard let zzzCollection = fetch_collection() else { return }
		
		zzzCollection.albums(sorted: true).forEach { zzzAlbum in
			let lrAlbum = Librarian.append_lrAlbum(mpid: zzzAlbum.albumPersistentID)
			zzzAlbum.songs(sorted: true).forEach { zzzSong in
				Librarian.append_lrSong(mpid: zzzSong.persistentID, in: lrAlbum)
			}
		}
		
		Librarian.save() // This makes `Librarian` save and reload the same library items, but lets it always use the same code to load during startup, regardless of whether we ran this migration.
		ZZZDatabase.destroy()
	}
}
