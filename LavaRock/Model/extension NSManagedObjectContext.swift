//
//  extension NSManagedObjectContext.swift
//  LavaRock
//
//  Created by h on 2020-08-22.
//

import CoreData

extension NSManagedObjectContext {
	
	func tryToSave() {
		perform {
			guard self.hasChanges else { return }
			do {
				try self.save()
			} catch {
				print("Crashed while trying to save changes asynchronously.")
				fatalError("\(error)")
			}
		}
	}
	
	func tryToSaveSynchronously() {
		performAndWait {
			guard self.hasChanges else { return }
			do {
				try self.save()
			} catch {
				print("Crashed while trying to save changes synchronously.")
				fatalError("\(error)")
			}
		}
	}
	
	func objectsFetched<T>(for request: NSFetchRequest<T>) -> [T] {
		var results = [T]()
		performAndWait {
			do {
				results = try self.fetch(request)
			} catch {
				fatalError("Couldn't load items from Core Data using the fetch request: \(request)")
			}
		}
		return results
	}
	
}
