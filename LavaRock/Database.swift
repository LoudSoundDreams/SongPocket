// 2020-08-22

import CoreData
import MusicKit

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

extension NSManagedObjectContext {
	final func printLibrary(
		referencing: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>]
	) {
		Collection.allFetched(sorted: true, context: self).forEach { collection in
			print(collection.index, collection.title ?? "")
			
			collection.albums(sorted: true).forEach { album in
				print(" ", album.index, referencing[MusicItemID(String(album.albumPersistentID))]?.title ?? InterfaceText.unknownAlbum)
				
				album.songs(sorted: true).forEach { song in
					print("   ", song.index, song.songInfo()?.titleOnDisk ?? InterfaceText.emDash)
				}
			}
		}
	}
	
	final func tryToSave() {
		performAndWait {
			guard hasChanges else { return }
			do {
				try save()
			} catch {
				fatalError("Crashed while trying to save changes synchronously: \(error)")
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
	
	// WARNING: Leaves gaps in the `Album` indices within each `Collection`, and doesn’t delete empty `Collection`s. You must call `deleteEmptyCollections` later.
	final func unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade() {
		let all = Album.allFetched(sorted: false, context: self)
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
