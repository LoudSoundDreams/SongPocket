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
	let ids_subjectedAlbums: Set<NSManagedObjectID> // Selected or all albums in source collection
	let ids_sourceCollections: Set<NSManagedObjectID>
	let ids_unmovedAlbums: Set<NSManagedObjectID>
	let ids_collectionsContainingMovedAlbums: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: OrganizeAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			LRString.variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark,
			ids_subjectedAlbums.count - ids_unmovedAlbums.count,
			ids_collectionsContainingMovedAlbums.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		ids_subjectedAlbums: Set<NSManagedObjectID>,
		ids_sourceCollections: Set<NSManagedObjectID>,
		ids_unmovedAlbums: Set<NSManagedObjectID>,
		ids_collectionsContainingMovedAlbums: Set<NSManagedObjectID>,
		delegate: OrganizeAlbumsDelegate
	) {
		self.ids_subjectedAlbums = ids_subjectedAlbums
		self.ids_sourceCollections = ids_sourceCollections
		self.ids_unmovedAlbums = ids_unmovedAlbums
		self.ids_collectionsContainingMovedAlbums = ids_collectionsContainingMovedAlbums
		self.delegate = delegate
	}
}
