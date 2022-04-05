//
//  UIFont.swift
//  LavaRock
//
//  Created by h on 2020-12-19.
//

import UIKit

extension UIFont {
	static func bodyWithMonospacedDigits(
		compatibleWith traitCollection: UITraitCollection?
	) -> UIFont {
		return .monospacedDigitSystemFont(
			ofSize:
				UIFont.preferredFont(
					forTextStyle: .body,
					compatibleWith: traitCollection)
				.pointSize,
			weight: .regular)
	}
	
	static func caption1WithMonospacedDigits(
		compatibleWith traitCollection: UITraitCollection?
	) -> UIFont {
		return .monospacedDigitSystemFont(
			ofSize:
				UIFont.preferredFont(
					forTextStyle: .caption1,
					compatibleWith: traitCollection)
				.pointSize,
			weight: .regular)
	}
}
