// 2025-01-25

import SwiftUI
@preconcurrency import MusicKit

struct BubbleBar: View {
	var body: some View {
		HStack {
			MenuSort()
				.padding(.trailing)
			MenuTransport()
				.padding(.trailing)
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
					guard let player = ApplicationMusicPlayer._shared else { return }
					if Remote.repeat_is_on {
						player.state.repeatMode = ApplicationMusicPlayer.RepeatMode.none
					} else {
						player.state.repeatMode = .one
					}
				} label: {
					Label(
						{ () -> String in
							var segments: [String] = []
							if Remote.repeat_is_on { segments.append(InterfaceText.Selected) }
							segments.append(InterfaceText.Repeat_One)
							return segments.formatted(.list(type: .and, width: .narrow))
						}(),
						systemImage: Remote.repeat_is_on
						? "repeat.1.circle.fill" : SF.repeat_1)
				}
				Button {
					AppleCatalog.open_Apple_Music()
				} label: {
					Label(InterfaceText.Apple_Music, systemImage: SF.app_external)
				}
			}
			ControlGroup {
				Button {
				} label: {
					Image(systemName: SF.jump_back_15)
						.accessibilityLabel(InterfaceText.Skip_back_15_seconds)
				}
				Button {
				} label: {
					Image(systemName: SF.rewind)
						.accessibilityLabel(InterfaceText.Restart)
				}
				Button {
				} label: {
					Image(systemName: SF.jump_forward_15)
						.accessibilityLabel(InterfaceText.Skip_forward_15_seconds)
				}
			}
			ControlGroup {
				Button {
				} label: {
					Image(systemName: SF.previous_bold)
						.accessibilityLabel(InterfaceText.Previous)
				}
				Button {
					Task {
						guard let player = ApplicationMusicPlayer._shared else { return }
						if player.state.playbackStatus == .playing {
							player.pause()
						} else {
							try? await player.play()
						}
					}
				} label: {
					Image(systemName: {
						if
							let player = ApplicationMusicPlayer._shared,
							player.state.playbackStatus == .playing
						{ return SF.pause_bold }
						return SF.play_bold
					}())
					.accessibilityLabel({
						if
							let player = ApplicationMusicPlayer._shared,
							player.state.playbackStatus == .playing
						{ return InterfaceText.Pause }
						return InterfaceText.Play
					}())
				}
				Button {
				} label: {
					Image(systemName: SF.next_bold)
						.accessibilityLabel(InterfaceText.Next)
				}
			}
		} label: {
			Image(systemName: {
				if
					let player = ApplicationMusicPlayer._shared,
					player.state.playbackStatus == .playing
				{ return SF.pause_circle }
				return SF.play_circle
			}())
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
