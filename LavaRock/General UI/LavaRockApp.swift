//
//  LavaRockApp.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI

@main
struct LavaRockApp: App {
	@ObservedObject private var theme: Theme = .shared
	
	var body: some Scene {
		WindowGroup {
			RootViewControllerRepresentable()
				.edgesIgnoringSafeArea(.all)
				.preferredColorScheme(theme.lighting.colorScheme)
				.tint(theme.accentColor.color)
		}
	}
	
	init() {
		PurchaseManager.shared.beginObservingPaymentTransactions()
		
		DispatchQueue.global(qos: .utility).async {
			UserDefaults.standard.deleteAllValuesExcept(forKeys: Set(LRUserDefaultsKey.rawValues()))
		}
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
	
	@ObservedObject private var theme: Theme = .shared
	
	func makeUIViewController(
		context: Context
	) -> ViewControllerType {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
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
