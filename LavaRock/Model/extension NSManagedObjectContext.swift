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
				print("Crashed while trying to save changes.")
				fatalError("\(error)")
			}
		}
	}
	
	func objectsFetched(for request: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
		var results = [NSManagedObject]()
		performAndWait {
			do {
				results = try self.fetch(request)
			} catch {
				fatalError("Couldn't load items from Core Data using the fetch request: \(request)")
			}
		}
		return results
	}
	
	// For testing.
	func printObjectsFetched(for request: NSFetchRequest<NSFetchRequestResult>) {
		print("Checking the current managed object context with the Core Data fetch request: \(request)")
		performAndWait {
			do {
				let results = try self.fetch(request)
				print("I found these managed objects: \(String(describing: results))")
			} catch {
				fatalError("\(error)")
			}
		}
	}
	
}
