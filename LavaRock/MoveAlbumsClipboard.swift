//
//  MoveAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData

final class MoveAlbumsClipboard {
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsBeingMovedAsSet: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
//	var prompt: String {
//		return String.localizedStringWithFormat(
//			LRString.variable_moveXAlbumsToAnotherCrate,
//			idsOfAlbumsBeingMovedAsSet.count)
//	}
	
	// State
	var hasCreatedNewCollection = false
	
	init(albumsBeingMoved: [Album]) {
		idsOfAlbumsBeingMoved = albumsBeingMoved.map { $0.objectID }
		idsOfAlbumsBeingMovedAsSet = Set(idsOfAlbumsBeingMoved)
		idsOfSourceCollections = Set(albumsBeingMoved.map { $0.container!.objectID })
	}
}
