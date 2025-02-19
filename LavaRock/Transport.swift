// 2025-01-31

import SwiftUI

struct MenuTransport: View {
	var body: some View {
		Menu {
			ControlGroup {
				b_previous
				b_rewind
				b_repeat
				b_next
			}
			ControlGroup {
				b_jump_back
				b_play_pause
				b_artwork
				b_jump_forward
			}
		} label: {
			Image(systemName: LCD.shared.is_playing
				  ? SF.circle_pause : SF.circle_play)
			.symbolRenderingMode(.hierarchical)
		}
		.controlGroupStyle(.compactMenu)
		.menuOrder(.fixed)
		.disabled(is_selecting)
	}
	private var is_selecting: Bool {
		guard let spotlight = Global.shared.spotlight else { return false }
		switch spotlight.selection {
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
		.accessibilityAddTraits(.startsMediaSession)
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
			Image(systemName: SF.previous)
				.accessibilityLabel(InterfaceText.Previous)
		}
		.menuActionDismissBehavior(.disabled)
		.disabled(LCD.shared.is_blank || LCD.shared.is_at_first_track)
	}
	private var b_next: some View {
		Button {
			Tape.next()
		} label: {
			Image(systemName: SF.next)
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
	
	private var b_artwork: some View {
		Button {
			Global.shared.spotlight_artwork()
		} label: {
			Label(InterfaceText.Go_to_Artwork, systemImage: SF.photo)
		}.disabled({
#if targetEnvironment(simulator)
			return false
#else
			return nil == Librarian.album_containing_uSong_current()
#endif
		}())
	}
}
