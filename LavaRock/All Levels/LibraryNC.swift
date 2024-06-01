//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit
import SwiftUI

final class LibraryNC: UINavigationController {
	var needsOverrideThemeInWindow = false
	
	lazy var mainToolbar = MainToolbar__UIKit(
		weakly_Console_presenter: self,
		weakly_Settings_presenter: self
	)
	
	init(rootStoryboardName: String) {
		super.init(
			rootViewController: UIStoryboard(name: rootStoryboardName, bundle: nil)
				.instantiateInitialViewController()!
		)
		
		did_init()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		did_init()
	}
	
	private func did_init() {
		navigationBar.prefersLargeTitles = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsOverrideThemeInWindow {
			needsOverrideThemeInWindow = false
			
			let window = view.window!
			
			// Lighting
			window.overrideUserInterfaceStyle = view.overrideUserInterfaceStyle
			// Remove override from this view controller
			view.overrideUserInterfaceStyle = .unspecified
			
			// Accent color
			window.tintColor = view.tintColor
			// Unfortunately, setting `view.tintColor = nil` doesn’t remove the override.
		}
	}
}
