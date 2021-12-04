//
//  AlbumOrganizerClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

protocol AlbumOrganizerDelegate: AnyObject {
	func didCommitOrganizeThenDismiss()
}

final class AlbumOrganizerClipboard {
	
	// Data
	let idsOfOrganizedAlbums: [NSManagedObjectID]
	let idsOfDestinationCollections: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID> // Is empty if organizing would delete the source `Collection`.
	
	// Helpers
	weak var delegate: AlbumOrganizerDelegate? = nil
	var prompt: String {
		let formatString = LocalizedString.format_organizeXAlbumsByAlbumArtistQuestionMark
		let numberOfAlbums = idsOfOrganizedAlbums.count
		return String.localizedStringWithFormat(
			formatString,
			numberOfAlbums)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		idsOfOrganizedAlbums: [NSManagedObjectID],
		idsOfSourceCollections: Set<NSManagedObjectID>,
		contextPreviewingChanges: NSManagedObjectContext,
		delegate: AlbumOrganizerDelegate
	) {
		self.idsOfOrganizedAlbums = idsOfOrganizedAlbums
		self.idsOfSourceCollections = idsOfSourceCollections
		let organizedAlbums = idsOfOrganizedAlbums.map {
			contextPreviewingChanges.object(with: $0) as! Album
		}
		idsOfDestinationCollections = Set(organizedAlbums.map { $0.container!.objectID })
		self.delegate = delegate
	}
	
}
