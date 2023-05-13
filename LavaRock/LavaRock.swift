//
//  LavaRock.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI

@main
struct LavaRock: App {
	@ObservedObject private var theme: Theme = .shared
	
	init() {
		// Delete unused entries in `UserDefaults`
		let toKeep = Set(LRUserDefaultsKey.allCases.map { $0.rawValue })
		let defaults = UserDefaults.standard
		defaults.dictionaryRepresentation().forEach { (key, _) in
			if !toKeep.contains(key) {
				defaults.removeObject(forKey: key)
			}
		}
		
		PurchaseManager.shared.beginObservingPaymentTransactions()
	}
	
	var body: some Scene {
		WindowGroup {
			MainLibraryNC()
				.edgesIgnoringSafeArea(.all)
				.preferredColorScheme(theme.lighting.colorScheme)
				.tint(theme.accentColor.color)
				.task { // Runs after `onAppear`, and after the view first appears onscreen
					await AppleMusic.integrateIfAuthorized()
				}
//				.mainToolbar()
		}
	}
}

private struct MainLibraryNC: UIViewControllerRepresentable {
	typealias VCType = LibraryNC
	
	@ObservedObject private var theme: Theme = .shared
	
	// Overriding lighting and accent color
	// We want to do that on the view’s window, but during `makeUIViewController`, that’s nil. So…
	// • During `make`, override on the view itself. Then, as soon as possible, move the override to the window.
	// • Thereafter, during `updateUIViewController`, always override on the window.
	// “As soon as possible” is `viewDidAppear`, because that’s when the window becomes non-nil, and note that that’s after the initial `update`.
	
	func makeUIViewController(
		context: Context
	) -> VCType {
		let vc = LibraryNC(rootStoryboardName: "FoldersTVC")
		
		// Lighting
		vc.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		
		// Accent color
		vc.view.tintColor = theme.accentColor.uiColor
		vc.needsOverrideThemeInWindow = true
		
		return vc
	}
	
	// SwiftUI does run this before `VCType.viewDidLoad`.
	func updateUIViewController(
		_ uiViewController: VCType,
		context: Context
	) {
		let vc = uiViewController
		let window = vc.view.window
		
		// Lighting
		window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		
		// Accent color
		// Unfortunately, we can’t remove a view’s tint color override.
		// So, override the tint color on both the view and its window, every time.
		vc.view.tintColor = theme.accentColor.uiColor
		// When the UIKit Settings screen changes the accent color, SwiftUI runs this method at a moment that breaks the animation for deselecting the accent color row.
		// So, only run this branch for the SwiftUI Settings screen, and make the UIKit Settings screen do this work itself.
		if Enabling.swiftUI__settings {
			window?.tintColor = theme.accentColor.uiColor
		}
	}
}
