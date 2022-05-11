//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	private static var hasMovedLightingToWindow = false
	private static var hasCopiedAccentColorToWindow = false
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let window = view.window {
			if !Self.hasMovedLightingToWindow {
				Self.hasMovedLightingToWindow = true
				window.overrideUserInterfaceStyle = view.overrideUserInterfaceStyle
				view.overrideUserInterfaceStyle = .unspecified
			}
			if !Self.hasCopiedAccentColorToWindow {
				Self.hasCopiedAccentColorToWindow = true
				window.tintColor = view.tintColor
			}
		}
	}
}
