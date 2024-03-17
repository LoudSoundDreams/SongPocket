// 2021-12-30

// Keeping these keys in one place helps us keep them unique.
enum LRDefaultsKey: String, CaseIterable {
	// Introduced in version ?
	case hasSavedDatabase = "hasEverImportedFromMusic"
	
	/*
	 Deprecated after version 1.13.3
	 Introduced in version 1.8
	 "nowPlayingIcon"
	 Values: String
	 Introduced in version 1.12
	 • "Paw"
	 • "Luxo"
	 Introduced in version 1.8
	 • "Speaker"
	 • "Fish"
	 Deprecated after version 1.11.2:
	 • "Bird"
	 • "Sailboat"
	 • "Beach umbrella"
	 
	 Deprecated after version 1.13.3
	 Introduced in version 1.0
	 "accentColorName"
	 Values: String
	 • "Blueberry"
	 • "Grape"
	 • "Strawberry"
	 • "Tangerine"
	 • "Lime"
	 
	 Deprecated after version 1.13
	 Introduced in version 1.6
	 "appearance"
	 Values: Int
	 • `0` for “match system”
	 • `1` for “always light”
	 • `2` for “always dark”
	 
	 Deprecated after version 1.7
	 Introduced in version ?
	 "shouldExplainQueueAction"
	 Values: Bool
	 */
}

import CoreData
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
}
