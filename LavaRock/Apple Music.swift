// 2022-03-19

import MusicKit

enum AppleMusic {
	@MainActor static func integrate() {
		Crate.shared.observeMediaPlayerLibrary()
		__MainToolbar.shared.observeMediaPlayerController()
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
