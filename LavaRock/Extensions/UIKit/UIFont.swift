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
		let bodyFont = UIFont.preferredFont(
			forTextStyle: .body,
			compatibleWith: traitCollection)
		return .monospacedDigitSystemFont(
			ofSize: bodyFont.pointSize,
			weight: .regular)
	}
}
