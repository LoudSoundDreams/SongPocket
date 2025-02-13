// 2022-12-12

import SwiftUI
import MusicKit

@MainActor struct AlbumRow: View {
	let uAlbum: UAlbum
	let exhibit: Exhibit
	
	var body: some View {
		AlbumArt(uAlbum: uAlbum, length_max: exhibit.length_artwork)
			.saturation(is_selecting_songs ? .zero : 1)
			.accessibilityAddTraits(.isButton)
			.overlay {
				ZStack(alignment: .bottom) {
					ZStack { if blurring {
						Rectangle().foregroundStyle(Material.regular)
					}}.animation(.linear_quick(), value: blurring)
					ZStack { if dimming {
						Color.black.opacity(.one_half)
					}}.animation(.linear_quick(), value: dimming)
					ZStack { if labeling {
						AlbumLabel(uAlbum: uAlbum, exhibit: exhibit)
					}}.animation(.linear_quick(), value: labeling)
				}
			}
			.overlay { border.accessibilityHidden(true) }
			.frame(maxWidth: .infinity) // Horizontally centers the above in wide viewport.
			.contentShape(Rectangle()) // Makes blank space tappable in wide viewport.
			.onTapGesture { tapped() }
	}
	private var blurring: Bool {
		switch exhibit.focus {
			case .covers, .expanded: return true
			case .gallery(let uA_showcased): return uA_showcased != uAlbum
		}
	}
	private var dimming: Bool {
		switch exhibit.focus {
			case .covers, .expanded: return false
			case .gallery(let uA_showcased): return uA_showcased != uAlbum
		}
	}
	private var labeling: Bool {
		switch exhibit.focus {
			case .covers, .expanded: return true
			case .gallery: return false
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
			case .gallery(let uA_showcased):
				if uA_showcased == uAlbum {
					exhibit.focus = .covers
				} else { exhibit.focus = .gallery(uAlbum) }
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
#if targetEnvironment(simulator)
				Image("wide")
					.resizable()
					.scaledToFit()
					.frame(width: length_max, height: length_max)
#else
				ZStack {
					Color(white: .one_fourth)
						.frame(width: length_max, height: length_max)
					Placeholder()
						.accessibilityLabel(InterfaceText.No_artwork)
				}
#endif
			}
		}.animation(nil, value: uAlbum) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works.
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
				image_gallery.hidden() // Keeps the layout stable.
				switch exhibit.selection {
					case .mode_songs: EmptyView()
					case .mode_albums: menu_select
					case .view:
						switch exhibit.focus {
							case .expanded: EmptyView()
							case .covers, .gallery: b_gallery
						}
				}
			}
			.font(.largeTitle)
			.dynamicType_clamped()
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
			Text(title_and_input_label)
				.font_title3_bold()
				.foregroundStyle(dimming ? .secondary : .primary)
			if let artist_album = albumInfo?._artist, artist_album != "" {
				Text(artist_album)
					.font_caption2_bold()
					.foregroundStyle(dimming ? .tertiary : .secondary)
			}
			if let date = albumInfo?._date_released {
				Text(date.formatted(date: .numeric, time: .omitted))
					.font(.caption2).monospacedDigit()
					.foregroundStyle(dimming ? .tertiary : .secondary)
			}
		}
		.animation(.linear_quick(), value: dimming)
		.disabled(dimming) // For accessibility.
		.accessibilityInputLabels([title_and_input_label])
	}
	private var dimming: Bool {
		switch exhibit.selection {
			case .mode_albums: return false
			case .mode_songs: return true
			case .view:
				switch exhibit.focus {
					case .covers, .gallery: return false
					case .expanded(let uA_expanded): return uA_expanded != uAlbum
				}
		}
	}
	
	private var b_gallery: some View {
		Button {
			exhibit.focus = .gallery(uAlbum)
		} label: {
			image_gallery
				.accessibilityLabel(InterfaceText.Show_artwork)
		}.disabled(!can_open_gallery) // Lets you rapid-tap to exit gallery, by making this button immediately start ignoring touches and passing them to the view behind it, while animating away.
	}
	private var image_gallery: some View {
		Image(systemName: SF.circle_photo)
			.symbolRenderingMode(.hierarchical)
	}
	private var can_open_gallery: Bool {
		switch exhibit.focus {
			case .gallery, .expanded: return false
			case .covers: return true
		}
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
			case .mode_albums(let uAs_selected): return uAs_selected.contains(uAlbum)
		}
	}
}
