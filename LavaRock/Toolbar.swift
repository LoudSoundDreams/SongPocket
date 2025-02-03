// 2025-01-25

import SwiftUI

struct BubbleBar: View {
	static let width_border: CGFloat = .eight * 1/2
	
	var body: some View {
		HStack(spacing: Self.width_border * 2) {
			MenuTransport()
			b_select_mode
			menu_overflow
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(Self.width_border) // As of iOS 18.3, an open `Menu` stays 4 points away from the view that presented it.
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
			Image(systemName: SF.circle_pencil)
				.symbolRenderingMode({
					guard let showcase else { return .hierarchical }
					switch showcase.selection {
						case .view: return .hierarchical
						case .mode_albums, .mode_songs: return .monochrome
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
	
	// MARK: Overflow
	
	private var menu_overflow: some View {
		Menu {
			sections_sort
			section_reorder
			section_scope
		} label: {
			Image(systemName: SF.circle_ellipsis)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.More)
		}.menuOrder(.fixed)
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
			}.disabled(!showcase.can_reorder_selection(up: true))
			
			Button {
				showcase.reorder_selection(up: true, to_limit: false)
			} label: {
				Image(systemName: SF.move_up)
					.accessibilityLabel(InterfaceText.Move_Up)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(!showcase.can_reorder_selection(up: true))
			
			Button {
				showcase.reorder_selection(up: false, to_limit: false)
			} label: {
				Image(systemName: SF.move_down)
					.accessibilityLabel(InterfaceText.Move_Down)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(!showcase.can_reorder_selection(up: false))
			
			Button {
				showcase.reorder_selection(up: false, to_limit: true)
			} label: {
				Image(systemName: SF.to_bottom)
					.accessibilityLabel(InterfaceText.To_Bottom)
			}.disabled(!showcase.can_reorder_selection(up: false))
		}.controlGroupStyle(.compactMenu)
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
				Tape.play_later(uSongs)
			} label: {
				Label(InterfaceText.Play_Later, systemImage: SF.add_to_queue)
			}.disabled(uSongs.isEmpty)
		}}
	}
}
