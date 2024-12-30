// 2020-08-22

import CoreData
import os

enum ZZZDatabase {
	fileprivate static let signposter = OSSignposter(subsystem: "core data", category: .pointsOfInterest)
	
	@MainActor static func migrate() {
		let _migrate = Self.signposter.beginInterval("migrate")
		defer { Self.signposter.endInterval("migrate", _migrate) }
		
		// Make it look like the app never used Core Data previously.
		// Move any data here to the modern places.
		
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
		
		// Create the modern representation of how the user had arranged their library.
		let converted = container.viewContext.converted_to_lrAlbums()
		
		// The conversion can have contents only if an older version of the app previously ran.
		// Plain-text storage can have contents only if a modern version of the app previously ran.
		// If the conversion has contents, use them to overwrite any plain-text storage.
		// If the conversion is empty, leave any plain-text storage alone.
		guard !converted.isEmpty else { return }
		
		Disk.save_albums(converted)
		let coordinator = container.persistentStoreCoordinator
		coordinator.persistentStores.forEach { store in
			try! coordinator.destroyPersistentStore(
				at: store.url!,
				type: NSPersistentStore.StoreType(rawValue: store.type))
		}
	}
}

extension NSManagedObjectContext {
	fileprivate final func converted_to_lrAlbums() -> [LRAlbum] {
		let signposter = ZZZDatabase.signposter
		let _convert = signposter.beginInterval("convert")
		defer { signposter.endInterval("convert", _convert) }
		
#if DEBUG
		//		mock_zCollections()
#endif
		
		let zCollections: [ZZZCollection] = {
			let request = ZZZCollection.fetchRequest()
			request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			return fetch_please(request)
		}()
		let zAlbums = zCollections.flatMap { $0.zAlbums() }
		return zAlbums.map {
			// `MPMediaEntityPersistentID` is a type alias for `UInt64`, but when we stored them in Core Data, we converted them to `Int64`.
			let uAlbum = UAlbum(bitPattern: $0.albumPersistentID)
			let uSongs = $0.zSongs().map { zSong in
				USong(bitPattern: zSong.persistentID)
			}
			return LRAlbum(uAlbum: uAlbum, uSongs: uSongs)
		}
	}
#if DEBUG
	private func mock_zCollections() {
		fetch_please(ZZZSong.fetchRequest()).forEach { delete($0) }
		fetch_please(ZZZAlbum.fetchRequest()).forEach { delete($0) }
		fetch_please(ZZZCollection.fetchRequest()).forEach { delete($0) }
		
		/*
		 Databases created before version 2.5 can contain multiple `Collection`s, each with a non-default title.
		 Database created and migrated after that contain exactly one `ZZZCollection`, with this title: ~
		 */
		
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
	
	private func fetch_please<T>(_ request: NSFetchRequest<T>) -> [T] {
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
	final func zAlbums() -> [ZZZAlbum] {
		guard let contents else { return [] }
		let unsorted = contents.map { $0 as! ZZZAlbum }
		return unsorted.sorted { $0.index < $1.index }
	}
}
extension ZZZAlbum {
	final func zSongs() -> [ZZZSong] {
		guard let contents else { return [] }
		let unsorted = contents.map { $0 as! ZZZSong }
		return unsorted.sorted { $0.index < $1.index }
	}
}
