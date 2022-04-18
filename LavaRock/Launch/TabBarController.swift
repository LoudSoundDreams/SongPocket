//
//  TabBarController.swift
//  LavaRock
//
//  Created by h on 2022-03-21.
//

import UIKit
import SwiftUI

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
				playerNC.viewControllers.first is ConsoleVC
			{
				let appearance = tabBar.standardAppearance
				appearance.configureWithTransparentBackground()
				tabBar.standardAppearance = appearance
			}
		}
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if Enabling.swiftUI__playerScreen {
			guard let viewControllers = viewControllers else {
				return
			}
			guard let indexOfPlayerScreen = viewControllers.firstIndex(where: { viewController in
				if
					let navigationController = viewController as? UINavigationController,
					navigationController.viewControllers.first is ConsoleVC
				{
					return true
				} else {
					return false
				}
			}) else {
				return
			}
			var copyOfViewControllers = viewControllers
			copyOfViewControllers.remove(at: indexOfPlayerScreen)
			copyOfViewControllers.insert(
				{
					let hostingController = UIHostingController(rootView: ConsoleView())
					hostingController.tabBarItem = UITabBarItem(
						title: "Player",
						image: UIImage(systemName: "hifispeaker.fill"),
						selectedImage: nil)
					return hostingController
				}(),
				at: indexOfPlayerScreen)
			setViewControllers(copyOfViewControllers, animated: false)
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		moveThemeToWindow()
	}
}
extension TabBarController: MovesThemeToWindow {}
