// 2021-12-30

import SwiftUI
import MusicKit

@main struct LavaRock: App {
	init() {
		// Clean up after ourselves; leave no unused data in persistent storage.
		UserDefaults.delete_deprecated_entries()
		
		// In order, (1) migrate persistent data, then (2) show persistent data, then (3) update persistent data.
		ZZZDatabase.migrate() // (1) Migrate before running any UI code, so our UI can assume already-migrated data.
		Librarian.load() // (2)
	}
	var body: some Scene {
		WindowGroup {
			ZStack(alignment: .bottom) {
				RepNCMain()
					.background { Color(white: .one_eighth / 2) }
					.ignoresSafeArea()
				if WorkingOn.toolbar {
					ZStack { if !spotlighting {
						BubbleBar()
					}}.animation(.linear_quick(), value: spotlighting)
				}
			}
			.persistentSystemOverlays(spotlighting ? .hidden : .automatic) // As of iOS 18.3 RC, even if we hard-code this to `.hidden`, iOS still shows the Home indicator when we change which artwork is focused.
			.task {
				guard MusicAuthorization.currentStatus == .authorized else { return }
				Self.integrate_Apple_Music()
			}
		}
	}
	private var spotlighting: Bool { Global.shared.showcase_is_spotlighting }
	
	@MainActor static func integrate_Apple_Music() {
		AppleCatalog.shared.watch() // (3)
		LCD.shared.watch()
	}
}

private struct RepNCMain: UIViewControllerRepresentable {
	func makeUIViewController(context: Context) -> NCMain { NCMain.create() }
	func updateUIViewController(_ vc: NCMain, context: Context) {}
}
private final class NCMain: UINavigationController {
	static func create() -> Self {
		let result = Self(rootViewController: ExhibitTVC.init_please())
		
		result.setNavigationBarHidden(true, animated: false)
		
		if !WorkingOn.toolbar {
			let toolbar = result.toolbar!
			result.setToolbarHidden(false, animated: false)
			toolbar.scrollEdgeAppearance = toolbar.standardAppearance
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
