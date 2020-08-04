//
//  CoreDataManager.swift
//  LavaRock
//
//  Created by h on 2020-07-21.
//

import CoreData
import UIKit

final class CoreDataManager {
	
	// MARK: Properties
	
	// "Constants"
	let managedObjectContext: NSManagedObjectContext
	
	// MARK: Methods
	
	init(managedObjectContext: NSManagedObjectContext) {
		self.managedObjectContext = managedObjectContext
	}
	
	func save() {
		managedObjectContext.perform {
			guard self.managedObjectContext.hasChanges else { return }
			do {
				try self.managedObjectContext.save()
			} catch {
				print("Crashed while trying to save changes.")
				fatalError("\(error)")
			}
		}
	}
	
	func managedObjects(for request: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
		var results = [NSManagedObject]()
		managedObjectContext.performAndWait {
			do {
				results = try managedObjectContext.fetch(request)
			} catch {
				fatalError("Couldn't load items from Core Data using the fetch request: \(request)")
			}
		}
		return results
	}
	
	// Just for testing.
	
	func check(request: NSFetchRequest<NSFetchRequestResult>) {
		print("Checking the current managed object context with the Core Data fetch request: \(request)")
		managedObjectContext.performAndWait {
			do {
				let results = try self.managedObjectContext.fetch(request)
				print("I found these managed objects: \(String(describing: results))")
			} catch {
				fatalError("\(error)")
			}
		}
	}
	
}
