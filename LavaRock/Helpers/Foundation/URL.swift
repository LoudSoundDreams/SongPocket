//
//  URL.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit

extension URL {
	
	static let music = Self(string: "music://")
	
	func open() {
		UIApplication.shared.open(self)
	}
	
}
