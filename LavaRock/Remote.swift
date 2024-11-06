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
	func observe_mkPlayer() {
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
	let b_remote = UIBarButtonItem()
	var tvc_albums: WeakRef<AlbumsTVC>? = nil
	
	private init() {
		refresh()
		NotificationCenter.default.add_observer_once(self, selector: #selector(refresh), name: PlayerState.musicKit, object: nil)
		NotificationCenter.default.add_observer_once(self, selector: #selector(refresh), name: Librarian.did_merge, object: nil) // Because when MusicKit enters or exits the “Not Playing” state, it doesn’t emit “queue changed” events.
	}
	@objc private func refresh() {
		// Refresh menu title
		b_remote.preferredMenuElementOrder = .fixed
		b_remote.menu = menu()
		
		// Make button reflect playback status
#if targetEnvironment(simulator)
		show_pause()
#else
		guard
			let player = ApplicationMusicPlayer._shared,
			!ApplicationMusicPlayer.is_empty
		else {
			show_play()
			return
		}
		if player.state.playbackStatus == .playing {
			show_pause()
		} else {
			show_play()
		}
#endif
	}
	private func show_play() {
		b_remote.image = Self.i_play
	}
	private func show_pause() {
		b_remote.image = Self.i_pause
	}
	private static let i_play = UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))
	private static let i_pause = UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))
	
	private func title_menu() -> String {
		guard MusicAuthorization.currentStatus == .authorized else {
			return ""
		}
		guard nil != ZZZDatabase.viewContext.fetch_collection() else {
			return InterfaceText._message_empty
		}
		return ""
	}
	private func menu() -> UIMenu {
		return UIMenu(title: title_menu(), children: [
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.Now_Playing, image: UIImage(systemName: "waveform"), attributes: {
#if targetEnvironment(simulator)
						return []
#else
						guard
							let id_song = MPMusicPlayerController.mpidSong_current,
							nil != ZZZDatabase.viewContext.fetch_song(mpidSong: id_song)
						else { return .disabled }
						return []
#endif
					}()) { [weak self] _ in self?.tvc_albums?.referencee?.show_current() }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(
						title: InterfaceText.Repeat_One,
						image: UIImage(systemName: "repeat.1"),
						attributes: ApplicationMusicPlayer.is_empty ? .disabled : [],
						state: {
							guard
								!ApplicationMusicPlayer.is_empty,
								let repeat_mode = ApplicationMusicPlayer._shared?.state.repeatMode,
								repeat_mode == .one
							else { return .off }
							return .on
						}()) { _ in
							guard
								let player = ApplicationMusicPlayer._shared,
								let repeat_mode = player.state.repeatMode
							else { return }
							if repeat_mode == .one {
								player.state.repeatMode = MusicPlayer.RepeatMode.none
							} else {
								player.state.repeatMode = .one
							}
						}
				])},
				Self.a_Apple_Music,
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					// Ideally, disable this when there are no previous tracks to skip to.
					UIAction(title: InterfaceText.Previous, image: UIImage(systemName: "backward.end"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToPreviousEntry() } }
				])},
				Self.dme_restart,
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.Next, image: UIImage(systemName: "forward.end"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToNextEntry() } }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.Skip_back_15_seconds, image: UIImage(systemName: "gobackward.15"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime -= 15 }
				])},
				Self.dme_play_pause,
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.Skip_forward_15_seconds, image: UIImage(systemName: "goforward.15"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime += 15 }
				])},
			]),
		])
	}
	private static let dme_restart = UIDeferredMenuElement.uncached { use in
		let action = UIAction(title: InterfaceText.Restart, image: UIImage(systemName: "arrow.counterclockwise")) { _ in ApplicationMusicPlayer._shared?.restartCurrentEntry() }
		if ApplicationMusicPlayer.is_empty { // Can we notice when `playbackTime` becomes or becomes not `0` while the menu is open?
			action.attributes.formUnion(.disabled)
		} else {
			action.attributes.subtract(.disabled)
		}
		use([action])
	}
	private static let dme_play_pause = UIDeferredMenuElement.uncached { use in
#if targetEnvironment(simulator)
		use([a_pause])
#else
		if ApplicationMusicPlayer._shared?.state.playbackStatus == .playing {
			use([a_pause])
		} else {
			let action = a_play
			if ApplicationMusicPlayer.is_empty {
				action.attributes.formUnion(.disabled)
			} else {
				action.attributes.subtract(.disabled)
			}
			use([action])
		}
#endif
	}
	private static let a_play: UIAction = {
		let result = UIAction(title: InterfaceText.Play, image: UIImage(systemName: "play")) { _ in Task { try await ApplicationMusicPlayer._shared?.play() } }
		result.accessibilityTraits.formUnion(.startsMediaSession)
		return result
	}()
	private static let a_pause = UIAction(title: InterfaceText.Pause, image: UIImage(systemName: "pause")) { _ in ApplicationMusicPlayer._shared?.pause() }
	private static let a_Apple_Music = UIAction(title: InterfaceText.Apple_Music, image: UIImage(systemName: "arrow.up.forward.app")) { _ in Librarian.open_Apple_Music() }
}
