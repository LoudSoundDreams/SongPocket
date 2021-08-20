//
//  extension UIMenu.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIMenu {
	
	convenience init(
		presentsUpward: Bool, // As of iOS 14.7 developer beta 2, when you present a UIMenu from lower down on the screen, the UIMenu shows its children from the bottom upward. Call this with `presentUpward: true` to reverse all the actions.
		groupedChildren: [[UIAction]]
	) {
		let groupedChildrenReordered: [[UIAction]] = {
			if presentsUpward {
				var groupedChildrenCopy = groupedChildren
				groupedChildrenCopy.reverse()
				groupedChildrenCopy.indices.forEach {
					groupedChildrenCopy[$0].reverse()
				}
				return groupedChildrenCopy
			} else {
				return groupedChildren
			}
		}()
		
		let submenus = groupedChildrenReordered.map { groupOfChildren in
			UIMenu(
				options: .displayInline,
				children: groupOfChildren)
		}
		
		self.init(children: submenus)
	}
	
}
