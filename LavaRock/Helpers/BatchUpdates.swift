//
//  BatchUpdates.swift
//  LavaRock
//
//  Created by h on 2022-05-14.
//

struct BatchUpdates<Identifier> {
	let toDelete: [Identifier]
	let toInsert: [Identifier]
	let toMove: [(Identifier, Identifier)]
}
