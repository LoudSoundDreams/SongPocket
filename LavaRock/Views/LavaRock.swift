//
//  LavaRock.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import SwiftUI

@main
struct LavaRock: App {
	init() {
		// Delete unused entries in `UserDefaults`
		let defaults = UserDefaults.standard
		let toKeep = Set(LRDefaultsKey.allCases.map { $0.rawValue })
		defaults.dictionaryRepresentation().forEach { (existingKey, _) in
			if !toKeep.contains(existingKey) {
				defaults.removeObject(forKey: existingKey)
			}
		}
	}
	
	var body: some Scene {
		WindowGroup {
			RootView()
				.edgesIgnoringSafeArea(.all)
				.task { // Runs after `onAppear`, and after the view first appears onscreen
					await AppleMusic.integrateIfAuthorized()
				}
//				.mainToolbar()
		}
	}
}
private struct RootView: UIViewControllerRepresentable {
	typealias VCType = UINavigationController
	
	func makeUIViewController(context: Context) -> VCType {
		let result = UINavigationController(
			rootViewController: UIStoryboard(name: "FoldersTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		
		return result
	}
	
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}