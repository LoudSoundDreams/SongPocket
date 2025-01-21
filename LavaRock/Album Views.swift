// 2022-12-12

import SwiftUI
import MusicKit

@MainActor struct AlbumRow: View {
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	var body: some View {
		let length_square: CGFloat = min(
			exhibit.size_viewport.width,
			exhibit.size_viewport.height)
		AlbumArt(
			uAlbum: uAlbum,
			dim_limit: length_square)
		.opacity(exhibit.has_selected_song() ? .one_half : 1)
		.animation(.default, value: exhibit.has_selected_song())
		.overlay {
			ZStack(alignment: .bottom) {
				ZStack {
					if !exhibit.is_spotlighting(uAlbum) {
						Rectangle().foregroundStyle(Material.thin)
					}
				}.animation(.linear_quick(), value: exhibit.is_spotlighting(uAlbum))
				ZStack {
					if !exhibit.is_spotlighting() {
						AlbumLabel(uAlbum: uAlbum, exhibit: exhibit).accessibilitySortPriority(10)
					}
				}.animation(.linear_quick(), value: exhibit.is_spotlighting())
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
		switch exhibit.selection {
			case .view, .mode_songs: EmptyView()
			case .mode_albums(let uAs_selected):
				let is_selected = uAs_selected.contains(uAlbum)
				let is_bright = is_selected != is_pressing
				if is_bright {
					BorderSelected()
				} else { BorderUnselected() }
		}
	}
	@State private var is_pressing = false
	
	private func tapped() {
		switch exhibit.selection {
			case .mode_songs: return
			case .view:
				switch exhibit.focus {
					case .covers, .expanded:
						exhibit.focus = .spotlight(uAlbum)
					case .spotlight(let uA_spotlighted):
						if uA_spotlighted == uAlbum {
							exhibit.focus = .covers
						} else { exhibit.focus = .spotlight(uAlbum) }
				}
			case .mode_albums(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uAlbum) {
					new_selected.remove(uAlbum)
				} else { new_selected.insert(uAlbum) }
				exhibit.selection = .mode_albums(new_selected)
		}
	}
}

// MARK: Label

@MainActor private struct AlbumLabel: View {
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	private let apple_lib: AppleLibrary = .shared
	var body: some View {
		let working_on_panel_buttons = 10 == 1
		if working_on_panel_buttons {
			VStack(alignment: .leading, spacing: .zero) {
				stack_info
					.padding()
					.padding(.leading, .eight * 1/2) // Align with `SongRow`.
				ButtonPanel(uAlbum: uAlbum, exhibit: exhibit)
					.containerRelativeFrame(.vertical) { length, axis in
						switch axis {
							case .horizontal: return length
							case .vertical: return length * .one_fourth
						}
					}
			}
		} else {
			VStack(alignment: .leading) {
				stack_info
					.padding(.leading, .eight * 1/2) // Align with `SongRow`.
				HStack(alignment: .bottom) {
					b_expand
					Spacer()
					menu_select
				}
				.font(.largeTitle)
				.dynamicType_default_to_max()
			}
			.padding()
		}
	}
	
	@ViewBuilder private var stack_info: some View {
		let albumInfo: AlbumInfo? = apple_lib.albumInfo(uAlbum: uAlbum)
		let title_and_input_label: String = {
			guard let title_album = albumInfo?._title, title_album != ""
			else { return InterfaceText._tilde }
			return title_album
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text(title_and_input_label)
				.font_title3_bold()
				.foregroundStyle(exhibit.has_selected_song() ? .secondary : .primary)
			if let artist_album = albumInfo?._artist, artist_album != "" {
				Text(artist_album)
					.font_caption2_bold()
					.foregroundStyle(exhibit.has_selected_song() ? .tertiary : .secondary)
				
			}
			if let date = albumInfo?._date_released {
				Text(date.formatted(date: .numeric, time: .omitted))
					.font(.caption2).monospacedDigit()
					.foregroundStyle(exhibit.has_selected_song() ? .tertiary : .secondary)
				
			}
		}
		.animation(.default, value: exhibit.has_selected_song())
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title_and_input_label])
	}
	private var b_expand: some View {
		Button {
			switch exhibit.focus {
				case .spotlight: return
				case .covers:
					exhibit.focus = .expanded(uAlbum)
				case .expanded(let uA_expanded):
					if uA_expanded == uAlbum {
						exhibit.focus = .covers
					} else { exhibit.focus = .expanded(uAlbum) }
			}
		} label: {
			Image(systemName: "chevron.forward.circle.fill") // 2do: Accessibility.
				.symbolRenderingMode(.hierarchical)
		}
		.rotationEffect({
			if exhibit.is_expanded(uAlbum)
			{ return Angle.degrees(90) }
			return Angle.zero
		}())
		.animation(.linear_quick(), value: exhibit.is_expanded(uAlbum))
		.disabled(!exhibit.is_viewing)
	}
	private var menu_select: some View {
		Menu {
			switch exhibit.selection {
				case .mode_songs, .mode_albums: EmptyView()
				case .view:
					Button(InterfaceText.Select, systemImage: "checkmark.circle") {
						withAnimation {
							exhibit.selection = .mode_albums([uAlbum])
						}
					}.disabled(apple_lib.is_merging)
					Divider()
			}
			b_above
			b_below
		} label: {
			if exhibit.has_selected_album(uAlbum)
			{ IconSelected() }
			else { IconUnselected() }
		}
		.disabled(exhibit.is_expanded())
		.animation(.default, value: exhibit.is_expanded())
	}
	private var b_above: some View {
		Button(
			exhibit.has_selected_album(uAlbum)
			? InterfaceText.Deselect_Up
			: InterfaceText.Select_Up,
			systemImage: exhibit.has_selected_album(uAlbum)
			? "arrowtriangle.up.circle.fill"
			: "arrowtriangle.up.circle"
		) {
			exhibit.change_album_range(from: uAlbum, forward: false)
		}.disabled({
			return (exhibit.signal_artifacts && false ) ||
			apple_lib.is_merging ||
			!exhibit.has_album_range(from: uAlbum, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			exhibit.has_selected_album(uAlbum)
			? InterfaceText.Deselect_Down
			: InterfaceText.Select_Down,
			systemImage: exhibit.has_selected_album(uAlbum)
			? "arrowtriangle.down.circle.fill"
			: "arrowtriangle.down.circle"
		) {
			exhibit.change_album_range(from: uAlbum, forward: true)
		}.disabled({
			return (exhibit.signal_artifacts && false) ||
			apple_lib.is_merging ||
			!exhibit.has_album_range(from: uAlbum, forward: true)
		}())
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
