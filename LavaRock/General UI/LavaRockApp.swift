//
//  LavaRockApp.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI
import CoreData

@main
struct LavaRockApp: App {
	var body: some Scene {
		WindowGroup {
			RootViewControllerRepresentable()
				.edgesIgnoringSafeArea(.all)
		}
	}
	
	init() {
		PurchaseManager.shared.beginObservingPaymentTransactions()
		
		DispatchQueue.global(qos: .utility).async {
			UserDefaults.standard.deleteAllEntriesExcept(
				withKeys: LRUserDefaultsKey.rawValues())
		}
	}
}

struct RootViewControllerRepresentable: UIViewControllerRepresentable {
	typealias ViewControllerType = UIViewController
	
	func makeUIViewController(
		context: Context
	) -> ViewControllerType {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let result = storyboard.instantiateViewController(withIdentifier: LibraryNC.storyboardID)
		return result
	}
	
	func updateUIViewController(
		_ uiViewController: ViewControllerType,
		context: Context
	) {}
}
