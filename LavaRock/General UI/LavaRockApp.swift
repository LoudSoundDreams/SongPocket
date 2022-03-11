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
	
	var body: some Scene {
		WindowGroup {
			RootViewControllerRepresentable()
				.edgesIgnoringSafeArea(.all)
				.preferredColorScheme(theme.lighting.colorScheme)
				.tint(theme.accentColor.color)
		}
	}
	
	init() {
		theme = .shared
		
		UserDefaults.standard.deleteAllValuesExceptForLRUserDefaultsKeys()
		
		PurchaseManager.shared.beginObservingPaymentTransactions()
	}
}

@MainActor
final class Theme: ObservableObject {
	private init() {}
	static let shared = Theme()
	
	@Published var lighting: Lighting = .savedPreference() {
		didSet { lighting.saveAsPreference() }
	}
	@Published var accentColor: AccentColor = .savedPreference() {
		didSet { accentColor.saveAsPreference() }
	}
}

struct RootViewControllerRepresentable: UIViewControllerRepresentable {
	typealias ViewControllerType = UIViewController
	
	@ObservedObject private var theme: Theme
	
	init() {
		theme = .shared
	}
	
	func makeUIViewController(
		context: Context
	) -> ViewControllerType {
		let storyboard = Enabling.playerScreen
		? UIStoryboard(name: "Tab Bar", bundle: nil)
		: UIStoryboard(name: "Library View", bundle: nil)
		let result = storyboard.instantiateInitialViewController()!
		
		result.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		result.view.tintColor = theme.accentColor.uiColor
		
		return result
	}
	
	func updateUIViewController(
		_ uiViewController: ViewControllerType,
		context: Context
	) {
		uiViewController.view.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(theme.lighting.colorScheme)
		if Enabling.swiftUIOptions {
			uiViewController.view.window?.tintColor = theme.accentColor.uiColor
		}
	}
}
