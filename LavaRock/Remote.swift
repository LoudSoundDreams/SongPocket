// 2022-05-09

import UIKit
@preconcurrency import MusicKit

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class Remote {
	static let shared = Remote()
	let b_remote = UIBarButtonItem()
	weak var tvc_weak: ExhibitTVC?
	
	private init() {
		refresh()
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .player_state, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .librarian_merged, object: nil) // Because when MusicKit enters or exits the “Not Playing” state, it doesn’t emit “queue changed” events.
	}
	@objc private func refresh() {
		// Refresh menu title
		b_remote.preferredMenuElementOrder = .fixed
		b_remote.menu = menu()
		
		// Make button reflect playback status
#if targetEnvironment(simulator)
		show_pause()
#else
		guard !ApplicationMusicPlayer.is_empty else {
			show_play()
			return
		}
		if PlayerState.shared.is_playing {
			show_pause()
		} else {
			show_play()
		}
#endif
	}
	private func show_play() {
		b_remote.image = image_play
	}
	private func show_pause() {
		b_remote.image = image_pause
	}
	private let image_play = UIImage(systemName: SF.play_circle)!.applying_hierarchical_tint()
	private let image_pause = UIImage(systemName: SF.pause_circle)!.applying_hierarchical_tint()
	
	private func title_menu() -> String {
		guard MusicAuthorization.currentStatus == .authorized
		else { return "" }
		guard !Librarian.the_albums.isEmpty
		else { return InterfaceText._empty_library_message }
		return ""
	}
	private func menu() -> UIMenu {
		return UIMenu(title: title_menu(), children: [
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				dme_go_to_artwork,
				Self.dme_repeat,
				Self.action_open_Apple_Music,
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
	
	private lazy var dme_go_to_artwork = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Go_to_Artwork, image: UIImage(systemName: SF.photo), attributes: {
#if targetEnvironment(simulator)
			return []
#else
			guard
				let current = PlayerState.shared.uSong_current,
				Librarian.uSongs_known.contains(current)
			else { return .disabled }
			return []
#endif
		}()) { [weak self] _ in self?.tvc_weak?.go_to_artwork() }
	])}
	private static let action_open_Apple_Music = UIAction(title: InterfaceText.Apple_Music, image: UIImage(systemName: SF.app_external)) { _ in AppleCatalog.open_Apple_Music() }
	
	private static let dme_toggle_playing = UIDeferredMenuElement.uncached { use in
#if targetEnvironment(simulator)
		use([a_pause])
#else
		if PlayerState.shared.is_playing {
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
		let result = UIAction(title: InterfaceText.Play, image: UIImage(systemName: SF.play_bold), attributes: .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.play() } }
		result.accessibilityTraits.formUnion(.startsMediaSession)
		return result
	}()
	private static let a_pause = UIAction(title: InterfaceText.Pause, image: UIImage(systemName: SF.pause_bold), attributes: .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.pause() }
	
	private static let dme_repeat = UIDeferredMenuElement.uncached { use in
		let action = UIAction(
			title: { // As of iOS 18.3 RC, with `preferredElementSize: .small`, VoiceOver never says “selected”.
				var segments: [String] = []
				if repeat_is_on { segments.append(InterfaceText.Selected) }
				segments.append(InterfaceText.Repeat_One)
				return segments.formatted(.list(type: .and, width: .narrow))
			}(),
			image: UIImage(systemName: SF.repeat_1),
			attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented,
			state: {
				if repeat_is_on
				{ return .on }
				return .off
			}()
		) { _ in
			guard let player = ApplicationMusicPlayer._shared else { return }
			if repeat_is_on {
				player.state.repeatMode = MusicPlayer.RepeatMode.none
			} else {
				player.state.repeatMode = .one
			}
		}
		use([action])
	}
	static var repeat_is_on: Bool {
		guard
			let player = ApplicationMusicPlayer._shared,
			let mode = player.state.repeatMode
		else { return false }
		return mode == .one
	}
	
	private static let dme_rewind = UIDeferredMenuElement.uncached { use in
		let action = UIAction(title: InterfaceText.Restart, image: UIImage(systemName: SF.rewind), attributes: .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.restartCurrentEntry() }
		if ApplicationMusicPlayer.is_empty { // Can we notice when `playbackTime` becomes or becomes not `0` while the menu is open?
			action.attributes.formUnion(.disabled)
		} else {
			action.attributes.subtract(.disabled)
		}
		use([action])
	}
	
	private static let dme_track_previous = UIDeferredMenuElement.uncached { use in use([
		// Ideally, disable this when there are no previous tracks to skip to.
		UIAction(title: InterfaceText.Previous, image: UIImage(systemName: SF.previous_bold), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToPreviousEntry() } }
	])}
	private static let dme_track_next = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Next, image: UIImage(systemName: SF.next_bold), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in Task { try await ApplicationMusicPlayer._shared?.skipToNextEntry() } }
	])}
	
	private static let dme_jump_backward = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Skip_back_15_seconds, image: UIImage(systemName: SF.jump_back_15), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime -= 15 }
	])}
	private static let dme_jump_forward = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Skip_forward_15_seconds, image: UIImage(systemName: SF.jump_forward_15), attributes: ApplicationMusicPlayer.is_empty ? .disabled : .keepsMenuPresented) { _ in ApplicationMusicPlayer._shared?.playbackTime += 15 }
	])}
}
