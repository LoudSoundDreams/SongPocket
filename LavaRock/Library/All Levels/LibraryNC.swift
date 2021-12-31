//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	static let identifier = "Library NC"
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Until `viewDidAppear`, `view.window == nil`.
		view.window?.overrideUserInterfaceStyle = Appearance.savedPreference().uiUserInterfaceStyle()
		view.window?.tintColor = AccentColor.savedPreference().uiColor
	}
}
