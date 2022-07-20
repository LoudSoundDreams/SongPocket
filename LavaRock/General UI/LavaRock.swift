//
//  LavaRock.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI

@main
struct LavaRock: App {
	@ObservedObject private var theme: Theme
	
	init() {
		theme = .shared
		
		// Delete unused entries in `UserDefaults`
		let defaults = UserDefaults.standard
		defaults.dictionaryRepresentation().forEach { (key, _object) in
			if !Set(
				LRUserDefaultsKey.allCases.map { $0.rawValue }
			).contains(key) {
				defaults.removeObject(forKey: key)
			}
		}
		
		PurchaseManager.shared.beginObservingPaymentTransactions()
	}
	
	var body: some Scene {
		WindowGroup {
			MainViewControllerRep()
				.edgesIgnoringSafeArea(.all)
				.preferredColorScheme(theme.lighting.colorScheme)
				.tint(theme.accentColor.color)
		}
	}
}

private struct MainViewControllerRep: UIViewControllerRepresentable {
	typealias VCType = LibraryNC
	
	@ObservedObject private var theme: Theme
	
	init() {
		theme = .shared
	}
	
	func makeUIViewController(
		context: Context
	) -> VCType {
		let result = UIStoryboard(name: "Library", bundle: nil)
			.instantiateInitialViewController() as! LibraryNC
		// <Override lighting and accent color>
		// <We want to do that on the view’s window, but at first, that’s nil.>
		// So,
		// <override on the view itself at first, then move the override to the window as soon as possible. Thereafter, always override on the window.>
		result.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		result.needsOverrideThemeInWindow = true
		return result
	}
	
	// SwiftUI does run this between `VCType.viewDidLoad` and its first `.viewWillAppear`.
	func updateUIViewController(
		_ uiViewController: VCType,
		context: Context
	) {
		// <Override lighting and accent color>
		// <We want to do that on the view’s window, but at first, that’s nil.>
		// Our next-best option would be to
		// <override on the view itself at first, then move the override to the window as soon as possible. Thereafter, always override on the window.>
		// But we can’t remove a view’s tint color override.
		// So, override the tint color on both the view and its window, every time.
		if
			// When the UIKit Options screen changes the accent color, running this branch breaks the animation for deselecting the accent color row.
			// So, do this only for the SwiftUI Options screen, and make the UIKit Options screen do this itself.
			let window = uiViewController.view.window
		{
			window.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
			window.tintColor = theme.accentColor.uiColor
		}
		uiViewController.view.tintColor = theme.accentColor.uiColor
	}
}
