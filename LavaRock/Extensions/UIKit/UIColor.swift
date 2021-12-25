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
	
	/*
	final func lessVibrant(
		for userInterfaceStyle: UIUserInterfaceStyle
	) -> UIColor {
		var mutableHue: CGFloat = 0
		var mutableSaturation: CGFloat = 0
		var mutableBrightness: CGFloat = 0
		var mutableAlpha: CGFloat = 0
		guard getHue(
			&mutableHue,
			saturation: &mutableSaturation,
			brightness: &mutableBrightness,
			alpha: &mutableAlpha
		) else {
			return self
		}
		switch userInterfaceStyle {
		case .unspecified:
			break
		case .light:
//			mutableSaturation *= 1/2 // same as opacity 1/2
//			mutableBrightness *= 1/2 // dark
//			mutableBrightness *= 2 // garish and computery
			break
		case .dark:
//			mutableSaturation *= 1/2 // blue -> baby blue
//			mutableBrightness *= 1/2 // same as opacity 1/2
			break
		@unknown default:
			break
		}
		return UIColor(
			hue: mutableHue,
			saturation: mutableSaturation,
			brightness: mutableBrightness,
			alpha: mutableAlpha)
	}
	*/
	
}
