// 2021-12-30

import SwiftUI
import MusicKit
import os

enum WorkingOn {
	static let bottom_bar = 10 == 1
}

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
		
		ZZZDatabase.migrate() // (1) Migrate before running any UI code, so our UI can assume already-migrated data.
		
		// (2)
		let loaded = Disk.load_albums()
		Librarian.the_albums = loaded
		loaded.forEach {
			Librarian.register_album($0)
		}
	}
	var body: some Scene {
		WindowGroup {
			let working_on_main_view = 10 == 1
			ZStack {
				if working_on_main_view {
					MainView()
				} else {
					MainVCRep()
						.toolbar { if WorkingOn.bottom_bar {
							ToolbarItemGroup(placement: .bottomBar) { TheBar() }
						}}
				}
			}
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

private struct MainView: View {
	var body: some View {
		ScrollView(.horizontal) {
			LazyHStack {
				MainVCRep()
					.frame(width: .eight * 24)
				MainVCRep()
					.frame(width: .eight * 36)
				List { ForEach(0 ..< 5) { _ in
					Image(systemName: "hare.fill")
				}}.frame(width: .eight * 24)
				List { ForEach(0 ..< 5) { _ in
					Image(systemName: "tortoise.fill")
				}}.frame(width: .eight * 36)
			}
		}
	}
}

private struct MainVCRep: UIViewControllerRepresentable {
	typealias VCType = NCMain
	func makeUIViewController(context: Context) -> VCType { NCMain.create() }
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
private final class NCMain: UINavigationController {
	static func create() -> Self {
		let result = Self(
			rootViewController: UIStoryboard(name: "AlbumTable", bundle: nil).instantiateInitialViewController()!
		)
		let nav_bar = result.navigationBar
		nav_bar.scrollEdgeAppearance = nav_bar.standardAppearance
		if !WorkingOn.bottom_bar {
			let toolbar = result.toolbar!
			toolbar.scrollEdgeAppearance = toolbar.standardAppearance
			result.setToolbarHidden(false, animated: false)
		}
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
