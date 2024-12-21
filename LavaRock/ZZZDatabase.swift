// 2020-08-22

import CoreData

enum ZZZDatabase {
	@MainActor static func migrate() {
		let context = container.viewContext
		context.migrate_to_single_collection()
		context.migrate_to_disk()
		
		let coordinator = container.persistentStoreCoordinator
		coordinator.persistentStores.forEach { store in
			try! coordinator.destroyPersistentStore(
				at: store.url!,
				type: NSPersistentStore.StoreType(rawValue: store.type))
		}
	}
	
	private static let container: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "ZZZContainer")
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
	
	@MainActor static let __viewContext = container.viewContext
	static func renumber(_ items: [NSManagedObject]) {
		items.enumerated().forEach { (index, item) in
			item.setValue(Int64(index), forKey: "index")
		}
	}
}

extension NSManagedObjectContext {
	fileprivate final func migrate_to_single_collection() {
		// Databases created before version 2.5 can contain multiple `Collection`s, each with a non-default title.
#if DEBUG
		//		mock_multicollection()
#endif
		// Move all `Album`s into the first `Collection`, and give it the default title.
		
		let all: [ZZZCollection] = {
			let request = ZZZCollection.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			return fetch_please(request)
		}()
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
#if DEBUG
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
#endif
	
	fileprivate final func migrate_to_disk() {
		// Write data to persistent storage as if the app never used Core Data previously.
		
		// Exit early if there’s nothing to migrate. The rest of the app must handle empty persistent storage anyway.
		let zzzCollection: ZZZCollection? = {
			let request = ZZZCollection.fetchRequest()
			return fetch_please(request).first
		}()
		guard let zzzCollection else { return }
		
		// TO DO
		let _ = zzzCollection
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
}

extension ZZZCollection {
	final func albums(sorted: Bool) -> [ZZZAlbum] {
		guard let contents else { return [] }
		let unsorted = contents.map { $0 as! ZZZAlbum }
		guard sorted else { return unsorted }
		return unsorted.sorted { $0.index < $1.index }
	}
}
extension ZZZAlbum {
	final func songs(sorted: Bool) -> [ZZZSong] {
		guard let contents else { return [] }
		let unsorted = contents.map { $0 as! ZZZSong }
		guard sorted else { return unsorted }
		return unsorted.sorted { $0.index < $1.index }
	}
}
