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
		let defaults = UserDefaults.standard
		let keysToKeep = Set(LRUserDefaultsKey.allCases.map { $0.rawValue })
		defaults.dictionaryRepresentation().forEach { (key, _object) in
			if !keysToKeep.contains(key) {
				defaults.removeObject(forKey: key)
			}
		}
		
		PurchaseManager.shared.beginObservingPaymentTransactions()
	}
	
	var body: some Scene {
		WindowGroup {
			LibraryNCRep()
				.edgesIgnoringSafeArea(.all)
				.preferredColorScheme(theme.lighting.colorScheme)
				.tint(theme.accentColor.color)
		}
	}
}

private struct LibraryNCRep: UIViewControllerRepresentable {
	typealias VCType = LibraryNC
	
	@ObservedObject private var theme: Theme = .shared
	
	// Overriding lighting and accent color
	// We want to do that on the view’s window, but during `makeUIViewController`, that’s nil. So …
	// • During `make`, override on the view itself. Then, as soon as possible, move the override to the window.
	// • Thereafter, during `updateUIViewController`, always override on the window.
	// “As soon as possible” is `viewDidAppear`, because that’s when the window becomes non-nil, and note that that’s after the initial `update`.
	
	func makeUIViewController(
		context: Context
	) -> VCType {
		let vc = LibraryNC(fileNameOfStoryboardForRootViewController: "CollectionsTVC")
		
		// Lighting
		vc.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		
		// Accent color
		vc.view.tintColor = theme.accentColor.uiColor
		vc.needsOverrideThemeInWindow = true
		
		return vc
	}
	
	// SwiftUI does run this between `VCType.viewDidLoad` and its first `.viewWillAppear`.
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
		// When the UIKit Options screen changes the accent color, SwiftUI runs this method at a moment that breaks the animation for deselecting the accent color row.
		// So, only run this branch for the SwiftUI Options screen, and make the UIKit Options screen do this work itself.
		if Enabling.swiftUI__options {
			window?.tintColor = theme.accentColor.uiColor
		}
	}
}
