// 2022-05-09

@preconcurrency import UIKit
@preconcurrency import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class Remote {
	static let shared = Remote()
	let playPauseButton = UIBarButtonItem()
	let overflowButton = UIBarButtonItem()
	var albumsTVC: WeakRef<AlbumsTVC>? = nil
	func observeMediaPlayerController() {
		refresh()
		MPMusicPlayerController._system?.beginGeneratingPlaybackNotifications()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
	}
	
	private init() {
		refresh()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: Librarian.didMerge, object: nil) // Because when Media Player enters or exits the “Not Playing” state, it doesn’t post “now-playing item changed” notifications.
	}
	
	@objc private func refresh() {
		refreshPlayPause()
		refreshOverflow()
	}
	
	private func refreshPlayPause() {
#if targetEnvironment(simulator)
		showPause()
		playPauseButton.isEnabled = true
#else
		guard
			let __player = MPMusicPlayerController._system,
			!SystemMusicPlayer.isEmpty
		else {
			showPlay()
			
			playPauseButton.isEnabled = false
			playPauseButton.accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
			
			return
		}
		
		playPauseButton.isEnabled = true
		playPauseButton.accessibilityTraits.subtract(.notEnabled)
		
		if __player.playbackState == .playing {
			showPause()
		} else {
			showPlay()
		}
#endif
	}
	private func showPlay() {
		playPauseButton.title = InterfaceText.play
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in Task { try await SystemMusicPlayer._shared?.play() } }
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = InterfaceText.pause
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in SystemMusicPlayer._shared?.pause() }
		playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
	}
	
	private func refreshOverflow() {
		overflowButton.preferredMenuElementOrder = .fixed
		overflowButton.menu = newOverflowMenu()
		
		let newImage: UIImage
		let newLabel: String
		defer {
			overflowButton.image = newImage
			overflowButton.accessibilityLabel = newLabel
			overflowButton.accessibilityUserInputLabels = [InterfaceText.more] // Still says “Repeat One More” for some reason.
		}
		let regularImage = UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))!
		let regularLabel = InterfaceText.more
		if
			!SystemMusicPlayer.isEmpty,
			let repeatMode = SystemMusicPlayer._shared?.state.repeatMode
		{
			switch repeatMode {
				case .one:
					newImage = UIImage(systemName: "repeat.1.circle.fill")!
					newLabel = [InterfaceText.repeat1, regularLabel].formattedAsNarrowList()
					return
				case .none, .all: break
				@unknown default: break
			}
		}
		newImage = regularImage
		newLabel = regularLabel
	}
	private func newOverflowTitle() -> String {
		if
			MusicAuthorization.currentStatus == .authorized,
			ZZZDatabase.viewContext.fetchCollection() == nil
		{ return InterfaceText._emptyLibraryMessage }
		return ""
	}
	private func newOverflowMenu() -> UIMenu {
		return UIMenu(title: newOverflowTitle(), children: [
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { [weak self] use in use([
					UIAction(title: InterfaceText.nowPlaying, image: UIImage(systemName: "waveform"), attributes: {
#if targetEnvironment(simulator)
						return []
#else
						guard
							let currentSongID = MPMusicPlayerController.nowPlayingID,
							nil != ZZZDatabase.viewContext.fetchSong(mpID: currentSongID)
						else { return .disabled }
						return []
#endif
					}()) { [weak self] _ in self?.albumsTVC?.referencee?.showCurrent() }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(
						title: InterfaceText.repeat1,
						image: UIImage(systemName: "repeat.1"),
						attributes: SystemMusicPlayer.isEmpty ? .disabled : [],
						state: {
							if
								let __player = MPMusicPlayerController._system,
								!SystemMusicPlayer.isEmpty,
								__player.repeatMode == .one
							{ return .on }
							return .off
						}()) { _ in
							guard let __player = MPMusicPlayerController._system else { return }
							if __player.repeatMode == .one {
								__player.repeatMode = MPMusicRepeatMode.none
							} else {
								__player.repeatMode = .one
							}
						}
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					// Ideally, disable this when there are no previous tracks to skip to.
					UIAction(title: InterfaceText.previous, image: UIImage(systemName: "backward.end"), attributes: SystemMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await SystemMusicPlayer._shared?.skipToPreviousEntry() } }
				])},
				UIDeferredMenuElement.uncached { use in use([
					// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
					UIAction(title: InterfaceText.restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: SystemMusicPlayer.isEmpty ? .disabled : []) { _ in SystemMusicPlayer._shared?.restartCurrentEntry() }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.next, image: UIImage(systemName: "forward.end"), attributes: SystemMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await SystemMusicPlayer._shared?.skipToNextEntry() } }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: SystemMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in SystemMusicPlayer._shared?.playbackTime -= 15 }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: SystemMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in SystemMusicPlayer._shared?.playbackTime += 15 }
				])},
			]),
		])
	}
}
