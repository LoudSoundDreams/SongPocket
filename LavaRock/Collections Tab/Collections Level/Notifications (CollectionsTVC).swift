//
//  Notifications (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-01.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// Remember: we might be in "moving albums" mode.
	
	// This is the same as in AlbumsTVC. Move it to the AlbumMover protocol?
	override func beginObservingNotifications() {
		super.beginObservingNotifications()
		
		if moveAlbumsClipboard != nil {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(didObserve(_:)),
				name: Notification.Name.NSManagedObjectContextDidSaveObjectIDs,
				object: managedObjectContext.parent)
		}
	}
	
	
	
}
