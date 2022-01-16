//
//  UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	final func translucentFaint() -> UIColor {
		return withAlphaComponent(0.125)
	}
	
	final func translucent() -> UIColor {
		return withAlphaComponent(0.5)
	}
}
