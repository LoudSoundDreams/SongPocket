//
//  OrganizeAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

protocol OrganizeAlbumsDelegate: AnyObject {
	func didOrganize()
}

struct WillOrganizeAlbumsStickyNote {
	let prompt: String
	let idsOfSourceCollections: Set<NSManagedObjectID>
}

final class OrganizeAlbumsClipboard {
	// Data
	let idsOfSourceCollections: Set<NSManagedObjectID>
	let idsOfUnmovedAlbums: Set<NSManagedObjectID>
	let idsOfMovedAlbums: Set<NSManagedObjectID>
	let idsOfCollectionsContainingMovedAlbums: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: OrganizeAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			Enabling.multicollection
			? LocalizedString.format_organizeIntoXSectionsByAlbumArtistQuestionMark
			: LocalizedString.format_organizeIntoXCollectionsByAlbumArtistQuestionMark,
			idsOfCollectionsContainingMovedAlbums.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		idsOfSourceCollections: Set<NSManagedObjectID>,
		idsOfUnmovedAlbums: Set<NSManagedObjectID>,
		idsOfMovedAlbums: Set<NSManagedObjectID>,
		idsOfCollectionsContainingMovedAlbums: Set<NSManagedObjectID>,
		delegate: OrganizeAlbumsDelegate
	) {
		self.idsOfSourceCollections = idsOfSourceCollections
		self.idsOfUnmovedAlbums = idsOfUnmovedAlbums
		self.idsOfMovedAlbums = idsOfMovedAlbums
		self.idsOfCollectionsContainingMovedAlbums = idsOfCollectionsContainingMovedAlbums
		self.delegate = delegate
	}
}
