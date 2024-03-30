// 2021-12-30

enum Enabling {
	static let unifiedAlbumList = 10 == 1
}

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
			RootVC()
				.toolbar { if MainToolbar.usesSwiftUI {
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
private struct RootVC: UIViewControllerRepresentable {
	typealias VCType = RootNC
	func makeUIViewController(context: Context) -> VCType {
		let result: RootNC = {
			if Enabling.unifiedAlbumList {
				if let _ = Collection.allFetched(sorted: false, context: Database.viewContext).first {
					return RootNC(
						rootViewController: UIStoryboard(name: "AlbumsTVC", bundle: nil).instantiateInitialViewController()!
					)
				}
			}
			return RootNC(
				rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil).instantiateInitialViewController()!
			)
		}()
		
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		
		MainToolbarStatus.shared.baseNC = result
		
		return result
	}
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
private final class RootNC: UINavigationController {
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		
		if !Self.hasAppeared {
			Self.hasAppeared = true
			
			// As of iOS 16.6.1, the build setting “Global Accent Color Name” doesn’t apply to (UIKit) alerts or action sheets.
			view.window!.tintColor = UIColor(named: "denim")!
			
			if !MainToolbar.usesSwiftUI {
				setToolbarHidden(false, animated: false)
			}
		}
	}
	private static var hasAppeared = false
}
