// 2022-05-09

import UIKit
@preconcurrency import MusicKit
import MediaPlayer
import Combine

@MainActor @Observable final class PlayerState {
	@ObservationIgnored static let shared = PlayerState()
	var signal = false { didSet {
		Task { // We’re responding to `objectWillChange` events, which aren’t what we actually want. This might wait for the next turn of the run loop, when the value might actually have changed.
			NotificationCenter.default.post(name: Self.musicKit, object: nil)
		}
	}}
	private init() {}
	@ObservationIgnored private var cancellables: Set<AnyCancellable> = []
}
extension PlayerState {
	func observeMKPlayer() {
		ApplicationMusicPlayer._shared?.state.objectWillChange
			.sink { [weak self] in self?.signal.toggle() }
			.store(in: &cancellables)
		ApplicationMusicPlayer._shared?.queue.objectWillChange
			.sink { [weak self] in self?.signal.toggle() }
			.store(in: &cancellables)
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
		NotificationCenter.default.addObserver_once(self, selector: #selector(refresh), name: PlayerState.musicKit, object: nil)
		NotificationCenter.default.addObserver_once(self, selector: #selector(refresh), name: Librarian.didMerge, object: nil) // Because when MusicKit enters or exits the “Not Playing” state, it doesn’t emit “queue changed” events.
	}
	@objc private func refresh() {
		// Refresh menu title
		bRemote.preferredMenuElementOrder = .fixed
		bRemote.menu = menu()
		
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
	
	private func menuTitle() -> String {
		guard MusicAuthorization.currentStatus == .authorized else {
			return ""
		}
		guard nil != ZZZDatabase.viewContext.fetchCollection() else {
			return InterfaceText._messageEmpty
		}
		return ""
	}
	private func menu() -> UIMenu {
		return UIMenu(title: menuTitle(), children: [
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.nowPlaying, image: UIImage(systemName: "waveform"), attributes: {
#if targetEnvironment(simulator)
						return []
#else
						guard
							let idSong = MPMusicPlayerController.idSongCurrent,
							nil != ZZZDatabase.viewContext.fetchSong(mpID: idSong)
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
				Self.dmeRestart,
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.next, image: UIImage(systemName: "forward.end"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToNextEntry() } }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime -= 15 }
				])},
				Self.dmePlayPause,
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: ApplicationMusicPlayer.isEmpty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime += 15 }
				])},
			]),
		])
	}
	private static let dmeRestart = UIDeferredMenuElement.uncached { use in
		let action = UIAction(title: InterfaceText.restart, image: UIImage(systemName: "arrow.counterclockwise")) { _ in ApplicationMusicPlayer._shared?.restartCurrentEntry() }
		if ApplicationMusicPlayer.isEmpty { // Can we notice when `playbackTime` becomes or becomes not `0` while the menu is open?
			action.attributes.formUnion(.disabled)
		} else {
			action.attributes.subtract(.disabled)
		}
		use([action])
	}
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
	private static let aPlay: UIAction = {
		let result = UIAction(title: InterfaceText.play, image: UIImage(systemName: "play")) { _ in Task { try await ApplicationMusicPlayer._shared?.play() } }
		result.accessibilityTraits.formUnion(.startsMediaSession)
		return result
	}()
	private static let aPause = UIAction(title: InterfaceText.pause, image: UIImage(systemName: "pause")) { _ in ApplicationMusicPlayer._shared?.pause() }
	private static let aAppleMusic = UIAction(title: InterfaceText.appleMusic, image: UIImage(systemName: "arrow.up.forward.app")) { _ in Librarian.openAppleMusic() }
}
