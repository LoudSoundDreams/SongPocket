// 2022-05-09

import UIKit
@preconcurrency import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class Remote {
	static let shared = Remote()
	let b_remote = UIBarButtonItem()
	weak var weak_tvc_albums: AlbumsTVC?
	
	private init() {
		refresh()
		NotificationCenter.default.add_observer_once(self, selector: #selector(refresh), name: PlayerState.musicKit, object: nil)
		NotificationCenter.default.add_observer_once(self, selector: #selector(refresh), name: AppleLibrary.did_merge, object: nil) // Because when MusicKit enters or exits the “Not Playing” state, it doesn’t emit “queue changed” events.
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
	private static let i_play = UIImage(systemName: "play.circle.fill")?.applying_hierarchical_tint()
	private static let i_pause = UIImage(systemName: "pause.circle.fill")?.applying_hierarchical_tint()
	
	private func title_menu() -> String {
		guard MusicAuthorization.currentStatus == .authorized else {
			return ""
		}
		guard let the_crate = Librarian.the_lrCrate, !the_crate.lrAlbums.isEmpty else {
			return InterfaceText._empty_library_message
		}
		return ""
	}
	private func menu() -> UIMenu {
		return UIMenu(title: title_menu(), children: [
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				dme_go_now_playing,
				Self.dme_toggle_repeat,
				Self.action_go_Apple_Music,
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				Self.dme_jump_backward,
				Self.dme_rewind,
				Self.dme_jump_forward,
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				Self.dme_track_previous,
				Self.dme_toggle_playing,
				Self.dme_track_next,
			]),
		])
	}
	
	private lazy var dme_go_now_playing = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Go_to_Album, image: UIImage(systemName: "square.stack"), attributes: {
#if targetEnvironment(simulator)
			return []
#else
			guard
				let id_current = MPMusicPlayerController.mpidSong_current,
				nil != Librarian.find_lrSong(mpid: id_current)
			else { return .disabled }
			return []
#endif
		}()) { [weak self] _ in self?.weak_tvc_albums?.show_current() }
	])}
	private static let action_go_Apple_Music = UIAction(title: InterfaceText.Open_Apple_Music, image: UIImage(systemName: "arrow.up.forward.app")) { _ in AppleLibrary.open_Apple_Music() }
	
	private static let dme_toggle_playing = UIDeferredMenuElement.uncached { use in
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
		let result = UIAction(title: InterfaceText.Play, image: UIImage(systemName: "play.fill"), attributes: .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.play() } }
		result.accessibilityTraits.formUnion(.startsMediaSession)
		return result
	}()
	private static let a_pause = UIAction(title: InterfaceText.Pause, image: UIImage(systemName: "pause.fill"), attributes: .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.pause() }
	
	private static let dme_toggle_repeat = UIDeferredMenuElement.uncached { use in use([
		UIAction(
			title: InterfaceText.Repeat_One,
			image: UIImage(systemName: "repeat.1"),
			attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented,
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
	])}
	
	private static let dme_rewind = UIDeferredMenuElement.uncached { use in
		let action = UIAction(title: InterfaceText.Restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.restartCurrentEntry() }
		if ApplicationMusicPlayer.is_empty { // Can we notice when `playbackTime` becomes or becomes not `0` while the menu is open?
			action.attributes.formUnion(.disabled)
		} else {
			action.attributes.subtract(.disabled)
		}
		use([action])
	}
	
	private static let dme_track_previous = UIDeferredMenuElement.uncached { use in use([
		// Ideally, disable this when there are no previous tracks to skip to.
		UIAction(title: InterfaceText.Previous, image: UIImage(systemName: "backward.end.fill"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToPreviousEntry() } }
	])}
	private static let dme_track_next = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Next, image: UIImage(systemName: "forward.end.fill"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToNextEntry() } }
	])}
	
	private static let dme_jump_backward = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Skip_back_15_seconds, image: UIImage(systemName: "gobackward.15"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime -= 15 }
	])}
	private static let dme_jump_forward = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Skip_forward_15_seconds, image: UIImage(systemName: "goforward.15"), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime += 15 }
	])}
}
