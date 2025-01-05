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
			let working_on_main_view = 10 == 1
			ZStack {
				if working_on_main_view {
					AlbumGallery()
				} else {
					RepNCAlbumTable()
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

private struct AlbumGallery: View {
	var body: some View {
		TabView(selection: $rando_spotlighted) {
			ForEach(randos, id: \.self) { rando in
				
//				RepNCAlbumTable().containerRelativeFrame(.horizontal)
				
				GeometryReader { proxy in
					if let uAlbum = Librarian.album_with_uAlbum.keys.randomElement()
					{
						VStack {
							Spacer()
							
							let geo_width = proxy.size.width
							AlbumArt(
								uAlbum: uAlbum,
								dim_limit: geo_width
							)
							.containerRelativeFrame(.horizontal)
							.onTapGesture {
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
							
							Spacer()
						}
					}
				}.ignoresSafeArea()
				
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
}

private struct RepNCAlbumTable: UIViewControllerRepresentable {
	typealias VCType = NCMain
	func makeUIViewController(context: Context) -> VCType { NCMain.create() }
	func updateUIViewController(_ uiViewController: VCType, context: Context) {}
}
private final class NCMain: UINavigationController {
	static func create() -> Self {
		let result = Self(
			rootViewController: UIStoryboard(name: "AlbumTable", bundle: nil).instantiateInitialViewController()!
		)
		result.setNavigationBarHidden(true, animated: false)
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
