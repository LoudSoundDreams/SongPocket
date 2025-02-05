// 2025-01-25

import SwiftUI

struct BubbleBar: View {
	var body: some View {
		HStack(spacing: Self.width_border * 2) {
			menu_overflow
			MenuTransport()
			b_select_mode
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(Self.width_border) // As of iOS 18.3, an open `Menu` stays 4 points away from the view that presented it.
		.background(Material.bar, in: .capsule)
	}
	private static let width_border: CGFloat = .eight * 1/2
	
	private var showcase: Exhibit? { Global.shared.showcase }
	
	private var b_select_mode: some View {
		Button {
			guard let showcase else { return }
			switch showcase.selection {
				case .mode_albums, .mode_songs:
					showcase.selection_end_animated()
				case .view:
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
						case .view: return InterfaceText.Select
						case .mode_albums, .mode_songs: return InterfaceText.Done
					}
				}())
		}.disabled({
			guard let showcase else { return true }
			return showcase.uAlbums().isEmpty
		}())
	}
	
	// MARK: - Overflow
	
	private var menu_overflow: some View {
		Menu {
			section_scope
			submenu_move
			section_reorder
		} label: {
			Image(systemName: SF.circle_hamburger)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.More)
		}.menuOrder(.fixed)
	}
	
	// MARK: Scope
	
	@ViewBuilder private var section_scope: some View { if let showcase {
		Section(showcase.message_status()) {
			let uSongs = showcase.uSongs_scope()
			
			Button {
				showcase.selection_end_animated()
				Task {
					await Tape.play_now(uSongs)
				}
			} label: {
				Label(InterfaceText.Play, systemImage: SF.play_hollow)
			}.disabled(uSongs.isEmpty)
			
			Button {
				showcase.selection_end_animated()
				Tape.play_later(uSongs)
			} label: {
				Label(InterfaceText.Play_Later, systemImage: SF.add_to_queue)
			}.disabled(uSongs.isEmpty)
		}.disabled(Global.shared.librarian_is_merging)
	}}
	
	// MARK: Arrange
	
	@ViewBuilder private var submenu_move: some View { if let showcase {
		Menu {
			// Include arrange commands depending on the type to arrange: albums or songs.
			// Enable arrange commands depending on the items to arrange:
			// • 2 or more
			// • Contiguous
			// • With useful data
			Group {
				switch showcase.focus {
					case .spotlight: EmptyView()
					case .covers: sections_arrange_albums
					case .expanded: sections_arrange_songs
				}
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(Global.shared.librarian_is_merging)
		} label: {
			Label(InterfaceText.Arrange, systemImage: SF.arrange)
		}
	}}
	
	@ViewBuilder private var sections_arrange_albums: some View {
		Section {
			buttons_arrange_albums([.recently_added, .recently_released])
		}
		Section {
			buttons_arrange_albums([.reverse, .random])
		}
	}
	@ViewBuilder private var sections_arrange_songs: some View {
		Section {
			buttons_arrange_songs([.track])
		}
		Section {
			buttons_arrange_songs([.reverse, .random])
		}
	}
	
	private func buttons_arrange_albums(_ albumOrders: [AlbumOrder]) -> some View {
		ForEach(albumOrders, id: \.self) { order in
			Button {
				showcase?.arrange_albums(by: order)
			} label: {
				Label(order.name, systemImage: order.sf_symbol)
			}.disabled({
				guard let showcase else { return true }
				return !showcase.can_arrange_albums(by: order)
			}())
		}
	}
	private func buttons_arrange_songs(_ songOrders: [SongOrder]) -> some View {
		ForEach(songOrders, id: \.self) { order in
			Button {
				showcase?.arrange_songs(by: order)
			} label: {
				Label(order.name, systemImage: order.sf_symbol)
			}.disabled({
				guard let showcase else { return true }
				return !showcase.can_arrange_songs(by: order)
			}())
		}
	}
	
	// MARK: Reorder
	
	@ViewBuilder private var section_reorder: some View { if let showcase {
		ControlGroup {
			Button {
				showcase.reorder(forward: false, to_limit: true)
			} label: {
				Image(systemName: SF.to_top)
					.accessibilityLabel(InterfaceText.To_Top)
			}.disabled(!showcase.can_reorder(forward: false))
			
			Button {
				showcase.reorder(forward: false, to_limit: false)
			} label: {
				Image(systemName: SF.move_up)
					.accessibilityLabel(InterfaceText.Move_Up)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(!showcase.can_reorder(forward: false))
			
			Button {
				showcase.reorder(forward: true, to_limit: false)
			} label: {
				Image(systemName: SF.move_down)
					.accessibilityLabel(InterfaceText.Move_Down)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(!showcase.can_reorder(forward: true))
			
			Button {
				showcase.reorder(forward: true, to_limit: true)
			} label: {
				Image(systemName: SF.to_bottom)
					.accessibilityLabel(InterfaceText.To_Bottom)
			}.disabled(!showcase.can_reorder(forward: true))
		}
		.controlGroupStyle(.compactMenu)
		.disabled(Global.shared.librarian_is_merging)
	}}
}
