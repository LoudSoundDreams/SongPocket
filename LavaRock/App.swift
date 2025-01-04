// 2021-12-30

import SwiftUI
import MusicKit

@main struct LavaRock: App {
	init() {
		// Clean up after ourselves; leave no unused data in persistent storage.
		let defaults = UserDefaults.standard
		defaults.dictionaryRepresentation().forEach { (key_existing, _) in
			defaults.removeObject(forKey: key_existing)
		}
		
		ZZZDatabase.viewContext.migrate_to_single_collection() // Run this before any UI code, so our UI can assume an already-migrated database.
	}
	var body: some Scene {
		WindowGroup {
//			AlbumShelf()
			
			VCRMain()
				.ignoresSafeArea()
				.task {
					guard MusicAuthorization.currentStatus == .authorized else { return }
					Self.integrate_Apple_Music()
				}
		}
	}
	
	@MainActor static func integrate_Apple_Music() {
		AppleLibrary.shared.watch()
		PlayerState.shared.watch()
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
		result.setNavigationBarHidden(true, animated: false)
		let toolbar = result.toolbar!
		result.setToolbarHidden(false, animated: false)
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
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
