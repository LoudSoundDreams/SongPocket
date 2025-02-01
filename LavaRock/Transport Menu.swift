// 2025-01-31

import SwiftUI

struct MenuTransport: View {
	var body: some View {
		Menu {
			ControlGroup {
				b_spotlight
				b_repeat
				b_apple_music
			} label: {
				let _ = Global.shared.librarian_is_merging
				if let message = Librarian.message_if_empty {
					Text(message)
				}
			}
			ControlGroup {
				b_jump_back
				b_rewind
				b_jump_forward
			}
			ControlGroup {
				b_previous
				b_play_pause
				b_next
			}
		} label: {
			Image(
				systemName: LCD.shared.is_playing
				? SF.circle_pause : SF.circle_play)
			.symbolRenderingMode(.hierarchical)
		}
		.menuOrder(.fixed)
		.controlGroupStyle(.compactMenu)
		.disabled(is_selecting)
	}
	private var is_selecting: Bool {
		guard let showcase = Global.shared.showcase else { return false }
		switch showcase.selection {
			case .view: return false
			case .mode_albums, .mode_songs: return true
		}
	}
	
	private var b_play_pause: some View {
		Button {
			if LCD.shared.is_playing {
				Tape.pause()
			} else {
				Task {
					await Tape.resume()
				}
			}
		} label: {
			Image(
				systemName: LCD.shared.is_playing
				? SF.pause_bold : SF.play_bold)
			.accessibilityLabel(
				LCD.shared.is_playing
				? InterfaceText.Pause : InterfaceText.Play)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank)
	}
	
	private var b_rewind: some View {
		Button {
			Tape.rewind()
		} label: {
			Image(systemName: SF.rewind)
				.accessibilityLabel(InterfaceText.Restart)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank) // Can we notice when `playbackTime` becomes or becomes not `0` while the menu is open?
	}
	
	private var b_previous: some View {
		Button {
			Tape.previous()
		} label: {
			Image(systemName: SF.previous_bold)
				.accessibilityLabel(InterfaceText.Previous)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank) // 2do: Disable when there are no previous tracks to skip to.
	}
	private var b_next: some View {
		Button {
			Tape.next()
		} label: {
			Image(systemName: SF.next_bold)
				.accessibilityLabel(InterfaceText.Next)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank)
	}
	
	private var b_jump_back: some View {
		Button {
			Tape.jump_back_15()
		} label: {
			Image(systemName: SF.jump_back_15)
				.accessibilityLabel(InterfaceText.Skip_back_15_seconds)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank)
	}
	private var b_jump_forward: some View {
		Button {
			Tape.jump_forward_15()
		} label: {
			Image(systemName: SF.jump_forward_15)
				.accessibilityLabel(InterfaceText.Skip_forward_15_seconds)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank)
	}
	
	private var b_repeat: some View {
		Button {
			if LCD.shared.repeat_is_on {
				Tape.repeat_off()
			} else {
				Tape.repeat_1()
			}
		} label: {
			Label(
				{ () -> String in
					var segments: [String] = []
					if LCD.shared.repeat_is_on { segments.append(InterfaceText.Selected) }
					segments.append(InterfaceText.Repeat_One)
					return segments.formatted(.list(type: .and, width: .narrow))
				}(),
				systemImage: LCD.shared.repeat_is_on
				? SF.circle_repeat_1 : SF.repeat_1)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank)
	}
	
	private var b_spotlight: some View {
		Button {
			Global.shared.gallery?.spotlight_current()
		} label: {
			Label(InterfaceText.Go_to_Artwork, systemImage: SF.photo_fill)
		}.disabled({
			guard
				let current = LCD.shared.uSong_current, // As of iOS 18.3 RC, mentioning this triggers a redraw if we delete or re-add the current song, because that makes Media Player post a notification “now-playing item changed”.
				Librarian.uSongs_known.contains(current)
			else { return true }
			return false
		}())
	}
	
	private var b_apple_music: some View {
		Button {
			AppleCatalog.open_Apple_Music()
		} label: {
			Label(InterfaceText.Apple_Music, systemImage: SF.app_external)
		}
	}
}
