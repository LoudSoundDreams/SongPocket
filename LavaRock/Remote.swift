// 2022-05-09

import UIKit
@preconcurrency import MusicKit

@MainActor final class Remote {
	static let shared = Remote()
	let b_remote = UIBarButtonItem()
	
	private init() {
		refresh()
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .lcd, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .librarian_merged, object: nil)
	}
	@objc private func refresh() {
		b_remote.preferredMenuElementOrder = .fixed
		b_remote.menu = menu() // Refreshes menu title.
		
		// Make button reflect playback status
#if targetEnvironment(simulator)
		show_pause()
#else
		guard !LCD.shared.is_blank else {
			show_play()
			return
		}
		if LCD.shared.is_playing {
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
	
	private func menu() -> UIMenu {
		return UIMenu(
			title: Librarian.message_if_empty ?? "",
			children: [
				UIMenu(options: .displayInline, preferredElementSize: .small, children: [
					dme_spotlight,
					Self.dme_repeat,
					Self.action_apple_music,
				]),
				UIMenu(options: .displayInline, preferredElementSize: .small, children: [
					Self.dme_jump_back,
					Self.dme_rewind,
					Self.dme_jump_forward,
				]),
				UIMenu(options: .displayInline, preferredElementSize: .small, children: [
					Self.dme_previous,
					Self.dme_play_pause,
					Self.dme_next,
				]),
			])
	}
	
	private lazy var dme_spotlight = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Go_to_Artwork, image: UIImage(systemName: SF.photo), attributes: {
#if targetEnvironment(simulator)
			return []
#else
			guard
				let current = LCD.shared.uSong_current,
				Librarian.uSongs_known.contains(current)
			else { return .disabled }
			return []
#endif
		}()) { _ in Global.shared.gallery?.spotlight_current() }
	])}
	private static let action_apple_music = UIAction(title: InterfaceText.Apple_Music, image: UIImage(systemName: SF.app_external)) { _ in AppleCatalog.open_Apple_Music() }
	
	private static let dme_play_pause = UIDeferredMenuElement.uncached { use in
#if targetEnvironment(simulator)
		use([a_pause])
#else
		if LCD.shared.is_playing {
			use([a_pause])
		} else {
			let action = a_resume
			if LCD.shared.is_blank {
				action.attributes.formUnion(.disabled)
			} else {
				action.attributes.subtract(.disabled)
			}
			use([action])
		}
#endif
	}
	private static let a_resume: UIAction = {
		let result = UIAction(title: InterfaceText.Play, image: UIImage(systemName: SF.play_bold), attributes: .keepsMenuPresented) { _ in Task { await Tape.resume() } }
		result.accessibilityTraits.formUnion(.startsMediaSession)
		return result
	}()
	private static let a_pause = UIAction(title: InterfaceText.Pause, image: UIImage(systemName: SF.pause_bold), attributes: .keepsMenuPresented) { _ in Tape.pause() }
	
	private static let dme_repeat = UIDeferredMenuElement.uncached { use in
		let action = UIAction(
			title: { // As of iOS 18.3 RC, with `preferredElementSize: .small`, VoiceOver never says “selected”.
				var segments: [String] = []
				if LCD.shared.repeat_is_on { segments.append(InterfaceText.Selected) }
				segments.append(InterfaceText.Repeat_One)
				return segments.formatted(.list(type: .and, width: .narrow))
			}(),
			image: UIImage(systemName: SF.repeat_1),
			attributes: LCD.shared.is_blank ? .disabled : .keepsMenuPresented,
			state: LCD.shared.repeat_is_on ? .on : .off
		) { _ in
			if LCD.shared.repeat_is_on {
				Tape.repeat_off()
			} else {
				Tape.repeat_1()
			}
		}
		use([action])
	}
	
	private static let dme_rewind = UIDeferredMenuElement.uncached { use in
		let action = UIAction(title: InterfaceText.Restart, image: UIImage(systemName: SF.rewind), attributes: .keepsMenuPresented) { _ in Tape.rewind() }
		if LCD.shared.is_blank {
			action.attributes.formUnion(.disabled)
		} else {
			action.attributes.subtract(.disabled)
		}
		use([action])
	}
	
	private static let dme_previous = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Previous, image: UIImage(systemName: SF.previous_bold), attributes: LCD.shared.is_blank ? .disabled : .keepsMenuPresented) { _ in Tape.previous() }
	])}
	private static let dme_next = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Next, image: UIImage(systemName: SF.next_bold), attributes: LCD.shared.is_blank ? .disabled : .keepsMenuPresented) { _ in Tape.next() }
	])}
	
	private static let dme_jump_back = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Skip_back_15_seconds, image: UIImage(systemName: SF.jump_back_15), attributes: LCD.shared.is_blank ? .disabled : .keepsMenuPresented) { _ in Tape.jump_back_15() }
	])}
	private static let dme_jump_forward = UIDeferredMenuElement.uncached { use in use([
		UIAction(title: InterfaceText.Skip_forward_15_seconds, image: UIImage(systemName: SF.jump_forward_15), attributes: LCD.shared.is_blank ? .disabled : .keepsMenuPresented) { _ in Tape.jump_forward_15() }
	])}
}
