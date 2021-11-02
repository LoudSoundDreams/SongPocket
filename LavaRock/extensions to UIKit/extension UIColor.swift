//
//  extension UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	
	static func tintColor_compatibleWithiOS14(_ view: UIView) -> UIColor {
		if #available(iOS 15, *) {
			return .tintColor
		} else {
			return view.tintColor
		}
	}
	
}
