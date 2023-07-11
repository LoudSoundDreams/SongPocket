//
//  UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	@MainActor
	final func resolvedForIncreaseContrast() -> UIColor {
		let view = UIView()
		view.tintColor = self
		return view.tintColor
	}
}
