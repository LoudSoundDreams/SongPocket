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
	
	lazy var mainToolbar = MainToolbar(
		moreButtonAction: UIAction { [weak self] _ in
			guard let self = self else { return }
			if Enabling.swiftUI__console {
				self.present(self.consoleViewHost, animated: true)
			} else {
				self.present(self.consoleVC, animated: true)
			}
		})
	private let consoleViewHost = UIHostingController(rootView: ConsoleView())
	private let consoleVC: UIViewController = UIStoryboard(
		name: "Console", bundle: nil)
		.instantiateInitialViewController()!
	
	init() {
		let collectionsTVC = UIStoryboard(
			name: "CollectionsTVC", bundle: nil)
			.instantiateInitialViewController()!
		super.init(rootViewController: collectionsTVC)
		
		setUp()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setUp()
	}
	
	private func setUp() {
		navigationBar.prefersLargeTitles = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if
			needsOverrideThemeInWindow,
			let window = view.window
		{
			needsOverrideThemeInWindow = false
			
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
