//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	// `MovesThemeToWindow`
	static var didMoveThemeToWindow = false
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		moveThemeToWindow()
	}
	
	final override func popToRootViewController(
		animated: Bool
	) -> [UIViewController]? {
		let result = super.popToRootViewController(animated: animated)
		let didPopAnyViewControllers = !(result ?? []).isEmpty
		if didPopAnyViewControllers {
			setToolbarHidden(true, animated: true)
		}
		return result
	}
}
extension LibraryNC: MovesThemeToWindow {}
