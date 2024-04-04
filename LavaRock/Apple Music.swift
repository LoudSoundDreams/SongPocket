// 2022-03-19

import MusicKit

@MainActor enum AppleMusic {
	static func integrate() {
		MusicRepo.shared.watchMPLibrary() // Collections view must start observing `Notification.Name.mergedChanges` before this.
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
	@objc private func playbackState() {
		reflectorToolbar?.referencee?.freshen()
	}
	@objc private func nowPlaying() {
		reflectorToolbar?.referencee?.freshen()
	}
}
