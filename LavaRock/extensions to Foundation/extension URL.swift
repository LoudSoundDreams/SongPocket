//
//  extension URL.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import Foundation
import UIKit

extension URL {
	
	static let music = Self(string: "music://")
	
	func open() {
		UIApplication.shared.open(self)
	}
	
}
