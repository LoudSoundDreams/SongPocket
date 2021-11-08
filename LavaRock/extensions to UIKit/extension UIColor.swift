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
	
	static func tintColorTranslucent_compatibleWithiOS14(_ view: UIView) -> UIColor {
		return .tintColor_compatibleWithiOS14(view).withAlphaComponent(1/16)
	}
	
}
