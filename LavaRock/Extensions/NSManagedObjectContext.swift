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
	
	final func createCollection(
		byCombiningCollectionsWithInOrder idsOfCollectionsToCombine: [NSManagedObjectID],
		title: String,
		index: Int64
	) -> Collection {
		let result = Collection(context: self)
		result.title = title
		result.index = index
		
		let toCombine = idsOfCollectionsToCombine.map { object(with: $0) } as! [Collection]
		var contentsOfResult = toCombine.flatMap { $0.albums(sorted: true) }
		contentsOfResult.reindex()
		contentsOfResult.forEach { $0.container = result }
		
		Collection.deleteAllEmpty(via: self)
		
		return result
	}
}
