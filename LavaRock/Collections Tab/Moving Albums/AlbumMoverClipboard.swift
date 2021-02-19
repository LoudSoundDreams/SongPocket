//
//  AlbumMoverClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

final class AlbumMoverClipboard { // This is a class and not a struct because we use it to share information.
	
	// MARK: - Properties
	
	// "Constants"
	let idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsNotBeingMoved: [NSManagedObjectID]
	var navigationItemPrompt: String {
		let formatString = LocalizedString.formatChooseACollectionPrompt
		let number = idsOfAlbumsBeingMoved.count
		return String.localizedStringWithFormat(formatString, number)
	}
	weak var delegate: AlbumMoverDelegate?
	
	// Variables
	var didAlreadyMakeNewCollection = false
	var didAlreadyCommitMoveAlbums = false
	
	// MARK: - Methods
	
	init(
		idOfCollectionThatAlbumsAreBeingMovedOutOf: NSManagedObjectID,
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		idsOfAlbumsNotBeingMoved: [NSManagedObjectID],
		delegate: AlbumMoverDelegate?
	) {
		self.idOfCollectionThatAlbumsAreBeingMovedOutOf = idOfCollectionThatAlbumsAreBeingMovedOutOf
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		self.idsOfAlbumsNotBeingMoved = idsOfAlbumsNotBeingMoved
		self.delegate = delegate
	}
	
}
