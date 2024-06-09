// 2021-12-30

import SwiftUI
import MusicKit

enum WorkingOn {
	static let inlineTracklist = 10 == 1
	static let mainToolbar = 10 == 1
}

@main
struct LavaRock: App {
	init() {
		// Clean up after ourselves; leave no unused data in persistent storage.
		let defaults = UserDefaults.standard
		let toKeep = Set(LRDefaultsKey.allCases.map { $0.rawValue })
		defaults.dictionaryRepresentation().forEach { (existingKey, _) in
			if toKeep.contains(existingKey) { return }
			defaults.removeObject(forKey: existingKey)
		}
	}
	var body: some Scene {
		let workingOnAlbumView = 1
		WindowGroup {
			switch workingOnAlbumView {
				case 10: AlbumShelf()
				case 100: AlbumList()
				default:
					RootVCRep()
						.ignoresSafeArea()
						.toolbar { if WorkingOn.mainToolbar {
							ToolbarItemGroup(placement: .bottomBar) { MainToolbar() }
						}}
						.task {
							guard MusicAuthorization.currentStatus == .authorized else { return }
							AppleMusic.integrate()
						}
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
		let navBar = result.navigationBar
		navBar.scrollEdgeAppearance = navBar.standardAppearance
		if !WorkingOn.mainToolbar {
			let toolbar = result.toolbar!
			toolbar.scrollEdgeAppearance = toolbar.standardAppearance
			result.setToolbarHidden(false, animated: false)
		}
		return result
	}
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		if !Self.hasAppeared {
			Self.hasAppeared = true
			view.window!.tintColor = .denim
		}
	}
	private static var hasAppeared = false
}