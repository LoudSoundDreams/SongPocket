//
//  OrganizeAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

protocol OrganizeAlbumsDelegate: AnyObject {
	func didSaveOrganizeThenDismiss()
}

final class OrganizeAlbumsClipboard {
	
	// Data
	let idsOfMovedAlbums: Set<NSManagedObjectID>
	let idsOfDestinationCollections: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	weak var delegate: OrganizeAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			LocalizedString.format_organizeIntoXCollectionsByAlbumArtistQuestionMark,
			idsOfDestinationCollections.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		idsOfMovedAlbums: Set<NSManagedObjectID>,
		idsOfSourceCollections: Set<NSManagedObjectID>,
		contextPreviewingChanges: NSManagedObjectContext,
		delegate: OrganizeAlbumsDelegate
	) {
		self.idsOfMovedAlbums = idsOfMovedAlbums
		
		self.idsOfSourceCollections = idsOfSourceCollections
		
		let movedAlbums = idsOfMovedAlbums.map {
			contextPreviewingChanges.object(with: $0) as! Album
		}
		idsOfDestinationCollections = Set(movedAlbums.map { $0.container!.objectID })
		
		self.delegate = delegate
	}
	
}
