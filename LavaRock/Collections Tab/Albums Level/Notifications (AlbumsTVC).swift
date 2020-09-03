//
//  Notifications (AlbumsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// Remember: we might be in "moving albums" mode.
	
	// This is the same as in CollectionsTVC. Move it to the AlbumMover protocol?
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
