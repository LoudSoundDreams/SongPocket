// 2022-03-19

import MusicKit

@MainActor enum AppleMusic {
	static func requestAccess() async {
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
	
	static func integrate() {
		MusicRepo.shared.watchMPLibrary()
		AudioPlayer.shared.watchMPPlayer()
	}
}

@MainActor extension SystemMusicPlayer {
	static var _shared: SystemMusicPlayer? {
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
@MainActor final class AudioPlayer {
	static let shared = AudioPlayer()
	private init() {}
	var reflectorToolbar: Weak<__MainToolbar>? = nil
	func watchMPPlayer() {
		guard let __player = MPMusicPlayerController._system else { return }
		__player.beginGeneratingPlaybackNotifications()
		playbackState()
		nowPlaying()
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(playbackState),
			name: .MPMusicPlayerControllerPlaybackStateDidChange, // As of iOS 15.4, Media Player also posts this when the repeat or shuffle mode changes.
			object: nil)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(nowPlaying),
			name: .MPMusicPlayerControllerNowPlayingItemDidChange,
			object: nil)
	}
	@objc private func playbackState() { reflectorToolbar?.referencee?.refresh() }
	@objc private func nowPlaying() { reflectorToolbar?.referencee?.refresh() }
}
