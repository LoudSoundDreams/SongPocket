//
//  TabBarController.swift
//  LavaRock
//
//  Created by h on 2022-03-21.
//

import UIKit

final class TabBarController: UITabBarController {
	// `MovesThemeToWindow`
	static var didMoveThemeToWindow = false
	
	final override var selectedViewController: UIViewController? {
		didSet {
			if selectedViewController is LibraryNC {
				let appearance = tabBar.standardAppearance
				appearance.configureWithDefaultBackground()
				tabBar.standardAppearance = appearance
			} else if
				let playerNC = selectedViewController as? UINavigationController,
				playerNC.viewControllers.first is PlayerVC
			{
				let appearance = tabBar.standardAppearance
				appearance.configureWithTransparentBackground()
				tabBar.standardAppearance = appearance
			}
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		moveThemeToWindow()
	}
}
extension TabBarController: MovesThemeToWindow {}
