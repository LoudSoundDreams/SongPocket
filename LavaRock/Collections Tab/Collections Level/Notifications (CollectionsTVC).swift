//
//  Notifications (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-01.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	override func managedObjectContextDidSave(_ notification: Notification) {
		guard shouldRespondToNextManagedObjectContextDidSaveNotification else { return }
		shouldRespondToNextManagedObjectContextDidSaveNotification = false
		
		let changeTypes = [NSUpdatedObjectsKey, NSInsertedObjectsKey, NSDeletedObjectsKey]
		for changeType in changeTypes {
			if let updatedObjects = notification.userInfo?[changeType] as? Set<NSManagedObject> {
				var updatedCollections = [Collection]()
				for object in updatedObjects {
					if let collection = object as? Collection {
						updatedCollections.append(collection)
						print("The collection “\(String(describing: collection.title))” should be updated with change type “\(changeType)” at index \(collection.index).")
					}
				}
				print("We need to update \(updatedCollections.count) collections with change type “\(changeType)”.")
			}
		}
	}
	
	
}
