//
//  NSManagedObjectContext.swift
//  LavaRock
//
//  Created by h on 2020-08-22.
//

import CoreData

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
