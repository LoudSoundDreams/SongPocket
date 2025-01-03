// 2022-12-12

import SwiftUI
import MusicKit

// MARK: - Album row

@MainActor struct AlbumRow: View {
	let uAlbum: UAlbum
	let list_state: AlbumListState
	
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			AlbumArt(
				uAlbum: uAlbum,
				dim_limit: min(list_state.size_viewport.width, list_state.size_viewport.height)
			)
			.opacity(sel_opacity)
			.animation(.default, value: list_state.select_mode)
			.overlay {
				ZStack {
					if !is_expanded { Rectangle().foregroundStyle(Material.thin) }
				}.animation(.linear(duration: .one_eighth), value: is_expanded)
			}
			ZStack {
				switch list_state.expansion {
					case .expanded: EmptyView()
					case .collapsed:
						AlbumLabel(uAlbum: uAlbum, list_state: list_state)
							.accessibilitySortPriority(10)
				}
			}.animation(.linear(duration: .one_eighth), value: list_state.expansion)
		}
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { sel_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay { sel_border.accessibilityHidden(true) } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityAddTraits(.isButton)
	}
	private var is_expanded: Bool {
		switch list_state.expansion {
			case .collapsed: return false
			case .expanded(let uA_expanded): return uA_expanded == uAlbum
		}
	}
	
	private var sel_opacity: Double {
		switch list_state.select_mode {
			case .view: return 1
			case .select_albums, .select_songs: return .one_fourth
		}
	}
	@ViewBuilder private var sel_highlight: some View {
		let highlighting: Bool = { switch list_state.select_mode {
			case .view, .select_songs: return false
			case .select_albums(let uAs_selected): return uAs_selected.contains(uAlbum)
		}}()
		if highlighting {
			Color.accentColor.opacity(.one_half)
		} else { EmptyView() }
	}
	@ViewBuilder private var sel_border: some View {
		switch list_state.select_mode {
			case .view, .select_songs: EmptyView()
			case .select_albums(let uAs_selected):
				if uAs_selected.contains(uAlbum) {
					RectSelected()
				} else { RectUnselected() }
		}
	}
	
	private func tapped() {
		switch list_state.select_mode {
			case .select_songs: return
			case .view:
				switch list_state.expansion {
					case .collapsed:
						list_state.expansion = .expanded(uAlbum)
					case .expanded(let uA_expanded):
						if uA_expanded == uAlbum {
							list_state.expansion = .collapsed
						} else { list_state.expansion = .expanded(uAlbum) }
				}
			case .select_albums(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uAlbum) {
					new_selected.remove(uAlbum)
				} else { new_selected.insert(uAlbum) }
				list_state.select_mode = .select_albums(new_selected)
		}
	}
}

// MARK: Album art

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
					Image(systemName: "music.note")
						.foregroundStyle(.secondary)
						.font(.title)
						.accessibilityLabel(InterfaceText.No_artwork)
				}
			}
		}
		.animation(nil, value: uAlbum) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works
	}
}

// MARK: Album label

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
					.foregroundStyle(sel_dimmed ? .tertiary : .secondary)
					.accessibilitySortPriority(10)
			}
			if let artist_album = albumInfo?._artist, artist_album != "" {
				Text(artist_album)
					.font_caption2_bold()
					.foregroundStyle(sel_dimmed ? .tertiary : .secondary)
					.accessibilitySortPriority(20)
			}
			Text(title_and_input_label)
				.font_title3_bold()
				.foregroundStyle(sel_dimmed ? .secondary : .primary)
				.accessibilitySortPriority(30) // Higher means sooner.
		}
		.animation(.default, value: sel_dimmed)
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title_and_input_label])
	}
	private var sel_dimmed: Bool {
		switch list_state.select_mode {
			case .view, .select_albums: return false
			case .select_songs: return true
		}
	}
	
	private var menu_select: some View {
		Menu {
			switch list_state.select_mode {
				case .select_songs, .select_albums: EmptyView()
				case .view:
					Button(InterfaceText.Select, systemImage: "checkmark.circle") {
						withAnimation {
							list_state.select_mode = .select_albums([uAlbum])
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
			switch list_state.expansion {
				case .expanded: return true
				case .collapsed: return false
			}}())
		.animation(.default, value: list_state.expansion)
	}
	private var b_above: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Up : InterfaceText.Select_Up,
			systemImage: is_selected ? "arrowtriangle.up.circle.fill" : "arrowtriangle.up.circle"
		) {
			list_state.change_album_range(from: uAlbum, forward: false)
		}.disabled({
			return (list_state.signal_albums_reordered && false) ||
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
			return (list_state.signal_albums_reordered && false) ||
			apple_lib.is_merging ||
			!list_state.has_album_range(from: uAlbum, forward: true)
		}())
	}
	private var is_selected: Bool {
		switch list_state.select_mode {
			case .view, .select_songs: return false
			case .select_albums(let uAs_selected): return uAs_selected.contains(uAlbum)
		}
	}
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirm_play_uSong = Notification.Name("LR_SongConfirmPlayWithMediaPlayerID")
	let uSong: USong
	let uAlbum: UAlbum
	let list_state: AlbumListState
	
	private let apple_lib: AppleLibrary = .shared
	var body: some View {
		VStack(spacing: .zero) {
			HStack(alignment: .firstTextBaseline) {
				let songInfo: SongInfo? = {
					guard let mkSong = apple_lib.mkSongs_cache[uSong] else {
						Task { await apple_lib.cache_mkSong(uSong: uSong) } // SwiftUI redraws this view afterward because this view observes the cache.
						return nil
					}
					return SongInfo(
						_disc: mkSong.discNumber,
						_track: mkSong.trackNumber,
						_title: mkSong.title,
						_artist: mkSong.artistName)
				}()
				let albumInfo: AlbumInfo? = apple_lib.albumInfo(uAlbum: uAlbum)
				
				stack_main(songInfo, albumInfo)
				Spacer()
				menu_select(songInfo, albumInfo)
			}
			.padding(.horizontal).padding(.leading, .eight * 1/2) // Align with `AlbumLabel`.
			.padding(.top, .eight * 3/2).padding(.bottom, .eight * 7/4)
			.background { sel_highlight }
			Separator().padding(.horizontal).padding(.leading, .eight * 1/2)
		}
		.overlay { sel_border }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	@ViewBuilder private func stack_main(
		_ songInfo: SongInfo?,
		_ albumInfo: AlbumInfo?
	) -> some View {
		let title: String? = songInfo?._title
		VStack(alignment: .leading, spacing: .eight * 1/2) { // Align with `AlbumLabel`.
			Text(title ?? InterfaceText._tilde)
				.foregroundStyle({
					let _ = PlayerState.shared.signal
					let _ = apple_lib.is_merging // I think this should be unnecessary, but I’ve seen the indicator get outdated after deleting a recently played song.
					return ApplicationMusicPlayer.StatusNowPlaying(uSong: uSong).foreground_color
				}())
			if
				let artist_song = songInfo?._artist,
				let artist_album = albumInfo?._artist,
				artist_song != "", artist_album != "",
				artist_song != artist_album
			{
				Text(artist_song)
					.foregroundStyle(.secondary)
					.font_footnote()
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title].compactMap { $0 })
		.accessibilityAddTraits(.isButton)
	}
	
	@ViewBuilder private var sel_highlight: some View {
		let highlighting: Bool = { switch list_state.select_mode {
			case .select_albums: return false
			case .view(let uS_activated): return uS_activated == uSong
			case .select_songs(let uSs_selected): return uSs_selected.contains(uSong)
		}}()
		Color.accentColor
			.opacity(highlighting ? .one_half : .zero)
			.animation( // Animates when entering vanilla mode. Doesn’t animate when entering or staying in select mode, or activating song in view mode.
				{ switch list_state.select_mode {
					case .select_albums: return nil // Should never run
					case .view(let uS_activated): return (uS_activated == nil) ? .default : nil
					case .select_songs: return nil // It’d be nice to animate deselecting after arranging, floating, and sinking, but not manually selecting or deselecting.
				}}(),
				value: list_state.select_mode)
	}
	@ViewBuilder private var sel_border: some View {
		switch list_state.select_mode {
			case .view, .select_albums: EmptyView()
			case .select_songs(let uSs_selected):
				if uSs_selected.contains(uSong) {
					RectSelected()
				} else { RectUnselected() }
		}
	}
	
	private func tapped() {
		switch list_state.select_mode {
			case .select_albums: return
			case .view: NotificationCenter.default.post(name: Self.confirm_play_uSong, object: uSong)
			case .select_songs(let old_selected):
				var new_selected = old_selected
				if old_selected.contains(uSong) {
					new_selected.remove(uSong)
				} else { new_selected.insert(uSong) }
				list_state.select_mode = .select_songs(new_selected)
		}
	}
	
	private func menu_select(
		_ songInfo: SongInfo?,
		_ albumInfo: AlbumInfo?
	) -> some View {
		Menu {
			Section({ () -> String in
				guard let songInfo, let albumInfo else { return "" }
				let numbers: String = {
					let f_track: String = {
						guard let track = songInfo._track else { return InterfaceText._octothorpe }
						return String(track)
					}()
					guard albumInfo._disc_max >= 2 else { return f_track }
					
					let f_disc: String = {
						guard let disc = songInfo._disc else { return InterfaceText._octothorpe }
						return String(disc)
					}()
					return "\(f_disc)\(InterfaceText._interpunct)\(f_track)"
				}()
				return InterfaceText.Track_VALUE(numbers)
			}()) {
				switch list_state.select_mode {
					case .select_albums, .select_songs: EmptyView()
					case .view:
						Button(InterfaceText.Select, systemImage: "checkmark.circle") {
							withAnimation {
								list_state.select_mode = .select_songs([uSong])
							}
						}.disabled(apple_lib.is_merging)
						Divider()
				}
				b_above
				b_below
			}
		} label: {
			if is_selected { IconSelected() } else { IconUnselected() }
		}
	}
	private var b_above: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Up : InterfaceText.Select_Up,
			systemImage: is_selected ? "arrowtriangle.up.circle.fill" : "arrowtriangle.up.circle"
		) {
			list_state.change_song_range(from: uSong, forward: false)
		}.disabled({
			return (list_state.signal_songs_reordered && false) ||
			apple_lib.is_merging ||
			!list_state.has_song_range(from: uSong, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Down: InterfaceText.Select_Down,
			systemImage: is_selected ? "arrowtriangle.down.circle.fill" : "arrowtriangle.down.circle"
		) {
			list_state.change_song_range(from: uSong, forward: true)
		}.disabled({
			return (list_state.signal_songs_reordered && false) ||
			apple_lib.is_merging ||
			!list_state.has_song_range(from: uSong, forward: true)
		}())
	}
	private var is_selected: Bool {
		switch list_state.select_mode {
			case .select_albums, .view: return false
			case .select_songs(let uSs_selected): return uSs_selected.contains(uSong)
		}
	}
}
