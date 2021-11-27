//
//  NSManagedObjectContext.swift
//  LavaRock
//
//  Created by h on 2020-08-22.
//

import CoreData

extension NSManagedObjectContext {
	
	static func withParent(
		_ parent: NSManagedObjectContext
	) -> NSManagedObjectContext {
		let result: NSManagedObjectContext = {
			if #available(iOS 15, *) {
				// When we require iOS 15, we can make turn this method into an initializer.
				return NSManagedObjectContext(.mainQueue)
			} else {
				return Self(concurrencyType: .mainQueueConcurrencyType)
			}
		}()
		result.parent = parent
		return result
	}
	
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
