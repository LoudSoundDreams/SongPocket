//
//  CollectionsNC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

class CollectionsNC: UINavigationController {
	
	// MARK: Managing saved data
	
	// "Constants":
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace with a child NSManagedObjectContext in "move albums mode".
	
	// Functions
	
	func saveCurrentManagedObjectContext() {
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
	
	// Just for testing.
	func checkCurrentManagedObjectContext(request: NSFetchRequest<NSFetchRequestResult>) {
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
	
	// MARK: Moving albums
	
	// "Constants":
	var isInMoveAlbumsMode = false
	
	// "Constants" for "move albums" mode:
	var moveAlbumsModePrompt: String?
	var managedObjectIDsOfAlbumsBeingMoved = [NSManagedObjectID]()
	var managedObjectIDsOfAlbumsNotBeingMoved = [NSManagedObjectID]()
	
	// Variables:
	var didMoveAlbumsToNewCollections = false
	
}
