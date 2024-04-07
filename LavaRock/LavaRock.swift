// 2021-12-30

import SwiftUI
import MusicKit

enum WorkingOn {
	static let mainToolbar = 10 == 1
}

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
//			AxisView()
//			AlbumList()
			RootVCRep()
				.ignoresSafeArea()
				.toolbar { if WorkingOn.mainToolbar {
					ToolbarItemGroup(placement: .bottomBar) {
						MainToolbar()
					}
				} }
				.task {
					guard MusicAuthorization.currentStatus == .authorized else { return }
					AppleMusic.integrate()
				}
		}
	}
}
private struct RootVCRep: UIViewControllerRepresentable {
	typealias VCType = RootNC
	func makeUIViewController(context: Context) -> VCType { RootNC.create() }
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
private final class RootNC: UINavigationController {
	static func create() -> Self {
		let result = Self(
			rootViewController: UIStoryboard(name: "AlbumsTVC", bundle: nil).instantiateInitialViewController()!
		)
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		if !WorkingOn.mainToolbar {
			result.setToolbarHidden(false, animated: false)
		}
		return result
	}
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		if !Self.hasAppeared {
			Self.hasAppeared = true
			view.window!.tintColor = UIColor(named: "denim")!
		}
	}
	private static var hasAppeared = false
}

// Keeping these keys in one place helps us keep them unique.
enum LRDefaultsKey: String, CaseIterable {
	// Introduced in version ?
	case hasSavedDatabase = "hasEverImportedFromMusic"
	
	/*
	 Deprecated after version 1.13.3
	 Introduced in version 1.8
	 "nowPlayingIcon"
	 Values: String
	 Introduced in version 1.12
	 • "Paw"
	 • "Luxo"
	 Introduced in version 1.8
	 • "Speaker"
	 • "Fish"
	 Deprecated after version 1.11.2:
	 • "Bird"
	 • "Sailboat"
	 • "Beach umbrella"
	 
	 Deprecated after version 1.13.3
	 Introduced in version 1.0
	 "accentColorName"
	 Values: String
	 • "Blueberry"
	 • "Grape"
	 • "Strawberry"
	 • "Tangerine"
	 • "Lime"
	 
	 Deprecated after version 1.13
	 Introduced in version 1.6
	 "appearance"
	 Values: Int
	 • `0` for “match system”
	 • `1` for “always light”
	 • `2` for “always dark”
	 
	 Deprecated after version 1.7
	 Introduced in version ?
	 "shouldExplainQueueAction"
	 Values: Bool
	 */
}
