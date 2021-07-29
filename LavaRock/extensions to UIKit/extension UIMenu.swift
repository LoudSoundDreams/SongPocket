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
				var actionGroupsCopy = actionGroups
				actionGroupsCopy.reverse()
				actionGroupsCopy.indices.forEach {
					actionGroupsCopy[$0].reverse()
				}
				return actionGroupsCopy
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
