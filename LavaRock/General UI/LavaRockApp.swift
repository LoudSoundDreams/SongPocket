//
//  LavaRockApp.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI

@main
struct LavaRockApp: App {
	@ObservedObject private var activeTheme: ActiveTheme = .shared
	
	var body: some Scene {
		WindowGroup {
			RootViewControllerRepresentable()
				.edgesIgnoringSafeArea(.all)
				.preferredColorScheme(activeTheme.lighting.colorScheme)
				.tint(activeTheme.accentColor.color)
		}
	}
	
	init() {
		PurchaseManager.shared.beginObservingPaymentTransactions()
		
		DispatchQueue.global(qos: .utility).async {
			UserDefaults.standard.deleteAllValuesExcept(forKeys: Set(LRUserDefaultsKey.rawValues()))
		}
	}
}

final class ActiveTheme: ObservableObject {
	private init() {}
	static let shared = ActiveTheme()
	
	@Published var lighting: Lighting = .savedPreference()
	@Published var accentColor: AccentColor = .savedPreference()
}

struct RootViewControllerRepresentable: UIViewControllerRepresentable {
	typealias ViewControllerType = UIViewController
	
	@ObservedObject private var activeTheme: ActiveTheme = .shared
	
	func makeUIViewController(
		context: Context
	) -> ViewControllerType {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let result = storyboard.instantiateInitialViewController()!
		
		result.view.overrideUserInterfaceStyle = UIUserInterfaceStyle(activeTheme.lighting.colorScheme)
		result.view.tintColor = activeTheme.accentColor.uiColor
		
		return result
	}
	
	func updateUIViewController(
		_ uiViewController: ViewControllerType,
		context: Context
	) {
		uiViewController.view.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(activeTheme.lighting.colorScheme)
		uiViewController.view.window?.tintColor = activeTheme.accentColor.uiColor
	}
}
