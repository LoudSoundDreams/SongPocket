//
//  CollectionsTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit
import SwiftUI

extension CollectionsTVC {
	// MARK: Library Items
	
	final override func shouldDismissAllViewControllersBeforeFreshenLibraryItems() -> Bool {
		if
			(presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
				|| presentedViewController is UIHostingController<OptionsView>
		{
			return false
		}
		
		return super.shouldDismissAllViewControllersBeforeFreshenLibraryItems()
	}
}
