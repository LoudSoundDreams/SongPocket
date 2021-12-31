//
//  UIMenu.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit

extension UIMenu {
	convenience init(
		presentsUpward: Bool, // As of iOS 14.7 developer beta 2, when you present a `UIMenu` from lower down on the screen, the `UIMenu` shows its children from the bottom upward. Call this with `presentUpward: true` to reverse all the actions.
		groupedElements: [[UIMenuElement]]
	) {
		let groupedElementsReordered: [[UIMenuElement]] = {
			if presentsUpward {
				var groupedElements = groupedElements
				groupedElements.reverse()
				groupedElements.indices.forEach {
					groupedElements[$0].reverse()
				}
				return groupedElements
			} else {
				return groupedElements
			}
		}()
		
		let submenus = groupedElementsReordered.map { groupOfElements in
			UIMenu(
				options: .displayInline,
				children: groupOfElements)
		}
		
		self.init(children: submenus)
	}
}
