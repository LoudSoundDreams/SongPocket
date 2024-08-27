// 2021-12-30

import SwiftUI
import MusicKit

@main struct LavaRock: App {
	init() {
		// Clean up after ourselves; leave no unused data in persistent storage.
		let defaults = UserDefaults.standard
		defaults.dictionaryRepresentation().forEach { (existingKey, _) in
			defaults.removeObject(forKey: existingKey)
		}
		
		Database.viewContext.migrateFromMulticollection() // Run this before any UI code, so our UI can assume an already-migrated database.
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
						.task {
							guard MusicAuthorization.currentStatus == .authorized else { return }
							Self.integrateAppleMusic()
						}
			}
		}
	}
	
	@MainActor static func integrateAppleMusic() {
		Crate.shared.observeMediaPlayerLibrary()
		__MainToolbar.shared.observeMediaPlayerController()
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
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		result.setToolbarHidden(false, animated: false)
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
