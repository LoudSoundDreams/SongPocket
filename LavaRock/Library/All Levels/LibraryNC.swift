//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit
import SwiftUI

final class LibraryNC: UINavigationController {
	final lazy var transportBar = TransportBar(
		moreButtonAction: UIAction { [weak self] _ in
			guard let self = self else { return }
			if Enabling.swiftUI__console {
				self.present(self.consoleViewHost, animated: true)
			} else {
				self.present(self.consoleVC, animated: true)
			}
		})
	private let consoleViewHost = UIHostingController(rootView: ConsoleView())
	private let consoleVC: UIViewController
	
	required init?(coder: NSCoder) {
		consoleVC = UIStoryboard(name: "Console", bundle: nil)
			.instantiateInitialViewController()!
		
		super.init(coder: coder)
	}
	
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
	private static var hasMovedLightingToWindow = false
	private static var hasCopiedAccentColorToWindow = false
}
