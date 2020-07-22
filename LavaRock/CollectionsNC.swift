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
	
	// MARK: Managing Saved Data
	
	// "Constants"
	let coreDataManager = CoreDataManager()
	
	// MARK: Moving Albums
	
	// "Constants"
	var isInMoveAlbumsMode = false
	var moveAlbumsModePrompt: String? {
		let number = managedObjectIDsOfAlbumsBeingMoved.count
		switch number {
		case 0:
			return nil
		case 1:
			return "Chooose a collection to move 1 album to."
		default:
			return "Choose a collection to move \(number) albums to."
		}
	}
	var managedObjectIDsOfAlbumsBeingMoved = [NSManagedObjectID]()
	var managedObjectIDsOfAlbumsNotBeingMoved = [NSManagedObjectID]()
	
	// Variables
	var didMoveAlbumsToNewCollections = false
	
}
