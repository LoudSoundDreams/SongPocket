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
		// Override lighting
		// We want to do that on the view controller’s window, but at first, that’s nil.
		// So, <override on the view controller itself at first, then move the override to the window as soon as possible>.
		result.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		result.needsOverrideThemeInWindow = true
		return result
	}
	
	func updateUIViewController(
		_ uiViewController: VCType,
		context: Context
	) {
		// Override accent color
		// We want to do that on the view controller’s window, but at first, that’s nil.
		// Our next-best option would be to <override on the view controller itself at first, then move the override to the window as soon as possible>. But we can’t remove a view controller’s tint color override, even by setting it to nil.
		// So, override on both the view controller and its window, every time.
		if let window = uiViewController.view.window {
			window.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
			window.tintColor = theme.accentColor.uiColor
		}
		uiViewController.view.tintColor = theme.accentColor.uiColor
	}
}
