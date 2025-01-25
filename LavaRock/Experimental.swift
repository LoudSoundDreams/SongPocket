// 2024-04-04

import SwiftUI
@preconcurrency import MusicKit

struct BubbleBar: View {
	var body: some View {
		HStack(alignment: .bottom) {
			Menu {
			} label: {
				Image(systemName: "arrow.up.arrow.down.circle.fill")
			}
			.padding(.trailing)
			
			Menu {
				let _ = PlayerState.shared.signal
				
				ControlGroup {
					Button {
						Global.shared.showcase?.tvc_weak?.go_to_artwork()
					} label: {
						Label(InterfaceText.Go_to_Artwork, systemImage: "photo")
					}
					Button {
						guard let player = ApplicationMusicPlayer._shared else { return }
						if Remote.repeat_is_on {
							player.state.repeatMode = MusicPlayer.RepeatMode.none
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
							? "repeat.1.circle.fill"
							: "repeat.1")
					}
					Button {
						AppleCatalog.open_Apple_Music()
					} label: {
						Label(InterfaceText.Apple_Music, systemImage: "arrow.up.forward.app")
					}
				}
				ControlGroup {
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
						Label(
							{
								if
									let player = ApplicationMusicPlayer._shared,
									player.state.playbackStatus == .playing
								{ return InterfaceText.Pause }
								return InterfaceText.Play
							}(),
							systemImage: {
								if
									let player = ApplicationMusicPlayer._shared,
									player.state.playbackStatus == .playing
								{ return "pause.fill" }
								return "play.fill"
							}())
					}
				}
			} label: {
				Image(systemName: {
					if
						let player = ApplicationMusicPlayer._shared,
						player.state.playbackStatus == .playing
					{ return "pause.circle.fill" }
					return "play.circle.fill"
				}())
			}
			.controlGroupStyle(.compactMenu)
			.padding(.trailing)
			
			Menu {
			} label: {
				Image(systemName: "ellipsis.circle.fill")
					.accessibilityLabel(InterfaceText.More)
			}
		}
		.symbolRenderingMode(.hierarchical)
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.menuOrder(.fixed)
		.padding(.eight)
		.background(Material.bar, in: .capsule)
	}
}

private extension View {
	func reacting(_ active: Bool) -> some View {
		return self
			.overlay {
				Color.black.opacity(active ? .one_fourth : .zero)
			}
			.animation(active ? nil : .linear_quick(), value: active)
	}
}
