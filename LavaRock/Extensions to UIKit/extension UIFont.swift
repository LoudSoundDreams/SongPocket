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
		let featureSettings: [[UIFontDescriptor.FeatureKey: Int]] = [
			[.type: kNumberSpacingType,
			 .selector: kMonospacedNumbersSelector]
		]
		let attributes = [UIFontDescriptor.AttributeName.featureSettings: featureSettings]
		let monospacedNumbersBodyFontDescriptor = bodyFontDescriptor.addingAttributes(attributes)
		return UIFont(descriptor: monospacedNumbersBodyFontDescriptor, size: 0)
	}()
	
}
