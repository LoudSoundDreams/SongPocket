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
	let bRemote = UIBarButtonItem()
	var albumsTVC: WeakRef<AlbumsTVC>? = nil
	
	private init() {
		refresh()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: PlayerState.musicKit, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: Librarian.didMerge, object: nil) // Because when MusicKit enters or exits the “Not Playing” state, it doesn’t emit “queue changed” events.
	}
	@objc private func refresh() {
		// Refresh menu title
		bRemote.preferredMenuElementOrder = .fixed
		bRemote.menu = newMenu()
		
		// Make button reflect playback status
#if targetEnvironment(simulator)
		showPause()
#else
		guard
			let player = ApplicationMusicPlayer._shared,
			!ApplicationMusicPlayer.isEmpty
		else {
			showPlay()
			return
		}
		if player.state.playbackStatus == .playing {
			showPause()
		} else {
			showPlay()
		}
#endif
	}
	private func showPlay() {
		bRemote.image = Self.iPlay
	}
	private func showPause() {
		bRemote.image = Self.iPause
	}
	private static let iPlay = UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))
	private static let iPause = UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))
	
	private func newMenuTitle() -> String {
		guard MusicAuthorization.currentStatus == .authorized else {
			return ""
		}
		guard nil != ZZZDatabase.viewContext.fetchCollection() else {
			return InterfaceText._emptyLibraryMessage
		}
		return ""
	}
	private func newMenu() -> UIMenu {
		return UIMenu(title: newMenuTitle(), children: [
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
							guard
								!ApplicationMusicPlayer.isEmpty,
								let repeatMode = ApplicationMusicPlayer._shared?.state.repeatMode,
								repeatMode == .one
							else { return .off }
							return .on
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
				Self.aAppleMusic,
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					// Ideally, disable this when there are no previous tracks to skip to.
					UIAction(title: InterfaceText.previous, image: UIImage(systemName: "backward.end"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToPreviousEntry() } }
				])},
				Self.dmePlayPause,
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.next, image: UIImage(systemName: "forward.end"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToNextEntry() } }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime -= 15 }
				])},
				Self.dmeRestart,
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime += 15 }
				])},
			]),
		])
	}
	private static let dmeRestart = UIDeferredMenuElement.uncached { use in use([
		// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
		UIAction(title: InterfaceText.restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : []) { _ in ApplicationMusicPlayer._shared?.restartCurrentEntry() }
	])}
	private static let dmePlayPause = UIDeferredMenuElement.uncached { use in
#if targetEnvironment(simulator)
		use([aPause])
#else
		if ApplicationMusicPlayer._shared?.state.playbackStatus == .playing {
			use([aPause])
		} else {
			let action = aPlay
			if ApplicationMusicPlayer.isEmpty {
				action.attributes.formUnion(.disabled)
			} else {
				action.attributes.subtract(.disabled)
			}
			use([action])
		}
#endif
	}
	private static let aPlay = UIAction(title: InterfaceText.play, image: UIImage(systemName: "play")) { _ in Task { try await ApplicationMusicPlayer._shared?.play() } }
	private static let aPause = UIAction(title: InterfaceText.pause, image: UIImage(systemName: "pause")) { _ in ApplicationMusicPlayer._shared?.pause() }
	private static let aAppleMusic = UIAction(title: InterfaceText.appleMusic, image: UIImage(systemName: "arrow.up.forward.app")) { _ in Librarian.openAppleMusic() }
}
