// 2021-12-30

import SwiftUI
import MusicKit
import os

@main struct LavaRock: App {
	init() {
		let signposter = OSSignposter(subsystem: "startup", category: .pointsOfInterest)
		let _init = signposter.beginInterval("init")
		defer { signposter.endInterval("init", _init) }
		
		// Clean up after ourselves; leave no unused data in persistent storage.
		let defaults = UserDefaults.standard
		defaults.dictionaryRepresentation().forEach { (key_existing, _) in
			defaults.removeObject(forKey: key_existing)
		}
		
		// In order, (1) migrate persistent data, then (2) show persistent data, then (3) update persistent data.
		
		// (1) Migrate before running any UI code, so our UI can assume already-migrated data.
		ZZZDatabase.migrate()
		
		// (2)
		let loaded = Disk.load_albums()
		Librarian.the_albums = loaded
		loaded.forEach {
			Librarian.register_album($0)
		}
	}
	var body: some Scene {
		WindowGroup {
//			AlbumGallery()
			
			RepNCMain()
				.ignoresSafeArea()
//				.toolbar { ToolbarItemGroup(placement: .bottomBar) { TheBar() } }
			
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

struct RepNCMain: UIViewControllerRepresentable {
	typealias VCType = NCMain
	func makeUIViewController(context: Context) -> VCType { VCType.create() }
	func updateUIViewController(_ vc: VCType, context: Context) {}
}
final class NCMain: UINavigationController {
	static func create() -> Self {
		let vc_root: UIViewController
//		= UIHostingController(rootView: AlbumGallery())
		= UIStoryboard(name: "AlbumTable", bundle: nil).instantiateInitialViewController()!
		let result = Self(rootViewController: vc_root)
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
