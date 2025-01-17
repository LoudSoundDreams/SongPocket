// 2022-12-12

import SwiftUI
import MusicKit

@MainActor struct AlbumRow: View {
	let uAlbum: UAlbum
	let list_state: AlbumListState
	
	var body: some View {
		let length_square: CGFloat = min(
			list_state.size_viewport.width,
			list_state.size_viewport.height)
		AlbumArt(
			uAlbum: uAlbum,
			dim_limit: length_square)
		.opacity(is_dimmed ? .one_half : 1).animation(.default, value: is_dimmed)
		.overlay {
			Color(white: .zero)
				.opacity(is_pressing ? .one_half : .zero)
				.animation(is_pressing ? nil : .linear_quick(), value: is_pressing)
		}
		.overlay {
			ZStack(alignment: .bottom) {
				ZStack {
					if !is_focused { Rectangle().foregroundStyle(Material.thin) }
				}.animation(.linear_quick(), value: is_focused)
				ZStack {
					switch list_state.focus {
						case .tracklist: EmptyView()
						case .cover:
							AlbumLabel(uAlbum: uAlbum, list_state: list_state).accessibilitySortPriority(10)
					}
				}.animation(.linear_quick(), value: list_state.focus)
			}
		}
		.overlay { border.accessibilityHidden(true) } // Use `withAnimation` to animate this when entering or exiting select mode, but not when staying in select mode.
		.frame(maxWidth: .infinity) // Horizontally centers the above in wide viewport.
		.contentShape(Rectangle()) // Makes blank space tappable in wide viewport.
		.onTapGesture { tapped() }
		.onLongPressGesture(minimumDuration: .zero) {
		} onPressingChanged: {
			is_pressing = $0
		}
		.accessibilityAddTraits(.isButton)
	}
	
	@ViewBuilder private var border: some View {
		switch list_state.selection {
			case .view, .mode_songs: EmptyView()
			case .mode_albums(let uAs_selected):
				if uAs_selected.contains(uAlbum) {
					BorderSelected()
				} else { BorderUnselected() }
		}
	}
	
	private func tapped() {
		switch list_state.selection {
			case .mode_songs: return
			case .view:
				switch list_state.focus {
					case .cover:
						list_state.focus = .tracklist(uAlbum)
					case .tracklist(let uA_focused):
						if uA_focused == uAlbum {
							list_state.focus = .cover
						} else { list_state.focus = .tracklist(uAlbum) }
				}
			case .mode_albums(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uAlbum) {
					new_selected.remove(uAlbum)
				} else { new_selected.insert(uAlbum) }
				list_state.selection = .mode_albums(new_selected)
		}
	}
	
	private var is_dimmed: Bool {
		switch list_state.selection {
			case .view, .mode_albums: return false
			case .mode_songs: return true
		}
	}
	@State private var is_pressing = false
	private var is_focused: Bool {
		switch list_state.focus {
			case .cover: return false
			case .tracklist(let uA_focused): return uA_focused == uAlbum
		}
	}
}

// MARK: Art

@MainActor struct AlbumArt: View {
	let uAlbum: UAlbum
	let dim_limit: CGFloat
	
	private var artwork: MusicKit.Artwork? {
		return AppleLibrary.shared.mkSections_cache[MusicItemID(String(uAlbum))]?.artwork
	}
	var body: some View {
		ZStack {
			if let artwork {
				/*
				 As of iOS 17.5.1:
				 • If you pass both width and height, `ArtworkImage` will have exactly those dimensions.
				 • If you pass only width or only height, the view will always be square.
				 If the aspect ratio of the view is different than the aspect ratio of the actual art, MusicKit fits the art within the view and fills the gap with color.
				 I can’t think of a way to figure the aspect ratio of the actual art. Therefore, always request a square view. For the square’s size, use the width or height of the viewport, whichever is smaller.
				 */
				ArtworkImage(artwork, width: dim_limit)
			} else {
				ZStack {
					Color(white: .one_fourth)
						.frame(width: dim_limit, height: dim_limit)
					PlaceholderMusicNote()
						.accessibilityLabel(InterfaceText.No_artwork)
				}
			}
		}
		.animation(nil, value: uAlbum) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works
	}
}

// MARK: Label

@MainActor private struct AlbumLabel: View {
	let uAlbum: UAlbum
	let list_state: AlbumListState
	
	private let apple_lib: AppleLibrary = .shared
	var body: some View {
		HStack(alignment: .lastTextBaseline) {
			stack_text
			Spacer()
			menu_select
		}
		.padding()
		.padding(.leading, .eight * 1/2) // Align with `SongRow`.
	}
	
	@ViewBuilder private var stack_text: some View {
		let albumInfo: AlbumInfo? = apple_lib.albumInfo(uAlbum: uAlbum)
		let title_and_input_label: String = {
			guard let title_album = albumInfo?._title, title_album != ""
			else { return InterfaceText._tilde }
			return title_album
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			if let date = albumInfo?._date_released {
				Text(date.formatted(date: .numeric, time: .omitted))
					.font(.caption2).monospacedDigit()
					.foregroundStyle(is_dimmed ? .tertiary : .secondary)
					.accessibilitySortPriority(10)
			}
			if let artist_album = albumInfo?._artist, artist_album != "" {
				Text(artist_album)
					.font_caption2_bold()
					.foregroundStyle(is_dimmed ? .tertiary : .secondary)
					.accessibilitySortPriority(20)
			}
			Text(title_and_input_label)
				.font_title3_bold()
				.foregroundStyle(is_dimmed ? .secondary : .primary)
				.accessibilitySortPriority(30) // Higher means sooner.
		}
		.animation(.default, value: is_dimmed)
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title_and_input_label])
	}
	
	private var menu_select: some View {
		Menu {
			switch list_state.selection {
				case .mode_songs, .mode_albums: EmptyView()
				case .view:
					Button(InterfaceText.Select, systemImage: "checkmark.circle") {
						withAnimation {
							list_state.selection = .mode_albums([uAlbum])
						}
					}.disabled(apple_lib.is_merging)
					Divider()
			}
			b_above
			b_below
		} label: {
			if is_selected { IconSelected() } else { IconUnselected() }
		}
		.disabled({
			switch list_state.focus {
				case .tracklist: return true
				case .cover: return false
			}
		}())
		.animation(.default, value: list_state.focus)
	}
	private var b_above: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Up : InterfaceText.Select_Up,
			systemImage: is_selected ? "arrowtriangle.up.circle.fill" : "arrowtriangle.up.circle"
		) {
			list_state.change_album_range(from: uAlbum, forward: false)
		}.disabled({
			return (list_state.signal_items && false ) ||
			apple_lib.is_merging ||
			!list_state.has_album_range(from: uAlbum, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Down : InterfaceText.Select_Down,
			systemImage: is_selected ? "arrowtriangle.down.circle.fill" : "arrowtriangle.down.circle"
		) {
			list_state.change_album_range(from: uAlbum, forward: true)
		}.disabled({
			return (list_state.signal_items && false) ||
			apple_lib.is_merging ||
			!list_state.has_album_range(from: uAlbum, forward: true)
		}())
	}
	
	private var is_dimmed: Bool {
		switch list_state.selection {
			case .view, .mode_albums: return false
			case .mode_songs: return true
		}
	}
	private var is_selected: Bool {
		switch list_state.selection {
			case .view, .mode_songs: return false
			case .mode_albums(let uAs_selected): return uAs_selected.contains(uAlbum)
		}
	}
}
