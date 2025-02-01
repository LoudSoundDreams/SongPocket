// 2025-01-25

import SwiftUI

struct BubbleBar: View {
	var body: some View {
		HStack {
			MenuSort()
			MenuTransport()
			MenuOverflow()
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(.eight * 1/2)
		.background(Material.bar, in: .capsule)
	}
}

private struct MenuSort: View {
	var body: some View {
		Menu { if let showcase = Global.shared.showcase {
			// Include sort commands depending on the type to sort: albums or songs.
			// Enable sort commands depending on the items to sort:
			// • 2 or more
			// • Contiguous
			// • With useful data
			switch showcase.focus {
				case .spotlight: EmptyView()
				case .covers: commands_albums
				case .expanded: commands_songs
			}
			
			ControlGroup {
				Button {
					showcase.reorder_selection(up: true, to_limit: true)
				} label: {
					Image(systemName: SF.to_top)
						.accessibilityLabel(InterfaceText.To_Top)
				}
				
				Button {
					showcase.reorder_selection(up: true, to_limit: false)
				} label: {
					Image(systemName: "arrow.up")
						.accessibilityLabel(InterfaceText.Move_Up)
				}.menuActionDismissBehavior(.disabled)
				
				Button {
					showcase.reorder_selection(up: false, to_limit: false)
				} label: {
					Image(systemName: "arrow.down")
						.accessibilityLabel(InterfaceText.Move_Down)
				}.menuActionDismissBehavior(.disabled)
				
				Button {
					showcase.reorder_selection(up: false, to_limit: true)
				} label: {
					Image(systemName: SF.to_bottom)
						.accessibilityLabel(InterfaceText.To_Bottom)
				}
			}
			.controlGroupStyle(.compactMenu)
			.disabled({
				switch showcase.selection {
					case .view: return true
					case .mode_albums(let uAs_selected): return uAs_selected.isEmpty
					case .mode_songs(let uSs_selected): return uSs_selected.isEmpty
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
					Global.shared.showcase?.sort_albums(by: order)
				} label: {
					Label(order.name, systemImage: order.sf_symbol)
				}.disabled({
					guard let showcase = Global.shared.showcase
					else { return true }
					return !showcase.can_sort_albums(by: order)
				}())
			}}
		}
	}
	private static let albumOrders_groups: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
	
	private var commands_songs: some View {
		ForEach(Self.songOrders_groups, id: \.self) { group in
			Section { ForEach(group, id: \.self) { order in
				Button {
					Global.shared.showcase?.sort_songs(by: order)
				} label: {
					Label(order.name, systemImage: order.sf_symbol)
				}.disabled({
					guard let showcase = Global.shared.showcase
					else { return true }
					return !showcase.can_sort_songs(by: order)
				}())
			}}
		}
	}
	private static let songOrders_groups: [[SongOrder]] = [[.track], [.reverse, .random]]
}

private struct MenuOverflow: View {
	var body: some View {
		Menu { if let showcase = Global.shared.showcase {
			Section {
				switch showcase.selection {
					case .view: EmptyView()
					case .mode_albums, .mode_songs:
						Button {
							showcase.end_selecting_animated()
						} label: {
							Label(InterfaceText.Done, systemImage: SF.select_fill)
						}
				}
			}
			section_scope
		}} label: {
			Image(systemName: SF.ellipsis)
				.symbolRenderingMode({
					guard let showcase = Global.shared.showcase
					else { return .hierarchical }
					switch showcase.selection {
						case .view:
							return .hierarchical
						case .mode_albums, .mode_songs:
							return .monochrome
					}
				}())
				.accessibilityLabel(InterfaceText.More)
		}
		.menuOrder(.fixed)
		.onLongPressGesture(minimumDuration: .zero) { die_rolls += 1 }
	}
	
	private var section_scope: some View {
		Section { if let showcase = Global.shared.showcase {
			let uSongs = showcase.uSongs_scope()
			
			Button {
				showcase.end_selecting_animated()
				Task {
					await Tape.play_now(uSongs)
				}
			} label: {
				Label(InterfaceText.Play, systemImage: SF.play_hollow)
			}.disabled(uSongs.isEmpty)
			
			Button {
				showcase.end_selecting_animated()
				// Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
				let jumbled = uSongs.in_any_other_order { $0 == $1 }
				Task {
					await Tape.play_now(jumbled)
				}
			} label: {
				Label(InterfaceText.Jumble, systemImage: {
					let _ = die_rolls
					return SF.die_random()
				}())
			}.disabled(uSongs.count <= 1)
			
			Button {
				showcase.end_selecting_animated()
				Tape.play_later(uSongs)
			} label: {
				Label(InterfaceText.Add_to_Queue, systemImage: SF.add_to_queue)
			}.disabled(uSongs.isEmpty)
		}}
	}
	@State private var die_rolls = 0
}
