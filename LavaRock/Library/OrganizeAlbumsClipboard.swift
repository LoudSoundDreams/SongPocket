//
//  OrganizeAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2021-11-27.
//

import CoreData

final class OrganizeAlbumsClipboard {
	let subjectedAlbums_ids: Set<NSManagedObjectID> // Selected or all albums in source collection
	let containingMoved_ids: Set<NSManagedObjectID>
	let prompt: String
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		subjectedAlbums_ids: Set<NSManagedObjectID>,
		containingMoved_ids: Set<NSManagedObjectID>,
		prompt: String
	) {
		self.subjectedAlbums_ids = subjectedAlbums_ids
		self.containingMoved_ids = containingMoved_ids
		self.prompt = prompt
	}
}
