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
		var result = [T]()
		performAndWait {
			do {
				result = try fetch(request)
			} catch {
				fatalError("Couldn't load items from Core Data using the fetch request: \(request)")
			}
		}
		return result
	}
	
}
