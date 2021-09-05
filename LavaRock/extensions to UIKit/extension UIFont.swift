//
//  extension UIFont.swift
//  LavaRock
//
//  Created by h on 2020-12-19.
//

import UIKit

extension UIFont {
	
	static let bodyWithMonospacedNumbers: UIFont = {
		let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
		let featureSettings: [[UIFontDescriptor.FeatureKey: Int]] = {
			// Xcode 13
			if #available(iOS 15, *) {
				return [
					[.type: kNumberSpacingType,
					 .selector: kMonospacedNumbersSelector]
				]
			} else {
				return [
					[.featureIdentifier: kNumberSpacingType,
					 .typeIdentifier: kMonospacedNumbersSelector]
				]
			}
			
			// Xcode 12
//			return [
//				[.featureIdentifier: kNumberSpacingType,
//				 .typeIdentifier: kMonospacedNumbersSelector]
//			]
		}()
		let attributes = [UIFontDescriptor.AttributeName.featureSettings: featureSettings]
		let monospacedNumbersBodyFontDescriptor = bodyFontDescriptor.addingAttributes(attributes)
		return UIFont(descriptor: monospacedNumbersBodyFontDescriptor, size: 0)
	}()
	
}
