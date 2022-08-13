//
//  UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	final func printHSBA() {
		var mutableHue: CGFloat = .zero
		var mutableSaturation: CGFloat = .zero
		var mutableBrightness: CGFloat = .zero
		var mutableAlpha: CGFloat = .zero
		getHue(
			&mutableHue,
			saturation: &mutableSaturation,
			brightness: &mutableBrightness,
			alpha: &mutableAlpha)
		print("H:", mutableHue)
		print("S:", mutableSaturation)
		print("B:", mutableBrightness)
		print("A:", mutableAlpha)
	}
	
	final func printRGBA() {
		var mutableRed: CGFloat = .zero
		var mutableGreen: CGFloat = .zero
		var mutableBlue: CGFloat = .zero
		var mutableAlpha: CGFloat = .zero
		getRed(
			&mutableRed,
			green: &mutableGreen,
			blue: &mutableBlue,
			alpha: &mutableAlpha)
		print("R:", mutableRed)
		print("G:", mutableGreen)
		print("B:", mutableBlue)
		print("A:", mutableAlpha)
	}
	
	final func translucentFaint() -> UIColor {
		return withAlphaComponent(.oneEighth)
	}
	
	final func translucent() -> UIColor {
		return withAlphaComponent(.oneHalf)
	}
}
