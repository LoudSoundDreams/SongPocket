// 2022-05-09

import UIKit
@preconcurrency import MusicKit
import MediaPlayer
import Combine

@MainActor @Observable final class PlayerState {
	@ObservationIgnored static let shared = PlayerState()
	var signal = false
	private init() {}
	@ObservationIgnored private var cancellables: Set<AnyCancellable> = []
}
extension PlayerState {
	func observeMKPlayer() {
		ApplicationMusicPlayer._shared?.state.objectWillChange
			.sink { [weak self] in
				self?.signal.toggle()
				NotificationCenter.default.post(name: Self.musicKit, object: nil)
			}.store(in: &cancellables)
		ApplicationMusicPlayer._shared?.queue.objectWillChange
			.sink { [weak self] in
				self?.signal.toggle()
				NotificationCenter.default.post(name: Self.musicKit, object: nil)
			}.store(in: &cancellables)
	}
	static let musicKit = Notification.Name("LRMusicKitPlayerStateOrQueue")
}

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class Remote {
	static let shared = Remote()
	let playPauseButton = UIBarButtonItem()
	let overflowButton = UIBarButtonItem()
	var albumsTVC: WeakRef<AlbumsTVC>? = nil
	
	private init() {
		refresh()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: PlayerState.musicKit, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: Librarian.didMerge, object: nil) // Because when MusicKit enters or exits the “Not Playing” state, it doesn’t emit “queue changed” events.
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
			let player = ApplicationMusicPlayer._shared,
			!ApplicationMusicPlayer.isEmpty
		else {
			showPlay()
			
			playPauseButton.isEnabled = false
			playPauseButton.accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
			
			return
		}
		
		playPauseButton.isEnabled = true
		playPauseButton.accessibilityTraits.subtract(.notEnabled)
		
		if player.state.playbackStatus == .playing {
			showPause()
		} else {
			showPlay()
		}
#endif
	}
	private func showPlay() {
		playPauseButton.title = InterfaceText.play
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in Task { try await ApplicationMusicPlayer._shared?.play() } }
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = InterfaceText.pause
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in ApplicationMusicPlayer._shared?.pause() }
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
			!ApplicationMusicPlayer.isEmpty,
			let repeatMode = ApplicationMusicPlayer._shared?.state.repeatMode
		{
			switch repeatMode { // As of iOS 18, this is unreliable; it sometimes returns `.none` even if the Apple Music app shows “repeat one”.
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
						attributes: ApplicationMusicPlayer.isEmpty ? .disabled : [],
						state: {
							if
								!ApplicationMusicPlayer.isEmpty,
								ApplicationMusicPlayer._shared?.state.repeatMode == .one
							{ return .on }
							return .off
						}()) { _ in
							guard
								let player = ApplicationMusicPlayer._shared,
								let repeatMode = player.state.repeatMode
							else { return }
							if repeatMode == .one {
								player.state.repeatMode = MusicPlayer.RepeatMode.none
							} else {
								player.state.repeatMode = .one
							}
						}
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					// Ideally, disable this when there are no previous tracks to skip to.
					UIAction(title: InterfaceText.previous, image: UIImage(systemName: "backward.end"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToPreviousEntry() } }
				])},
				UIDeferredMenuElement.uncached { use in use([
					// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
					UIAction(title: InterfaceText.restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : []) { _ in ApplicationMusicPlayer._shared?.restartCurrentEntry() }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.next, image: UIImage(systemName: "forward.end"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToNextEntry() } }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime -= 15 }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime += 15 }
				])},
			]),
		])
	}
}
