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
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		moveThemeToWindow()
	}
}
extension TabBarController: MovesThemeToWindow {}
