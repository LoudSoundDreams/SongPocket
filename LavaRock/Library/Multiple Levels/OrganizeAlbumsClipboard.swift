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
	let idsOfSubjectedAlbums: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	let idsOfUnmovedAlbums: Set<NSManagedObjectID>
	let idsOfCollectionsContainingMovedAlbums: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: OrganizeAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			LocalizedString.format_organizeIntoXCollectionsByAlbumArtistQuestionMark,
			idsOfSubjectedAlbums.count,
			idsOfCollectionsContainingMovedAlbums.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		idsOfSubjectedAlbums: Set<NSManagedObjectID>,
		idsOfSourceCollections: Set<NSManagedObjectID>,
		idsOfUnmovedAlbums: Set<NSManagedObjectID>,
		idsOfCollectionsContainingMovedAlbums: Set<NSManagedObjectID>,
		delegate: OrganizeAlbumsDelegate
	) {
		self.idsOfSubjectedAlbums = idsOfSubjectedAlbums
		self.idsOfSourceCollections = idsOfSourceCollections
		self.idsOfUnmovedAlbums = idsOfUnmovedAlbums
		self.idsOfCollectionsContainingMovedAlbums = idsOfCollectionsContainingMovedAlbums
		self.delegate = delegate
	}
}
