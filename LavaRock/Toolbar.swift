// 2025-01-25

import SwiftUI

struct BubbleBar: View {
	var body: some View {
		HStack(spacing: Self.width_border * 2) {
			b_select_mode
			menu_overflow
			MenuTransport()
		}
		.font(.largeTitle)
		.dynamicType_clamped()
		.padding(Self.width_border) // As of iOS 18.3, an open `Menu` stays 4 points away from the view that presented it.
		.background(Material.bar, in: .capsule)
	}
	private static let width_border: CGFloat = .eight * 1/2
	
	private var spotlight: Exhibit? { Global.shared.spotlight }
	
	private var b_select_mode: some View {
		Button {
			guard let spotlight else { return }
			switch spotlight.selection {
				case .mode_albums, .mode_songs:
					spotlight.selection_end_animated()
				case .view:
					switch spotlight.focus {
						case .gallery: return
						case .covers:
							withAnimation {
								spotlight.selection = .mode_albums([])
							}
						case .expanded:
							withAnimation {
								spotlight.selection = .mode_songs([])
							}
					}
			}
		} label: {
			Image(systemName: SF.circle_check)
				.symbolRenderingMode({
					guard let spotlight else { return .hierarchical }
					switch spotlight.selection {
						case .view: return .hierarchical
						case .mode_albums, .mode_songs: return .monochrome
					}
				}())
				.accessibilityLabel({
					guard let spotlight else { return InterfaceText.Select }
					switch spotlight.selection {
						case .view: return InterfaceText.Select
						case .mode_albums, .mode_songs: return InterfaceText.Done
					}
				}())
		}.disabled({
			guard let spotlight else { return true }
			return spotlight.uAlbums().isEmpty
		}())
	}
	
	// MARK: - Overflow
	
	private var menu_overflow: some View {
		Menu {
			section_scope
			sections_move
			section_reorder
		} label: {
			Image(systemName: SF.circle_menu)
				.symbolRenderingMode(.hierarchical)
				.accessibilityLabel(InterfaceText.Menu)
		}.menuOrder(.fixed)
	}
	
	// MARK: Scope
	
	@ViewBuilder private var section_scope: some View { if let spotlight {
		Section(spotlight.message_status()) {
			let uSongs = spotlight.uSongs_scope()
			
			Button {
				spotlight.selection_end_animated()
				Task {
					await Tape.play_now(uSongs)
				}
			} label: {
				Label(InterfaceText.Play, systemImage: SF.play_hollow)
			}.disabled(uSongs.isEmpty)
			
			Button {
				spotlight.selection_end_animated()
				Tape.play_later(uSongs)
			} label: {
				Label(InterfaceText.Play_Later, systemImage: SF.add_to_queue)
			}.disabled(uSongs.isEmpty)
		}.disabled(Global.shared.librarian_is_merging)
	}}
	
	// MARK: Arrange
	
	@ViewBuilder private var sections_move: some View { if let spotlight {
		// Include arrange commands depending on the type to arrange: albums or songs.
		// Enable arrange commands depending on the items to arrange:
		// • 2 or more
		// • Contiguous
		// • With useful data
		Menu(InterfaceText.Arrange, systemImage: SF.arrange) {
			Group { switch spotlight.focus {
				case .gallery: EmptyView()
				case .covers: sections_arrange_albums
				case .expanded: sections_arrange_songs
			}}.disabled(Global.shared.librarian_is_merging)
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
				spotlight?.arrange_albums(by: order)
			} label: {
				Label(order.name, systemImage: order.sf_symbol)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled({
				guard let spotlight else { return true }
				return !spotlight.can_arrange_albums(by: order)
			}())
		}
	}
	private func buttons_arrange_songs(_ songOrders: [SongOrder]) -> some View {
		ForEach(songOrders, id: \.self) { order in
			Button {
				spotlight?.arrange_songs(by: order)
			} label: {
				Label(order.name, systemImage: order.sf_symbol)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled({
				guard let spotlight else { return true }
				return !spotlight.can_arrange_songs(by: order)
			}())
		}
	}
	
	// MARK: Reorder
	
	@ViewBuilder private var section_reorder: some View { if let spotlight {
		ControlGroup {
			Button {
				spotlight.reorder(forward: false, to_limit: true)
			} label: {
				Image(systemName: SF.to_top)
					.accessibilityLabel(InterfaceText.To_Top)
			}.disabled(!spotlight.can_reorder(forward: false))
			
			Button {
				spotlight.reorder(forward: false, to_limit: false)
			} label: {
				Image(systemName: SF.move_up)
					.accessibilityLabel(InterfaceText.Move_Up)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(!spotlight.can_reorder(forward: false))
			
			Button {
				spotlight.reorder(forward: true, to_limit: false)
			} label: {
				Image(systemName: SF.move_down)
					.accessibilityLabel(InterfaceText.Move_Down)
			}
			.menuActionDismissBehavior(.disabled)
			.disabled(!spotlight.can_reorder(forward: true))
			
			Button {
				spotlight.reorder(forward: true, to_limit: true)
			} label: {
				Image(systemName: SF.to_bottom)
					.accessibilityLabel(InterfaceText.To_Bottom)
			}.disabled(!spotlight.can_reorder(forward: true))
		}
		.controlGroupStyle(.compactMenu)
		.disabled(Global.shared.librarian_is_merging)
	}}
}
