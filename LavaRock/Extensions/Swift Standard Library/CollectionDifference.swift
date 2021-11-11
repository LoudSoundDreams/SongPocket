//
//  CollectionDifference.swift
//  LavaRock
//
//  Created by h on 2021-11-04.
//

extension CollectionDifference {
	
	func indicesOfDeletesInsertsAndMoves(
	) -> (
		deletes: [Int],
		inserts: [Int],
		moves: [(Int, Int)]
	) {
		var indicesOfOldItemsToDelete = [Int]()
		var indicesOfNewItemsToInsert = [Int]()
		var indicesOfItemsToMove = [(oldIndex: Int, newIndex: Int)]()
		
		forEach { change in
			// If a `Change`'s `associatedWith:` value is non-nil, then it has a counterpart `Change` in the `CollectionDifference`, and the two `Change`s together represent a move, rather than a remove and an insert.
			switch change {
			case .remove(let offset, _, let associatedOffset):
				if let associatedOffset = associatedOffset {
					indicesOfItemsToMove.append(
						(oldIndex: offset,
						 newIndex: associatedOffset)
					)
				} else {
					indicesOfOldItemsToDelete.append(offset)
				}
			case .insert(let offset, _, let associatedOffset):
				if associatedOffset == nil {
					indicesOfNewItemsToInsert.append(offset)
				}
			}
		}
		
		return (
			indicesOfOldItemsToDelete,
			indicesOfNewItemsToInsert,
			indicesOfItemsToMove
		)
	}
	
}
