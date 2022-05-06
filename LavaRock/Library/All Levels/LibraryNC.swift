//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	private static var movedLightingToWindow = false
	private static var copiedAccentColorToWindow = false
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let window = view.window {
			if !Self.movedLightingToWindow {
				Self.movedLightingToWindow = true
				window.overrideUserInterfaceStyle = view.overrideUserInterfaceStyle
				view.overrideUserInterfaceStyle = .unspecified
			}
			if !Self.copiedAccentColorToWindow {
				Self.copiedAccentColorToWindow = true
				window.tintColor = view.tintColor
			}
		}
	}
}
