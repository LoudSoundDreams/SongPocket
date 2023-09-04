//
//  OrganizeAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

@MainActor
protocol OrganizeAlbumsDelegate: AnyObject {
	func didOrganize()
}

struct WillOrganizeAlbumsStickyNote {
	let prompt: String
	let ids_sourceCollections: Set<NSManagedObjectID>
}

final class OrganizeAlbumsClipboard {
	// Data
	let subjectedAlbums_ids: Set<NSManagedObjectID> // Selected or all albums in source collection
	let sourceCollections_ids: Set<NSManagedObjectID>
	let unmovedAlbums_ids: Set<NSManagedObjectID>
	let collectionsContainingMovedAlbums_ids: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: OrganizeAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			LRString.variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark,
			subjectedAlbums_ids.count - unmovedAlbums_ids.count,
			collectionsContainingMovedAlbums_ids.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		subjectedAlbums_ids: Set<NSManagedObjectID>,
		sourceCollections_ids: Set<NSManagedObjectID>,
		unmovedAlbums_ids: Set<NSManagedObjectID>,
		collectionsContainingMovedAlbums_ids: Set<NSManagedObjectID>,
		delegate: OrganizeAlbumsDelegate
	) {
		self.subjectedAlbums_ids = subjectedAlbums_ids
		self.sourceCollections_ids = sourceCollections_ids
		self.unmovedAlbums_ids = unmovedAlbums_ids
		self.collectionsContainingMovedAlbums_ids = collectionsContainingMovedAlbums_ids
		self.delegate = delegate
	}
}
