//
//  extension UIAlertAction.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIAlertAction {
	
	static func cancel(
		handler: ((UIAlertAction) -> Void)?
	) -> UIAlertAction {
		UIAlertAction(
			title: LocalizedString.cancel,
			style: .cancel,
			handler: handler)
	}
	
}
