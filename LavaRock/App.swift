// 2021-12-30

import SwiftUI
import MusicKit

enum WorkingOn {
	static let toolbar = 10 == 1
}

@main struct LavaRock: App {
	static let padding_bubbleBar_horizontal: CGFloat = .eight * 2
	
	init() {
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
			ZStack(alignment: .bottom) {
				RepNCMain()
					.background { Color(white: .one_eighth / 2) }
					.ignoresSafeArea()
				
//					.toolbar { if WorkingOn.toolbar {
//						ToolbarItemGroup(placement: .bottomBar) {
//							BubbleBar()
//						}
//					}}
				
				if WorkingOn.toolbar {
					ZStack { if !Global.shared.focus_is_spotlight {
						BubbleBar().padding(.horizontal, Self.padding_bubbleBar_horizontal)
					}}.animation(.linear_quick(), value: Global.shared.focus_is_spotlight)
				}
			}
			.persistentSystemOverlays(Global.shared.focus_is_spotlight ? .hidden : .automatic) // As of iOS 18.3 RC, even if we hard-code this to `.hidden`, iOS still shows the Home indicator when we change which artwork is focused.
			.task {
				guard MusicAuthorization.currentStatus == .authorized else { return }
				Self.integrate_Apple_Music()
			}
		}
	}
	
	@MainActor static func integrate_Apple_Music() {
		AppleCatalog.shared.watch() // (3)
		LCD.shared.watch()
	}
}

@MainActor @Observable final class Global {
	private init() {}
	var focus_is_spotlight = false
	@ObservationIgnored var showcase: Exhibit?
}
extension Global {
	@ObservationIgnored static let shared = Global()
}

// MARK: Private

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
