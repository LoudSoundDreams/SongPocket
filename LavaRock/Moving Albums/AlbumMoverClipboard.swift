//
//  AlbumMoverClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

final class AlbumMoverClipboard { // This is a class and not a struct because we use it to share information.
	
	// MARK: - Properties
	
	// Constants
	let ifOfSourceCollection: NSManagedObjectID
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsNotBeingMoved: [NSManagedObjectID]
	static let indexOfNewCollection = 0
	
	// "Constants"
	var navigationItemPrompt: String {
		let formatString = LocalizedString.formatChooseACollectionPrompt
		let number = idsOfAlbumsBeingMoved.count
		return String.localizedStringWithFormat(
			formatString,
			number)
	}
	weak var delegate: AlbumMoverDelegate?
	
	// Variables
	var didAlreadyMakeNewCollection = false
	var didAlreadyCommitMoveAlbums = false
	
	// MARK: - Methods
	
	init(
		idOfSourceCollection: NSManagedObjectID,
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		idsOfAlbumsNotBeingMoved: [NSManagedObjectID],
		delegate: AlbumMoverDelegate?
	) {
		self.ifOfSourceCollection = idOfSourceCollection
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		self.idsOfAlbumsNotBeingMoved = idsOfAlbumsNotBeingMoved
		self.delegate = delegate
	}
	
}
