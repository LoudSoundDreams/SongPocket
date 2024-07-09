// 2022-03-19

import MusicKit

enum AppleMusic {
	@MainActor static func requestAccess() async {
		switch MusicAuthorization.currentStatus {
			case .authorized: break // Should never run
			case .notDetermined:
				switch await MusicAuthorization.request() {
					case .denied, .restricted, .notDetermined: break
					case .authorized: AppleMusic.integrate()
					@unknown default: break
				}
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
			@unknown default: break
		}
	}
	
	@MainActor static func integrate() {
		MusicRepo.shared.observeMediaPlayerLibrary()
		__MainToolbar.shared.observeMediaPlayerController()
	}
	
	static func sections() async -> [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] {
		let request = MusicLibrarySectionedRequest<MusicKit.Album, MusicKit.Song>()
		guard let response = try? await request.response() else { return [:] }
		
		let tuples = response.sections.map { section in (section.id, section) }
		return Dictionary(uniqueKeysWithValues: tuples)
	}
}

extension SystemMusicPlayer {
	@MainActor static var _shared: SystemMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
}

import MediaPlayer
extension MPMusicPlayerController {
	static var _system: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return .systemMusicPlayer
	}
}
