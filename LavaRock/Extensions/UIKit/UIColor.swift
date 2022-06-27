//
//  UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	final func translucentFaint() -> UIColor {
		return withAlphaComponent(.oneEighth)
	}
	
	final func translucent() -> UIColor {
		return withAlphaComponent(.oneHalf)
	}
}
