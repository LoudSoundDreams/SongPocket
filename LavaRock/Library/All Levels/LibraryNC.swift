//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	final lazy var transportBar = TransportBar(
		moreButtonAction: UIAction { [weak self] _ in
			guard let self = self else { return }
			self.present(self.moreVC, animated: true)
		})
	private let moreVC: UIViewController
	
	required init?(coder: NSCoder) {
		moreVC = UIStoryboard(name: "Console", bundle: nil)
			.instantiateInitialViewController()!
		
		super.init(coder: coder)
	}
	
	private static var hasMovedLightingToWindow = false
	private static var hasCopiedAccentColorToWindow = false
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
}
