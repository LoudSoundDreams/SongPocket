//
//  extension Collection.swift
//  LavaRock
//
//  Created by h on 2020-12-17.
//

import CoreData

extension Collection {
	
	static func validatedTitle(from rawProposedTitle: String?) -> String {
		let unwrappedProposedTitle = rawProposedTitle ?? ""
		if unwrappedProposedTitle == "" {
			return LocalizedString.defaultCollectionTitle
		} else {
			let trimmedTitle = unwrappedProposedTitle.prefix(255) // In case the user pastes a dangerous amount of text
			if trimmedTitle != unwrappedProposedTitle {
				return trimmedTitle + "…" // Does this need to be localized?
			} else {
				return String(trimmedTitle)
			}
		}
	}
	
}
