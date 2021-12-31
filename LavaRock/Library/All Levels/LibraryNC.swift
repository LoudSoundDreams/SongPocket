//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	static let identifier = "Library NC"
	
	private static var didStartSettingTheme = false
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if !Self.didStartSettingTheme {
			Self.didStartSettingTheme = true
			view.overrideUserInterfaceStyle = Appearance.savedPreference().uiUserInterfaceStyle()
			view.tintColor = AccentColor.savedPreference().uiColor
		}
	}
	
	private static var didFinishSettingTheme = false
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Until `viewDidAppear`, `view.window == nil`.
		if !Self.didFinishSettingTheme {
			Self.didFinishSettingTheme = true
			view.window?.overrideUserInterfaceStyle = view.overrideUserInterfaceStyle
			view.overrideUserInterfaceStyle = .unspecified
			view.window?.tintColor = view.tintColor
			view.tintColor = nil
		}
	}
}
