// 2025-01-25

import SwiftUI
@preconcurrency import MusicKit

struct BubbleBar: View {
	static let width_border: CGFloat = .eight * 3/4
	
	var body: some View {
		HStack(spacing: .zero) {
			MenuSort()
			Spacer()
			MenuTransport()
			Spacer()
			MenuOverflow()
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(Self.width_border)
		.background(Material.bar, in: .capsule)
	}
}

// MARK: Sort

private struct MenuSort: View {
	var body: some View {
		Menu { if let exhibit = Global.shared.showcase {
			switch exhibit.focus {
				case .spotlight: EmptyView()
				case .covers: commands_albums
				case .expanded: commands_songs
			}
			
			ControlGroup {
				Button {
				} label: {
					Image(systemName: SF.to_top)
						.accessibilityLabel(InterfaceText.To_Top)
				}
				
				Button {
				} label: {
					Image(systemName: "arrow.up")
						.accessibilityLabel(InterfaceText.Move_Up)
				}.menuActionDismissBehavior(.disabled)
				
				Button {
				} label: {
					Image(systemName: "arrow.down")
						.accessibilityLabel(InterfaceText.Move_Down)
				}.menuActionDismissBehavior(.disabled)
				
				Button {
				} label: {
					Image(systemName: SF.to_bottom)
						.accessibilityLabel(InterfaceText.To_Bottom)
				}
			}
			.controlGroupStyle(.compactMenu)
			.disabled({
				switch exhibit.selection {
					case .view: return true
					case .mode_albums(let uAs_selected):
						return uAs_selected.isEmpty
					case .mode_songs(let uSs_selected):
						return uSs_selected.isEmpty
				}
			}())
		}} label: {
			Image(systemName: SF.sort)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.Sort)
		}.menuOrder(.fixed)
	}
	
	private var commands_albums: some View {
		ForEach(Self.albumOrders_groups, id: \.self) { group in
			Section { ForEach(group, id: \.self) { order in
				Button {
				} label: {
					Label(order.name, systemImage: order.sf_symbol)
				}
			}}
		}
	}
	private static let albumOrders_groups: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
	
	private var commands_songs: some View {
		ForEach(Self.songOrders_groups, id: \.self) { group in
			Section { ForEach(group, id: \.self) { order in
				Button {
				} label: {
					Label(order.name, systemImage: order.sf_symbol)
				}
			}}
		}
	}
	private static let songOrders_groups: [[SongOrder]] = [[.track], [.reverse, .random]]
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
				}.disabled({
					guard
						let current = LCD.shared.uSong_current, // As of iOS 18.3 RC, mentioning this triggers a redraw if we delete or re-add the current song, because that makes Media Player post a notification “now-playing item changed”.
						Librarian.uSongs_known.contains(current)
					else { return true }
					return false
				}())
				
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
			} label: {
				let _ = AppleCatalog.shared.is_merging
				if let message = Librarian.message_if_empty {
					Text(message)
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
		.disabled(is_selecting)
//		.animation(.default, value: is_selecting) // 2do
	}
	private var is_selecting: Bool {
		guard let exhibit = Global.shared.showcase else { return false }
		switch exhibit.selection {
			case .view: return false
			case .mode_albums, .mode_songs: return true
		}
	}
}

// MARK: Overflow

private struct MenuOverflow: View {
	var body: some View {
		Menu { if let exhibit = Global.shared.showcase {
			Section {
				switch exhibit.selection {
					case .view: EmptyView()
					case .mode_albums, .mode_songs:
						Button {
							exhibit.end_selecting_animated()
						} label: {
							Label(InterfaceText.Done, systemImage: SF.select_fill)
						}
				}
			}
			
			let uSongs = exhibit.uSongs_scope()
			
			Button {
				exhibit.end_selecting_animated()
				Task { await Tape.play_now(uSongs) }
			} label: {
				Label(InterfaceText.Play, systemImage: SF.play_hollow)
			}.disabled(uSongs.isEmpty)
			
			Button {
				exhibit.end_selecting_animated()
				// Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
				let jumbled = uSongs.in_any_other_order { $0 == $1 }
				Task { await Tape.play_now(jumbled) }
			} label: {
				Label(InterfaceText.Jumble, systemImage: SF.die_random())
			}.disabled(uSongs.count <= 1)
			
			Button {
				exhibit.end_selecting_animated()
				Tape.play_later(uSongs)
			} label: {
				Label(InterfaceText.Add_to_Queue, systemImage: SF.add_to_queue)
			}.disabled(uSongs.isEmpty)
		}} label: {
			Image(systemName: SF.ellipsis)
				.symbolRenderingMode({
					guard let exhibit = Global.shared.showcase
					else { return .hierarchical }
					switch exhibit.selection {
						case .view:
							return .hierarchical
						case .mode_albums, .mode_songs:
							return .monochrome
					}
				}())
				.animation(.default, value: Global.shared.showcase?.selection)
				.accessibilityLabel(InterfaceText.More)
		}.menuOrder(.fixed)
	}
}
