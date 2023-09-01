//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	var needsOverrideThemeInWindow = false
	
	lazy var mainToolbar = MainToolbar__UIKit()
	
	init(rootStoryboardName: String) {
		super.init(
			rootViewController: UIStoryboard(name: rootStoryboardName, bundle: nil)
				.instantiateInitialViewController()!
		)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
	}
	
	// Xcode 15: Move this to `viewIsAppearing`? (Back-deployed to iOS 13)
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsOverrideThemeInWindow {
			needsOverrideThemeInWindow = false
			
//			let window = view.window!
			
			// Accent color
//			window.tintColor = view.tintColor
			// Unfortunately, setting `view.tintColor = nil` doesn’t remove the override.
		}
	}
}
