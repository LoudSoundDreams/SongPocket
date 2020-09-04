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
