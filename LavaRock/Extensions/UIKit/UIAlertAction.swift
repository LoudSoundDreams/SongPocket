//
//  UIAlertAction.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIAlertAction {
	static func cancelWithHandler(
		handler: ((UIAlertAction) -> Void)?
	) -> UIAlertAction {
		UIAlertAction(title: LRString.cancel, style: .cancel, handler: handler)
	}
}
