//
//  MoveAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

final class MoveAlbumsClipboard { // This is a class, not a struct, because we use it to share information.
	
	// MARK: Properties
	
	let idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsNotBeingMoved: [NSManagedObjectID]
	
	// MARK: Methods
	
	init(
		idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID,
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		idsOfAlbumsNotBeingMoved: [NSManagedObjectID]
	) {
		self.idOfCollectionThatAlbumsAreBeingMovedOutOf = idOfCollectionThatAlbumsAreBeingMovedOutOf
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		self.idsOfAlbumsNotBeingMoved = idsOfAlbumsNotBeingMoved
	}
	
	static func moveAlbumsModePrompt(numberOfAlbumsBeingMoved: Int) -> String {
		switch numberOfAlbumsBeingMoved {
		case 1:
			return "Chooose a collection to move 1 album to."
		default:
			return "Choose a collection to move \(numberOfAlbumsBeingMoved) albums to."
		}
	}
	
}
