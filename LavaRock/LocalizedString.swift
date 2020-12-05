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
	
	
	
	// MARK: - Strings With Variables (Format Strings)
	
	// MARK: Strings Without Text Variations
	
	
	
	// MARK: Strings With Text Variations (String Dictionaries)
	
	
	
}
