//
//  UIFont.swift
//  LavaRock
//
//  Created by h on 2020-12-19.
//

import UIKit

extension UIFont {
	
	static let bodyWithMonospacedDigits: UIFont = {
		let bodyFont = UIFont.preferredFont(forTextStyle: .body)
		return .monospacedDigitSystemFont(ofSize: bodyFont.pointSize, weight: .regular)
	}()
	
}
