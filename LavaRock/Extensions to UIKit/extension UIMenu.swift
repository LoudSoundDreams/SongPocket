//
//  extension UIMenu.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIMenu {
	
	convenience init(
		presentsUpward: Bool, // As of iOS 14.7 beta 2, when you present a UIMenu from lower down on the screen, the UIMenu shows its children from the bottom upward. Call this with `presentUpward: true` to reverse all the actions.
		actionGroups: [[UIAction]]
	) {
		let actionGroupsReordered: [[UIAction]] = {
			if presentsUpward {
				var subactionsCopy = actionGroups
				subactionsCopy.reverse()
				for indexOfSubactionGroup in subactionsCopy.indices {
					subactionsCopy[indexOfSubactionGroup].reverse()
				}
				return subactionsCopy
			} else {
				return actionGroups
			}
		}()
		
		let submenus = actionGroupsReordered.map { actionGroup in
			UIMenu(
				options: .displayInline,
				children: actionGroup)
		}
		
		self.init(children: submenus)
	}
	
}
