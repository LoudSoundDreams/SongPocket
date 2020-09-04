//
//  MoveAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

final class MoveAlbumsClipboard { // This is a class, not a struct, because we use it to share information.
	
	// MARK: - Properties
	
	let idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID
	var idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsNotBeingMoved: [NSManagedObjectID]
	var navigationItemPrompt: String {
		let number = idsOfAlbumsBeingMoved.count
		switch number {
		case 1:
			return "Choose a collection to move 1 album to."
		default:
			return "Choose a collection to move \(number) albums to."
		}
	}
	
	// MARK: - Methods
	
	init(
		idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID,
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		idsOfAlbumsNotBeingMoved: [NSManagedObjectID]
	) {
		self.idOfCollectionThatAlbumsAreBeingMovedOutOf = idOfCollectionThatAlbumsAreBeingMovedOutOf
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		self.idsOfAlbumsNotBeingMoved = idsOfAlbumsNotBeingMoved
	}
	
}
