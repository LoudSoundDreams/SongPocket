// 2022-12-12

import SwiftUI
import MusicKit

@MainActor struct AlbumRow: View {
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	var body: some View {
		AlbumArt(
			uAlbum: uAlbum,
			length_max: exhibit.length_artwork)
		.saturation(is_selecting_songs ? .zero : 1)
		.overlay {
			ZStack(alignment: .bottom) {
				ZStack { if is_blurred {
					Rectangle().foregroundStyle(Material.thick)
				}}.animation(.linear_quick(), value: is_blurred)
				ZStack { if is_labeled {
					AlbumLabel(uAlbum: uAlbum, exhibit: exhibit)
				}}.animation(.linear_quick(), value: is_labeled)
			}
		}
		.overlay { border.accessibilityHidden(true) } // 2do: Make VoiceOver say “selected”.
		.frame(maxWidth: .infinity) // Horizontally centers the above in wide viewport.
		.contentShape(Rectangle()) // Makes blank space tappable in wide viewport.
		.onTapGesture { tapped() }
		.accessibilityAddTraits(.isButton)
	}
	private var is_blurred: Bool {
		switch exhibit.focus {
			case .covers, .expanded: return true
			case .spotlight(let uA_spotlighted):
				return uA_spotlighted != uAlbum
		}
	}
	private var is_labeled: Bool {
		switch exhibit.focus {
			case .covers, .expanded: return true
			case .spotlight: return false
		}
	}
	private var is_selecting_songs: Bool {
		switch exhibit.selection {
			case .mode_songs: return true
			case .view, .mode_albums: return false
		}
	}
	
	@ViewBuilder private var border: some View {
		switch exhibit.selection { // Use `withAnimation` to animate this when entering or exiting select mode, but not when staying in select mode.
			case .view, .mode_songs: EmptyView()
			case .mode_albums(let uAs_selected):
				if uAs_selected.contains(uAlbum) {
					BorderSelected()
				} else { BorderUnselected() }
		}
	}
	
	private func tapped() {
		switch exhibit.selection {
			case .mode_songs: return
			case .mode_albums(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uAlbum) {
					new_selected.remove(uAlbum)
				} else { new_selected.insert(uAlbum) }
				exhibit.selection = .mode_albums(new_selected)
				return
			case .view: break
		}
		switch exhibit.focus {
			case .covers:
				exhibit.focus = .expanded(uAlbum)
			case .expanded(let uA_expanded):
				if uA_expanded == uAlbum {
					exhibit.focus = .covers
				} else { exhibit.focus = .expanded(uAlbum) }
			case .spotlight(let uA_spotlighted):
				if uA_spotlighted == uAlbum {
					exhibit.focus = .covers
				} else { exhibit.focus = .spotlight(uAlbum) }
		}
	}
}

@MainActor struct AlbumArt: View {
	let uAlbum: UAlbum
	let length_max: CGFloat
	
	private var artwork: MusicKit.Artwork? {
		return AppleCatalog.shared.mkSections_cache[MusicItemID(String(uAlbum))]?.artwork
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
				ArtworkImage(artwork, width: length_max)
			} else {
				ZStack {
					Color(white: .one_fourth)
						.frame(width: length_max, height: length_max)
					Placeholder()
						.accessibilityLabel(InterfaceText.No_artwork)
				}
			}
		}
		.animation(nil, value: uAlbum) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works.
	}
}

@MainActor private struct AlbumLabel: View {
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	private let catalog: AppleCatalog = .shared
	var body: some View {
		HStack(alignment: .bottom) {
			stack_info
				.padding(.leading, SongRow.nudge_text)
				.padding(.trailing, .eight) // Leave room before the buttons.
			Spacer()
			ZStack {
				image_spotlight.hidden() // Keeps the layout stable.
				switch exhibit.selection {
					case .mode_songs: EmptyView()
					case .mode_albums: menu_select
					case .view:
						switch exhibit.focus {
							case .spotlight, .expanded: EmptyView()
							case .covers: b_spotlight
						}
				}
			}
			.font(.largeTitle)
			.dynamicType_default_to_plus_3()
			.animation(.linear_quick(), value: exhibit.focus)
		}.padding()
	}
	
	@ViewBuilder private var stack_info: some View {
		let albumInfo: AlbumInfo? = catalog.albumInfo(uAlbum: uAlbum)
		let title_and_input_label: String = {
			guard let title_album = albumInfo?._title, title_album != ""
			else { return InterfaceText._tilde }
			return title_album
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			if let date = albumInfo?._date_released {
				Text(date.formatted(date: .numeric, time: .omitted))
					.font(.caption2).monospacedDigit()
					.foregroundStyle(is_selecting_songs ? .tertiary : .secondary)
			}
			if let artist_album = albumInfo?._artist, artist_album != "" {
				Text(artist_album)
					.font_caption2_bold()
					.foregroundStyle(is_selecting_songs ? .tertiary : .secondary)
					.accessibilitySortPriority(20)
			}
			Text(title_and_input_label)
				.font_title3_bold()
				.foregroundStyle(is_selecting_songs ? .secondary : .primary) // 2do: Make VoiceOver say “dimmed”.
				.accessibilitySortPriority(30) // Bigger is sooner.
		}
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title_and_input_label])
	}
	private var is_selecting_songs: Bool {
		switch exhibit.selection {
			case .mode_songs: return true
			case .view, .mode_albums: return false
		}
	}
	
	private var b_spotlight: some View {
		Button {
			exhibit.focus = .spotlight(uAlbum)
		} label: {
			image_spotlight
				.accessibilityLabel(InterfaceText.Show_artwork)
		}
	}
	private var image_spotlight: some View {
		Image(systemName: SF.circle_photo)
			.symbolRenderingMode(.hierarchical)
	}
	
	private var menu_select: some View {
		Menu {
			b_above
			b_below
		} label: {
			if is_selected
			{ EllipsisSelected() }
			else { EllipsisUnselected() }
		}
	}
	private var b_above: some View {
		Button(
			is_selected
			? InterfaceText.Deselect_Up : InterfaceText.Select_Up,
			systemImage: is_selected
			? SF.circle_triangle_up_fill : SF.circle_triangle_up_hollow
		) {
			exhibit.toggle_range(from_uAlbum: uAlbum, forward: false)
		}.disabled(!exhibit.can_select_range(from_uAlbum: uAlbum, forward: false))
	}
	private var b_below: some View {
		Button(
			is_selected
			? InterfaceText.Deselect_Down : InterfaceText.Select_Down,
			systemImage: is_selected
			? SF.circle_triangle_down_fill : SF.circle_triangle_down_hollow
		) {
			exhibit.toggle_range(from_uAlbum: uAlbum, forward: true)
		}.disabled(!exhibit.can_select_range(from_uAlbum: uAlbum, forward: true))
	}
	private var is_selected: Bool {
		switch exhibit.selection {
			case .view, .mode_songs: return false
			case .mode_albums(let uAs_selected):
				return uAs_selected.contains(uAlbum)
		}
	}
}
