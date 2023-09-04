//
//  OrganizeAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

final class OrganizeAlbumsClipboard {
	let subjectedAlbums_ids: Set<NSManagedObjectID> // Selected or all albums in source collection
	let destinationCollections_ids: Set<NSManagedObjectID>
	var prompt: String {
		String.localizedStringWithFormat(
			LRString.variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark,
			subjectedAlbums_ids.count,
			destinationCollections_ids.count
		)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		subjectedAlbums_ids: Set<NSManagedObjectID>,
		destinationCollections_ids: Set<NSManagedObjectID>
	) {
		self.subjectedAlbums_ids = subjectedAlbums_ids
		self.destinationCollections_ids = destinationCollections_ids
	}
}
