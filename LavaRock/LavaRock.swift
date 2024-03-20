// 2021-12-30

import SwiftUI

@main
struct LavaRock: App {
	static let usesSwiftUIMainToolbar = 10 == 1
	
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
				.toolbar { if Self.usesSwiftUIMainToolbar {
					ToolbarItemGroup(placement: .bottomBar) { MainToolbar() }
				} }
				.ignoresSafeArea()
				.task { // Runs after `onAppear`, and after the view first appears onscreen
					await AppleMusic.integrateIfAuthorized()
				}
				.tint(Color("denim")) // Applies before `integrateIfAuthorized`.
		}
	}
}
private struct RootView: UIViewControllerRepresentable {
	typealias VCType = UINavigationController
	func makeUIViewController(context: Context) -> VCType {
		let result = UINavigationController(
			rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		
		MainToolbarStatus.shared.baseNC = result
		
		return result
	}
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
