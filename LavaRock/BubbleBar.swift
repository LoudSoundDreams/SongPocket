// 2025-01-25

import SwiftUI
@preconcurrency import MusicKit

struct BubbleBar: View {
	var body: some View {
		HStack(spacing: .zero) {
			MenuSort()
				.padding(.trailing, .eight * 3/2)
			MenuTransport()
				.padding(.trailing, .eight * 3/2)
			MenuOverflow()
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(.eight)
		.background(Material.bar, in: .capsule)
	}
}

// MARK: Sort

private struct MenuSort: View {
	var body: some View {
		Menu {
		} label: {
			Image(systemName: SF.sort)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.Sort)
		}.menuOrder(.fixed)
	}
}

// MARK: Transport

private struct MenuTransport: View {
	var body: some View {
		Menu {
			ControlGroup {
				Button {
					Global.shared.showcase?.tvc_weak?.go_to_artwork()
				} label: {
					Label(InterfaceText.Go_to_Artwork, systemImage: SF.photo)
				}
				
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
						? "repeat.1.circle.fill" : SF.repeat_1)
				}
				.menuActionDismissBehavior(.disabled)
				.disabled(LCD.shared.is_blank)
				
				Button {
					AppleCatalog.open_Apple_Music()
				} label: {
					Label(InterfaceText.Apple_Music, systemImage: SF.app_external)
				}
			}
			
			ControlGroup {
				Button {
					Tape.jump_back_15()
				} label: {
					Image(systemName: SF.jump_back_15)
						.accessibilityLabel(InterfaceText.Skip_back_15_seconds)
				}
				.menuActionDismissBehavior(.disabled)
				.disabled(LCD.shared.is_blank)
				
				Button {
					Tape.rewind()
				} label: {
					Image(systemName: SF.rewind)
						.accessibilityLabel(InterfaceText.Restart)
				}
				.menuActionDismissBehavior(.disabled)
				.disabled(LCD.shared.is_blank)
				
				Button {
					Tape.jump_forward_15()
				} label: {
					Image(systemName: SF.jump_forward_15)
						.accessibilityLabel(InterfaceText.Skip_forward_15_seconds)
				}
				.menuActionDismissBehavior(.disabled)
				.disabled(LCD.shared.is_blank)
			}
			
			ControlGroup {
				Button {
					Tape.previous()
				} label: {
					Image(systemName: SF.previous_bold)
						.accessibilityLabel(InterfaceText.Previous)
				}
				.menuActionDismissBehavior(.disabled)
				.disabled(LCD.shared.is_blank)
				
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
				
				Button {
					Tape.next()
				} label: {
					Image(systemName: SF.next_bold)
						.accessibilityLabel(InterfaceText.Next)
				}
				.menuActionDismissBehavior(.disabled)
				.disabled(LCD.shared.is_blank)
			}
		} label: {
			Image(
				systemName: LCD.shared.is_playing
				? SF.pause_circle : SF.play_circle)
			.symbolRenderingMode(.hierarchical)
		}
		.menuOrder(.fixed)
		.controlGroupStyle(.compactMenu)
	}
}

// MARK: Overflow

private struct MenuOverflow: View {
	var body: some View {
		Menu {
		} label: {
			Image(systemName: SF.ellipsis)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.More)
		}.menuOrder(.fixed)
	}
}
