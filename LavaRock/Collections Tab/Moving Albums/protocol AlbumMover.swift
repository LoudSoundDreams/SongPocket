//
//  protocol AlbumMover.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import UIKit

protocol AlbumMover {
	var moveAlbumsClipboard: MoveAlbumsClipboard? { get set }
	
	/*
	Also:
	- Observe NSManagedObjectContextDidSaveObjectIDs notifications on the main managed object context.
	*/
}

//extension AlbumMover {
//	
//	override func deleteFromView(_ idsOfAllDeletedObjects: [NSManagedObjectID]) {
//		super.deleteFromView(idsOfAllDeletedObjects)
//		
//		if let moveAlbumsClipboard = moveAlbumsClipboard {
//			for deletedID in idsOfAllDeletedObjects {
//				if moveAlbumsClipboard.idsOfAlbumsBeingMoved.contains(deletedID) {
//					dismiss(animated: true, completion: nil)
//				}
//			}
//		}
//	}
//	
//}
