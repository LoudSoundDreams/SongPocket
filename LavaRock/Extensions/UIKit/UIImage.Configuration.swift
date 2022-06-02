//
//  UIImage.Configuration.swift
//  LavaRock
//
//  Created by h on 2021-12-13.
//

import UIKit

extension UIImage.Configuration {
	typealias SymbolConfig = UIImage.SymbolConfiguration
	
	static var bodySmall: SymbolConfig {
		SymbolConfig(font: .preferredFont(forTextStyle: .body), scale: .small)
	}
	
	static var hierarchical: SymbolConfig {
		return SymbolConfig(hierarchicalColor: .tintColor)
	}
}
