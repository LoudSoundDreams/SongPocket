// 2021-12-30

import SwiftUI
import MusicKit

enum WorkingOn {
	static let select_range = 10 == 10
	static let plain_database = 10 == 1
}

@main struct LavaRock: App {
	init() {
		// Clean up after ourselves; leave no unused data in persistent storage.
		let defaults = UserDefaults.standard
		defaults.dictionaryRepresentation().forEach { (key_existing, _) in
			defaults.removeObject(forKey: key_existing)
		}
		
		ZZZDatabase.viewContext.migrateFromMulticollection() // Run this before any UI code, so our UI can assume an already-migrated database.
	}
	var body: some Scene {
		WindowGroup {
//			AlbumShelf()
//			AlbumList()
			VCRMain()
				.ignoresSafeArea()
				.task {
					guard MusicAuthorization.currentStatus == .authorized else { return }
					Self.integrate_Apple_Music()
				}
		}
	}
	
	@MainActor static func integrate_Apple_Music() {
		Librarian.shared.observe_mpLibrary()
		PlayerState.shared.observeMKPlayer()
	}
}
private struct VCRMain: UIViewControllerRepresentable {
	typealias VCType = NCMain
	func makeUIViewController(context: Context) -> VCType { NCMain.create() }
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
private final class NCMain: UINavigationController {
	static func create() -> Self {
		let result = Self(
			rootViewController: UIStoryboard(name: "AlbumsTVC", bundle: nil).instantiateInitialViewController()!
		)
		let nav_bar = result.navigationBar
		nav_bar.scrollEdgeAppearance = nav_bar.standardAppearance
		let toolbar = result.toolbar!
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		result.setToolbarHidden(false, animated: false)
		return result
	}
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		if !Self.has_appeared {
			Self.has_appeared = true
			view.window!.tintColor = .denim
		}
	}
	private static var has_appeared = false
}
