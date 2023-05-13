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
	let idsOfSourceFolders: Set<NSManagedObjectID>
}

final class OrganizeAlbumsClipboard {
	// Data
	let idsOfSubjectedAlbums: Set<NSManagedObjectID>
	let idsOfSourceFolders: Set<NSManagedObjectID>
	let idsOfUnmovedAlbums: Set<NSManagedObjectID>
	let idsOfFoldersContainingMovedAlbums: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: OrganizeAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			LRString.variable_moveXAlbumsToYFoldersByAlbumArtistQuestionMark,
			idsOfSubjectedAlbums.count - idsOfUnmovedAlbums.count,
			idsOfFoldersContainingMovedAlbums.count)
	}
	
	// State
	var didAlreadyCommitOrganize = false
	
	init(
		idsOfSubjectedAlbums: Set<NSManagedObjectID>,
		idsOfSourceFolders: Set<NSManagedObjectID>,
		idsOfUnmovedAlbums: Set<NSManagedObjectID>,
		idsOfFoldersContainingMovedAlbums: Set<NSManagedObjectID>,
		delegate: OrganizeAlbumsDelegate
	) {
		self.idsOfSubjectedAlbums = idsOfSubjectedAlbums
		self.idsOfSourceFolders = idsOfSourceFolders
		self.idsOfUnmovedAlbums = idsOfUnmovedAlbums
		self.idsOfFoldersContainingMovedAlbums = idsOfFoldersContainingMovedAlbums
		self.delegate = delegate
	}
}
