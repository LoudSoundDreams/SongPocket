//
//  AlbumMoverClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

final class AlbumMoverClipboard { // This is a class, not a struct, because we use it to share information.
	
	// MARK: - Properties
	
	// "Constants"
	let idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
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
	weak var abortDelegate: AlbumMoverAbortDelegate?
	
	// Variables
	var isMakingNewCollection = false // If we have to refresh to reflect changes in the Apple Music library, we'll cancel making the new collection, (then dismiss the "move albums" sheet).
	var didAlreadyMakeNewCollection = false
	var didAlreadyCommitMoveAlbums = false
	
	// MARK: - Methods
	
	init(
		idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID,
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		idsOfAlbumsNotBeingMoved: [NSManagedObjectID],
		abortDelegate: AlbumMoverAbortDelegate?
	) {
		self.idOfCollectionThatAlbumsAreBeingMovedOutOf = idOfCollectionThatAlbumsAreBeingMovedOutOf
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		self.idsOfAlbumsNotBeingMoved = idsOfAlbumsNotBeingMoved
		self.abortDelegate = abortDelegate
	}
	
}
