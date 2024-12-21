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
		
		// Migrate persistent data (1), then show persistent data (2), then update persistent data (3), in that order.
		ZZZDatabase.migrate() // (1) It’s simpler to migrate before running any UI code, so our UI can assume already-migrated data. But slow migrations ought to show UI while in progress.
		Librarian.load() // (2)
	}
	var body: some Scene {
		WindowGroup {
			VCRMain()
				.ignoresSafeArea()
				.task {
					guard MusicAuthorization.currentStatus == .authorized else { return }
					Self.integrate_Apple_Music()
				}
		}
	}
	
	@MainActor static func integrate_Apple_Music() {
		AppleLibrary.shared.watch() // (3)
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
