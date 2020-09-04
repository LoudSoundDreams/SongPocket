//
//  protocol AlbumMover.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import UIKit
import CoreData

protocol AlbumMover {
	var moveAlbumsClipboard: MoveAlbumsClipboard? { get set }
	
	func beginObservingParentManagedObjectContextNotifications()
	func deleteFromViewWhileMovingAlbums(_ idsOfAllDeletedObjects: [NSManagedObjectID])
}
