//
//  UIView.swift
//  LavaRock
//
//  Created by h on 2022-06-01.
//

import UIKit

extension UIView {
	final func addSubview(
		_ subview: UIView,
		activating constraints: [NSLayoutConstraint]
	) {
		addSubview(subview)
		subview.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate(constraints)
	}
}
