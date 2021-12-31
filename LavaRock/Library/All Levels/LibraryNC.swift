//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	static let identifier = "Library NC"
	
	private static var didSetTheme = false
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Until `viewDidAppear`, `view.window == nil`.
		if !Self.didSetTheme {
			Self.didSetTheme = true
			view.window?.overrideUserInterfaceStyle = Appearance.savedPreference().uiUserInterfaceStyle()
			view.window?.tintColor = AccentColor.savedPreference().uiColor
		}
	}
}
