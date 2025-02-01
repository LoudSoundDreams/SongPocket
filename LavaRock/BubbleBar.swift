// 2025-01-25

import SwiftUI

struct BubbleBar: View {
	var body: some View {
		HStack {
			b_select_mode
			MenuTransport()
			menu_overflow
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(.eight * 1/2)
		.background(Material.bar, in: .capsule)
	}
	
	private var showcase: Exhibit? { Global.shared.showcase }
	
	private var b_select_mode: some View {
		Button {
			guard let showcase else { return }
			switch showcase.selection {
				case .mode_albums, .mode_songs:
					showcase.end_selecting_animated()
					return
				case .view: break
			}
			switch showcase.focus {
				case .spotlight: return
				case .covers:
					withAnimation {
						showcase.selection = .mode_albums([])
					}
				case .expanded:
					withAnimation {
						showcase.selection = .mode_songs([])
					}
			}
		} label: {
			Image(systemName: SF.select_fill)
				.symbolRenderingMode({
					guard let showcase else { return .hierarchical }
					switch showcase.selection {
						case .view:
							return .hierarchical
						case .mode_albums, .mode_songs:
							return .monochrome
					}
				}())
				.accessibilityLabel({
					guard let showcase else { return InterfaceText.Select }
					switch showcase.selection {
						case .view:
							return InterfaceText.Select
						case .mode_albums, .mode_songs:
							return InterfaceText.Done
					}
				}())
		}.disabled({
			guard let showcase else { return true }
			return showcase.uAlbums().isEmpty ||
			Global.shared.librarian_is_merging
		}())
	}
	
	private var menu_overflow: some View {
		Menu {
			sections_sort
			section_reorder
			section_scope
		} label: {
			Image(systemName: SF.ellipsis)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.More)
		}
		.menuOrder(.fixed)
		.onLongPressGesture(minimumDuration: .zero) { die_rolls += 1 }
	}
	
	@ViewBuilder private var sections_sort: some View {
		// Include sort commands depending on the type to sort: albums or songs.
		// Enable sort commands depending on the items to sort:
		// • 2 or more
		// • Contiguous
		// • With useful data
		if let showcase { switch showcase.focus {
			case .spotlight: EmptyView()
			case .covers: sections_sort_albums
			case .expanded: sections_sort_songs
		}}
	}
	
	private var sections_sort_albums: some View {
		ForEach(Self.albumOrders_groups, id: \.self) { group in
			Section { ForEach(group, id: \.self) { order in
				Button {
					showcase?.sort_albums(by: order)
				} label: {
					Label(order.name, systemImage: order.sf_symbol)
				}.disabled({
					guard let showcase else { return true }
					return !showcase.can_sort_albums(by: order)
				}())
			}}
		}
	}
	private static let albumOrders_groups: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
	
	private var sections_sort_songs: some View {
		ForEach(Self.songOrders_groups, id: \.self) { group in
			Section { ForEach(group, id: \.self) { order in
				Button {
					showcase?.sort_songs(by: order)
				} label: {
					Label(order.name, systemImage: order.sf_symbol)
				}.disabled({
					guard let showcase else { return true }
					return !showcase.can_sort_songs(by: order)
				}())
			}}
		}
	}
	private static let songOrders_groups: [[SongOrder]] = [[.track], [.reverse, .random]]
	
	@ViewBuilder private var section_reorder: some View {
		if let showcase { ControlGroup {
			Button {
				showcase.reorder_selection(up: true, to_limit: true)
			} label: {
				Image(systemName: SF.to_top)
					.accessibilityLabel(InterfaceText.To_Top)
			}
			
			Button {
				showcase.reorder_selection(up: true, to_limit: false)
			} label: {
				Image(systemName: SF.move_up)
					.accessibilityLabel(InterfaceText.Move_Up)
			}.menuActionDismissBehavior(.disabled)
			
			Button {
				showcase.reorder_selection(up: false, to_limit: false)
			} label: {
				Image(systemName: SF.move_down)
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
		.disabled({ switch showcase.selection {
			case .view: return true
			case .mode_albums(let uAs_selected): return uAs_selected.isEmpty
			case .mode_songs(let uSs_selected): return uSs_selected.isEmpty
		}}())
		}
	}
	
	private var section_scope: some View {
		Section { if let showcase {
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
				Label(InterfaceText.Play_Later, systemImage: SF.add_to_queue)
			}.disabled(uSongs.isEmpty)
		}}
	}
	@State private var die_rolls = 0
}
