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
	
	var allowsSelecting = true
	
	final override var selectedViewController: UIViewController? {
		didSet {
			if
				(selectedViewController as? UINavigationController)?
					.viewControllers.first is ConsoleVC
			{
				let appearance = tabBar.standardAppearance
				appearance.configureWithTransparentBackground()
				tabBar.standardAppearance = appearance
			} else {
				let appearance = tabBar.standardAppearance
				appearance.configureWithDefaultBackground()
				tabBar.standardAppearance = appearance
			}
		}
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		delegate = self
		
		if Enabling.optionsInTabBar {
			if let optionsNC = viewControllers?.last as? OptionsNC {
				optionsNC.tabBarItem = UITabBarItem(
					title: LocalizedString.options,
					image: UIImage(systemName: "switch.2"),
					selectedImage: nil)
			}
		} else {
			if viewControllers?.last is OptionsNC {
				viewControllers?.removeLast()
			}
		}
		
		if Enabling.swiftUI__console {
			replaceConsoleVC()
		}
		
		func replaceConsoleVC() {
			guard let viewControllers = viewControllers else {
				return
			}
			guard let indexOfConsole = viewControllers.firstIndex(where: { viewController in
				(viewController as? UINavigationController)?.viewControllers.first is ConsoleVC
			}) else {
				return
			}
			var copyOfViewControllers = viewControllers
			copyOfViewControllers.remove(at: indexOfConsole)
			copyOfViewControllers.insert(
				{
					let hostingController = UIHostingController(rootView: ConsoleView())
					hostingController.tabBarItem = UITabBarItem(
						title: "Player",
						image: UIImage(systemName: "hifispeaker.fill"),
						selectedImage: nil)
					return hostingController
				}(),
				at: indexOfConsole)
			setViewControllers(copyOfViewControllers, animated: false)
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		moveThemeToWindow()
	}
}
extension TabBarController: MovesThemeToWindow {}
extension TabBarController: UITabBarControllerDelegate {
	final func tabBarController(
		_ tabBarController: UITabBarController,
		shouldSelect viewController: UIViewController
	) -> Bool {
		return allowsSelecting
	}
}
