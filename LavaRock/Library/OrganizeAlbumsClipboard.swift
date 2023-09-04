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
	let prompt: String
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		subjectedAlbums_ids: Set<NSManagedObjectID>,
		destinationCollections_ids: Set<NSManagedObjectID>,
		prompt: String
	) {
		self.subjectedAlbums_ids = subjectedAlbums_ids
		self.destinationCollections_ids = destinationCollections_ids
		self.prompt = prompt
	}
}
