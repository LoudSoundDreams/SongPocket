//
//  UIFont.swift
//  LavaRock
//
//  Created by h on 2020-12-19.
//

import UIKit

extension UIFont {
	static func monospacedDigitSystemFont(forTextStyle style: TextStyle) -> UIFont {
		return .monospacedDigitSystemFont(
			ofSize: UIFont.preferredFont(forTextStyle: style).pointSize,
			weight: .regular)
	}
}
