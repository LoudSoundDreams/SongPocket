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
	
	// Overriding lighting and accent color
	// We want to do that on the view’s window, but during `makeUIViewController`, that’s nil. So…
	// • During `make`, override on the view itself. Then, as soon as possible, move the override to the window.
	// • Thereafter, during `updateUIViewController`, always override on the window.
	// “As soon as possible” is `viewDidAppear`, because that’s when the window becomes non-nil, and note that that’s after the initial `update`.
	
	func makeUIViewController(
		context: Context
	) -> VCType {
		let vc = LibraryNC(rootStoryboardName: "FoldersTVC")
//		vc.view.tintColor = tint
		vc.needsOverrideThemeInWindow = true
		return vc
	}
	
	// SwiftUI does run this before `VCType.viewDidLoad`.
	func updateUIViewController(
		_ uiViewController: VCType,
		context: Context
	) {
//		let vc = uiViewController
//		let window = vc.view.window
		
		// Unfortunately, we can’t remove a view’s tint color override.
		// So, override the tint color on both the view and its window, every time.
//		vc.view.tintColor = tint
	}
}
