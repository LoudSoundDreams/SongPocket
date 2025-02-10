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
			ZStack(alignment: .bottomTrailing) {
				RepNCMain()
					.background {
						LinearGradient(
							gradient: Gradient(stops: [
								Gradient.Stop(color: Color(white: .one_eighth / 4), location: .zero),
								Gradient.Stop(color: Color(white: .one_eighth / 2), location: 1),
							]),
							startPoint: .top, endPoint: .bottom)
					}
					.ignoresSafeArea()
				ZStack { if !in_gallery {
					BubbleBar()
						.padding(.horizontal)
						.padding(.horizontal, -BubbleBar.width_border)
						.transition(.move(edge: .bottom))
				}}.animation(.linear_quick(), value: in_gallery)
			}
			.persistentSystemOverlays(in_gallery ? .hidden : .automatic) // As of iOS 18.3 RC, even if we hard-code this to `.hidden`, iOS still shows the Home indicator when we change which artwork is focused.
			.task {
				guard MusicAuthorization.currentStatus == .authorized else { return }
				Self.integrate_Apple_Music()
			}
		}
	}
	private var in_gallery: Bool {
		guard let showcase = Global.shared.showcase else { return false }
		switch showcase.focus {
			case .gallery: return true
			case .covers, .expanded: return false
		}
	}
	
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
		return result
	}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		if !Self.has_appeared {
			Self.has_appeared = true
			view.window!.tintColor = UIColor(Color.LRAccent)
		}
	}
	private static var has_appeared = false
}
