//
//  extension UIFont.swift
//  LavaRock
//
//  Created by h on 2020-12-19.
//

import UIKit

extension UIFont {
	
	static let bodyMonospacedNumbers: UIFont = {
		let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
		let monospacedNumbersBodyFontDescriptor = bodyFontDescriptor.addingAttributes([
			UIFontDescriptor.AttributeName.featureSettings: [[
				UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
				UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
			]]
		])
		return UIFont(descriptor: monospacedNumbersBodyFontDescriptor, size: 0)
	}()
	
}
