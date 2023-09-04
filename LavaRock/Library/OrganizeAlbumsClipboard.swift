//
//  OrganizeAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

struct WillOrganizeAlbumsStickyNote {
	let prompt: String
	let sourceCollections_ids: Set<NSManagedObjectID>
}

final class OrganizeAlbumsClipboard {
	// Data
	let subjectedAlbums_ids: Set<NSManagedObjectID> // Selected or all albums in source collection
	let sourceCollections_ids: Set<NSManagedObjectID>
	let unmovedAlbums_ids: Set<NSManagedObjectID>
	let containingMoved_ids: Set<NSManagedObjectID>
	
	// Helpers
	var prompt: String {
		return String.localizedStringWithFormat(
			LRString.variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark,
			subjectedAlbums_ids.count - unmovedAlbums_ids.count,
			containingMoved_ids.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		subjectedAlbums_ids: Set<NSManagedObjectID>,
		sourceCollections_ids: Set<NSManagedObjectID>,
		unmovedAlbums_ids: Set<NSManagedObjectID>,
		containingMoved_ids: Set<NSManagedObjectID>
	) {
		self.subjectedAlbums_ids = subjectedAlbums_ids
		self.sourceCollections_ids = sourceCollections_ids
		self.unmovedAlbums_ids = unmovedAlbums_ids
		self.containingMoved_ids = containingMoved_ids
	}
}
