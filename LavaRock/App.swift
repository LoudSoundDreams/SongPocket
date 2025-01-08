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
			
			RepVC()
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

private struct AlbumGallery: View {
	var body: some View {
		TabView(selection: $rando_spotlighted) {
			ForEach(randos, id: \.self) { rando in
				RepVC()
			}
		}
		.tabViewStyle(.page(indexDisplayMode: .never))
		.background { Color(white: .one_eighth) }
		.persistentSystemOverlays(.hidden)
	}
	@State private var randos: [UUID] = {
		var result: [UUID] = []
		result.append(Self.rando_default)
		(1 ... 9).forEach { _ in
			result.append(UUID())
		}
		return result
	}()
	@State private var rando_spotlighted: UUID = Self.rando_default // As of iOS 18.3 developer beta 1, this breaks if we use type `UUID?`; `TabView` always selects the first tab.
	private static let rando_default = UUID()
	
	private func remove(_ rando: UUID) {
		guard let i_rando = randos.firstIndex(of: rando) else { return }
		let new_rando_spotlighted: UUID? = {
			guard randos.count >= 2 else { return nil }
			let i_next_rando: Int = min(i_rando + 1, randos.count - 1)
			let result = randos[i_next_rando]
			return result
		}()
		let _ = withAnimation { // Unreliable; the first time after any swipe, SwiftUI crossfades the new tab into place rather than pushing it.
			randos.remove(at: i_rando)
			if let new_rando_spotlighted {
				rando_spotlighted = new_rando_spotlighted
			}
		}
	}
}

private struct RepVC: UIViewControllerRepresentable {
	typealias VCType = NCMain
	func makeUIViewController(context: Context) -> VCType { VCType.create() }
	func updateUIViewController(_ vc: VCType, context: Context) {}
}

private final class NCMain: UINavigationController {
	static func create() -> Self {
		let result = Self(
			rootViewController: UIStoryboard(name: "AlbumTable", bundle: nil).instantiateInitialViewController()!
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
