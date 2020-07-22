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
	
	// "Constants" for "move albums" mode
	var moveAlbumsModePrompt: String?
	var managedObjectIDsOfAlbumsBeingMoved = [NSManagedObjectID]()
	var managedObjectIDsOfAlbumsNotBeingMoved = [NSManagedObjectID]()
	
	// Variables
	var didMoveAlbumsToNewCollections = false
	
	// Methods
	func setMoveAlbumsModePrompt() {
		let number = managedObjectIDsOfAlbumsBeingMoved.count
		if number == 1 {
			moveAlbumsModePrompt = "Chooose a collection to move 1 album to."
		} else {
			moveAlbumsModePrompt = "Choose a collection to move \(number) albums to."
		}
	}
	
}
