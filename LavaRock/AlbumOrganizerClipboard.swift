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
	let idsOfNewCollections: Set<NSManagedObjectID>
	
	// Helpers
	weak var delegate: AlbumOrganizerDelegate? = nil
	var prompt: String {
		let formatString = LocalizedString.formatOrganizeAlbumsPrompt
		let numberOfAlbums = idsOfOrganizedAlbums.count
		let numberOfNewCollections = idsOfNewCollections.count
		return String.localizedStringWithFormat(
			formatString,
			numberOfAlbums, numberOfNewCollections)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		idsOfOrganizedAlbums: [NSManagedObjectID],
		context: NSManagedObjectContext,
		delegate: AlbumOrganizerDelegate
	) {
		self.idsOfOrganizedAlbums = idsOfOrganizedAlbums
		let organizedAlbums = idsOfOrganizedAlbums.map {
			context.object(with: $0) as! Album
		}
		idsOfNewCollections = Set(organizedAlbums.map { $0.container!.objectID })
		self.delegate = delegate
	}
	
}
