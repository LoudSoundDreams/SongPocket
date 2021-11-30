//
//  SectionStructure.swift
//  LavaRock
//
//  Created by h on 2021-11-28.
//

struct SectionStructure<
	Identifier: Hashable,
	RowIdentifier: Hashable
> {
	let identifier: Identifier
	let rowIdentifiers: [RowIdentifier]
}

extension SectionStructure: Hashable {
}
