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
//				ExhibitList()
				ExhibitTVCRep()
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
						.transition(.move(edge: .bottom)) // Actually incorrect because the view disappears after traveling only its own height, not offscreen; but it looks good enough.
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
		guard let spotlight = Global.shared.spotlight else { return false }
		switch spotlight.focus {
			case .gallery: return true
			case .covers, .expanded: return false
		}
	}
	
	@MainActor static func integrate_Apple_Music() {
		AppleCatalog.shared.watch() // (3)
		LCD.shared.watch()
	}
}

private struct ExhibitTVCRep: UIViewControllerRepresentable {
	typealias VCType = ExhibitTVC
	func makeUIViewController(context: Context) -> VCType {
		return ExhibitTVC.init_please()
	}
	func updateUIViewController(_ vc: VCType, context: Context) {}
}
