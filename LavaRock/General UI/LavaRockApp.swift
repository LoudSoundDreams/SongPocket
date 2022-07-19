//
//  LavaRockApp.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI

@main
struct LavaRockApp: App {
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
		result.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		return result
	}
	
	func updateUIViewController(
		_ uiViewController: VCType,
		context: Context
	) {
		uiViewController.view.tintColor = theme.accentColor.uiColor
		if let window = uiViewController.view.window {
			window.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
			window.tintColor = theme.accentColor.uiColor
		}
	}
}
