//
//  LRTableCell.swift
//  LavaRock
//
//  Created by h on 2021-12-03.
//

import UIKit

class LRTableCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		refreshSelectedBackgroundView()
	}
	
	private func refreshSelectedBackgroundView() {
		let colorView = UIView()
		
//		let accentColor = UIColor.tintColor_()
//		let adjustedAccentColor: UIColor
//		var mutableHue: CGFloat = 0
//		var mutableSaturation: CGFloat = 0
//		var mutableBrightness: CGFloat = 0
//		var mutableAlpha: CGFloat = 0
//		if accentColor.getHue(
//			&mutableHue,
//			saturation: &mutableSaturation,
//			brightness: &mutableBrightness,
//			alpha: &mutableAlpha
//		) {
//			switch traitCollection.userInterfaceStyle {
//			case .unspecified:
//				mutableBrightness *= 2 // Does `.unspecified` mean the system appearance? How do we figure out whether it's actually light or dark?
//			case .light:
//				mutableBrightness *= 2
//			case .dark:
//				mutableBrightness *= 1/2
//			@unknown default:
//				break
//			}
//
//			adjustedAccentColor = UIColor(
//				hue: mutableHue,
//				saturation: mutableSaturation,
//				brightness: mutableBrightness,
//				alpha: mutableAlpha)
//		} else {
//			adjustedAccentColor = accentColor
//		}
//		colorView.backgroundColor = adjustedAccentColor
		
		colorView.backgroundColor = .tintColor_().translucentVibrant()
		selectedBackgroundView = colorView
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
			refreshSelectedBackgroundView()
		}
	}
}

