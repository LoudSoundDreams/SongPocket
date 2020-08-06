//
//  extension UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	
	func deselectAllRows(animated: Bool) {
		guard let indexPaths = indexPathsForSelectedRows else { return }
		for indexPath in indexPaths {
			deselectRow(at: indexPath, animated: animated) // As of iOS 14.0 beta 4, this doesn't animate for some reason. It works right on iOS 13.5.1.
		}
	}
	
}
