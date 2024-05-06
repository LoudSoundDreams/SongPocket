// 2020-08-22

import CoreData
import MediaPlayer

enum Database {
	static let viewContext = container.viewContext
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
	
	final func printLibrary() {
		Collection.allFetched(sorted: true, context: self).forEach { collection in
			print(collection.index, collection.title ?? "")
			collection.albums(sorted: true).forEach { album in
				print(" ", album.index, album.titleFormatted())
				album.songs(sorted: true).forEach { song in
					print("   ", song.index, song.songInfo()?.titleOnDisk ?? "")
				}
			}
		}
	}
	
	// Use `Collection(afterAllOtherCount:title:context:)` if possible. It’s faster.
	final func newCollection(
		index: Int64,
		title: String
	) -> Collection {
		// Displace existing `Collection`s past insertion point
		Collection.allFetched(sorted: false, context: self).forEach {
			if $0.index >= index { $0.index += 1 }
		}
		
		let result = Collection(context: self)
		result.title = title
		result.index = index
		return result
	}
	
	final func move(
		albumIDs: [NSManagedObjectID],
		toCollectionWith collectionID: NSManagedObjectID
	) {
		let toMove = albumIDs.map { object(with: $0) } as! [Album]
		let destination = object(with: collectionID) as! Collection
		let sourceCollections = Set(toMove.map { $0.container! })
		
		// Displace existing contents
		var toDisplace = Set(destination.albums(sorted: false))
		toMove.forEach { toDisplace.remove($0) }
		toDisplace.forEach {
			$0.index += Int64(toMove.count)
		}
		
		// Move albums
		toMove.enumerated().forEach { (offset, album) in
			album.container = destination
			album.index = Int64(offset)
		}
		
		// Clean up
		sourceCollections.forEach {
			let albums = $0.albums(sorted: true)
			Database.renumber(albums)
		}
		deleteEmptyCollections()
	}
	
	// WARNING: Leaves gaps in the `Album` indices within each `Collection`, and doesn’t delete empty `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade() {
		let all = Album.allFetched(sorted: false, inCollection: nil, context: self)
		all.forEach { album in
			if album.contents?.count == 0 {
				delete(album)
			}
		}
	}
	
	final func deleteEmptyCollections() {
		var all = Collection.allFetched(sorted: true, context: self)
		all.enumerated().reversed().forEach { (index, collection) in
			if collection.contents?.count == 0 {
				delete(collection)
				all.remove(at: index)
			}
		}
		Database.renumber(all)
	}
}
