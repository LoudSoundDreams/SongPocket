//
//  MoveAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

protocol MoveAlbumsDelegate: AnyObject {
	func didMoveThenDismiss()
}

final class MoveAlbumsClipboard { // This is a class and not a struct because we use it to share information.
	
	// Data
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsBeingMoved_asSet: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: MoveAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			FeatureFlag.multicollection ? LocalizedString.format_chooseASectiontoMoveXAlbumsTo : LocalizedString.format_chooseACollectionToMoveXAlbumsTo,
			idsOfAlbumsBeingMoved.count)
	}
	
	// State
	var didAlreadyCreate = false
	var didAlreadyCommitMove = false
	
	init(
		albumsBeingMoved: [Album],
		delegate: MoveAlbumsDelegate
	) {
		idsOfAlbumsBeingMoved = albumsBeingMoved.map { $0.objectID }
		idsOfAlbumsBeingMoved_asSet = Set(idsOfAlbumsBeingMoved)
		idsOfSourceCollections = Set(albumsBeingMoved.map { $0.container!.objectID })
		self.delegate = delegate
	}
	
}
