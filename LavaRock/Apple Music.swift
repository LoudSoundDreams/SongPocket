// 2022-03-19

import MusicKit

@MainActor enum AppleMusic {
	static var loadingIndicator: CollectionsTVC? = nil
	
	static func integrateIfAuthorized() async {
		guard MusicAuthorization.currentStatus == .authorized else { return }
		
		await loadingIndicator?.prepareToIntegrateWithAppleMusic()
		
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
