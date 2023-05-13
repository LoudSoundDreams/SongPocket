//
//  MoveAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

@MainActor
protocol MoveAlbumsDelegate: AnyObject {
	func didMove()
}

final class MoveAlbumsClipboard { // This is a class and not a struct because we use it to share information.
	// Data
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsBeingMovedAsSet: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	private(set) weak var delegate: MoveAlbumsDelegate? = nil
	var prompt: String {
		return String.localizedStringWithFormat(
			LRString.variable_chooseACollectionToMoveXAlbumsTo,
			idsOfAlbumsBeingMovedAsSet.count)
	}
	
	init(
		albumsBeingMoved: [Album],
		delegate: MoveAlbumsDelegate
	) {
		idsOfAlbumsBeingMoved = albumsBeingMoved.map { $0.objectID }
		idsOfAlbumsBeingMovedAsSet = Set(idsOfAlbumsBeingMoved)
		idsOfSourceCollections = Set(albumsBeingMoved.map { $0.container!.objectID })
		self.delegate = delegate
	}
}
