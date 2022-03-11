//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	private static var didMoveThemeToWindow = false
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Until `viewDidAppear`, `view.window == nil`.
		if !Self.didMoveThemeToWindow {
			Self.didMoveThemeToWindow = true
			
			view.window?.overrideUserInterfaceStyle = view.overrideUserInterfaceStyle
			view.overrideUserInterfaceStyle = .unspecified
			
			view.window?.tintColor = view.tintColor
			view.tintColor = nil // TO DO: Applies “Increase Contrast” twice.
		}
	}
}
