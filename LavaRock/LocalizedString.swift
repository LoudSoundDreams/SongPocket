//
//  LocalizedString.swift
//  LavaRock
//
//  Created by h on 2020-12-05.
//

import Foundation

// Putting all the keys we pass to NSLocalizedString in one place (here) helps keep them unique, which we need to do to ensure predictable behavior.
final class LocalizedString { // You can't make this an enum, because associated values for enum cases need to be literals.
	
	// Don't pass arguments to the Foundation function NSLocalizedString, because when you choose Editor -> Export for Localization…, Xcode won't include those calls.
	
	// MARK: - Strings Without Variables
	
	// MARK: Options
	
	static var accentColor: String {
		NSLocalizedString(
			"Accent Color",
			comment: "Options heading")
	}
	
	static var strawberry: String {
		NSLocalizedString(
			"Strawberry",
			comment: "Accent color")
	}
	
	static var tangerine: String {
		NSLocalizedString(
			"Tangerine",
			comment: "Accent color")
	}
	
	static var lime: String {
		NSLocalizedString(
			"Lime",
			comment: "Accent color")
	}
	
	static var blueberry: String {
		NSLocalizedString(
			"Blueberry",
			comment: "Accent color")
	}
	
	static var grape: String {
		NSLocalizedString(
			"Grape",
			comment: "Accent color")
	}
	
	// MARK: - Strings With Variables (Format Strings)
	
	// MARK: Strings Without Text Variations
	
	
	
	// MARK: Strings With Text Variations (String Dictionaries)
	
	
	
}
