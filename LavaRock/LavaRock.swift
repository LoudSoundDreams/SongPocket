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
			RootNC()
				.edgesIgnoringSafeArea(.all)
				.task { // Runs after `onAppear`, and after the view first appears onscreen
					await AppleMusic.integrateIfAuthorized()
				}
//				.mainToolbar()
		}
	}
}
private struct RootNC: UIViewControllerRepresentable {
	typealias VCType = LibraryNC
	
	func makeUIViewController(context: Context) -> VCType {
		let result = LibraryNC(rootStoryboardName: "FoldersTVC")
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		return result
	}
	
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
