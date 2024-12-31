// 2022-12-12

import SwiftUI
import MusicKit

// MARK: - Album row

@MainActor struct AlbumRow: View {
	let id_album: MPIDAlbum
	let list_state: AlbumListState
	
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			AlbumArt(
				id_album: id_album,
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
					case .collapsed: AlbumLabel(
						id_album: id_album,
						list_state: list_state
					).accessibilitySortPriority(10)
				}
			}.animation(.linear(duration: .one_eighth), value: list_state.expansion)
		}
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { sel_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay { sel_border.accessibilityHidden(true) }// .accessibilitySortPriority(20) } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityAddTraits(.isButton)
	}
	private var is_expanded: Bool {
		switch list_state.expansion {
			case .collapsed: return false
			case .expanded(let id_expanded): return id_expanded == id_album
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
			case .select_albums(let ids_selected): return ids_selected.contains(id_album)
		}}()
		if highlighting {
			Color.accentColor.opacity(.one_half)
		} else { EmptyView() }
	}
	@ViewBuilder private var sel_border: some View {
		switch list_state.select_mode {
			case .view, .select_songs: EmptyView()
			case .select_albums(let ids_selected):
				if ids_selected.contains(id_album) {
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
						list_state.expansion = .expanded(id_album)
					case .expanded(let id_expanded):
						if id_expanded == id_album {
							list_state.expansion = .collapsed
						} else { list_state.expansion = .expanded(id_album) }
				}
			case .select_albums(let ids_selected):
				var selected_new = ids_selected
				if ids_selected.contains(id_album) {
					selected_new.remove(id_album)
				} else { selected_new.insert(id_album) }
				list_state.select_mode = .select_albums(selected_new)
		}
	}
}

// MARK: Album art

@MainActor private struct AlbumArt: View {
	let id_album: MPIDAlbum
	let dim_limit: CGFloat
	
	private var artwork: MusicKit.Artwork? {
		return AppleLibrary.shared.mkSection(mpidAlbum: id_album)?.artwork
	}
	var body: some View {
		ZStack {
#if targetEnvironment(simulator)
			if let sim_album = Sim_MusicLibrary.shared.sim_albums[id_album] {
				Image(sim_album.art_file_name)
					.resizable()
					.scaledToFit()
					.frame(width: dim_limit, height: dim_limit)
			}
#else
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
					Color.white_one_fourth
						.frame(width: dim_limit, height: dim_limit)
					Image(systemName: "music.note")
						.foregroundStyle(.secondary)
						.font(.title)
						.accessibilityLabel(InterfaceText.No_artwork)
				}
			}
#endif
		}
		.animation(nil, value: id_album) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works
	}
}

// MARK: Album label

@MainActor private struct AlbumLabel: View {
	let id_album: MPIDAlbum
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
		let info_album: InfoAlbum? = apple_lib.infoAlbum(mpidAlbum: id_album)
		let title_and_input_label: String = {
			guard let title_album = info_album?._title, title_album != ""
			else { return InterfaceText._tilde }
			return title_album
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			if let date = info_album?._date_released {
				Text(date.formatted(date: .numeric, time: .omitted))
					.font(.caption2).monospacedDigit()
					.foregroundStyle(sel_dimmed ? .tertiary : .secondary)
					.accessibilitySortPriority(10)
			}
			if let artist_album = info_album?._artist, artist_album != "" {
				Text(artist_album)
					.font_caption2_bold()
					.foregroundStyle(sel_dimmed ? .tertiary : .secondary)
					.accessibilitySortPriority(20)
			}
			Text(title_and_input_label)
				.font_title3_bold()
				.foregroundStyle({
					if sel_dimmed { return Color.secondary }
					return ApplicationMusicPlayer.StatusNowPlaying(mpidAlbum: id_album).foreground_color
				}())
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
							list_state.select_mode = .select_albums([id_album])
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
			list_state.change_album_range(from: id_album, forward: false)
		}.disabled({
			return (list_state.signal_albums_reordered && false) ||
			apple_lib.is_merging || // TO DO: Change icon to spinner.
			!list_state.has_album_range(from: id_album, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Down : InterfaceText.Select_Down,
			systemImage: is_selected ? "arrowtriangle.down.circle.fill" : "arrowtriangle.down.circle"
		) {
			list_state.change_album_range(from: id_album, forward: true)
		}.disabled({
			return (list_state.signal_albums_reordered && false) ||
			apple_lib.is_merging ||
			!list_state.has_album_range(from: id_album, forward: true)
		}())
	}
	private var is_selected: Bool {
		switch list_state.select_mode {
			case .view, .select_songs: return false
			case .select_albums(let ids_selected): return ids_selected.contains(id_album)
		}
	}
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirm_play_id_song = Notification.Name("LRSongConfirmPlayWithID")
	let id_song: MPIDSong
	let id_album: MPIDAlbum
	let list_state: AlbumListState
	
	private let apple_lib: AppleLibrary = .shared
	var body: some View {
		VStack(spacing: .zero) {
			HStack(alignment: .firstTextBaseline) {
				let infoSong: InfoSong__? = {
#if targetEnvironment(simulator)
					guard let sim_song = Sim_MusicLibrary.shared.sim_songs[id_song] else {
						Task { await apple_lib.cache_mkSong(mpidSong: id_song) }
						return nil
					}
					return InfoSong__(
						_title: sim_song.title_on_disk ?? "",
						_artist: "",
						_disc: 1,
						_track: sim_song.track_number_on_disk)
#else
					guard let mkSong = apple_lib.mkSongs[MusicItemID(String(id_song))] else {
						Task { await apple_lib.cache_mkSong(mpidSong: id_song) } // SwiftUI redraws this view afterward because this view observes the cache.
						// TO DO: Prevent unnecessary redraw to nil and back to content after merging from Apple Music.
						return nil
					}
					return InfoSong__(
						_title: mkSong.title,
						_artist: mkSong.artistName,
						_disc: mkSong.discNumber,
						_track: mkSong.trackNumber)
#endif
				}()
				let infoAlbum: InfoAlbum? = apple_lib.infoAlbum(mpidAlbum: id_album)
				
				stack_main(infoSong, infoAlbum)
				Spacer()
				menu_select(infoSong, infoAlbum)
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
		_ infoSong: InfoSong__?,
		_ infoAlbum: InfoAlbum?
	) -> some View {
		let title: String? = infoSong?._title
		VStack(alignment: .leading, spacing: .eight * 1/2) { // Align with `AlbumLabel`.
			Text(title ?? InterfaceText._tilde)
				.foregroundStyle({
					let _ = PlayerState.shared.signal
					let _ = apple_lib.is_merging // I think this should be unnecessary, but I’ve seen the indicator get outdated after deleting a recently played song.
					return ApplicationMusicPlayer.StatusNowPlaying(mpidSong: id_song).foreground_color
				}())
			if
				let artist_song = infoSong?._artist,
				let artist_album = infoAlbum?._artist,
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
			case .view(let id_activated): return id_activated == id_song
			case .select_songs(let ids_selected): return ids_selected.contains(id_song)
		}}()
		Color.accentColor
			.opacity(highlighting ? .one_half : .zero)
			.animation( // Animates when entering vanilla mode. Doesn’t animate when entering or staying in select mode, or activating song in view mode.
				{ switch list_state.select_mode {
					case .select_albums: return nil // Should never run
					case .view(let id_activated): return (id_activated == nil) ? .default : nil
					case .select_songs: return nil // It’d be nice to animate deselecting after arranging, floating, and sinking, but not manually selecting or deselecting.
				}}(),
				value: list_state.select_mode)
	}
	@ViewBuilder private var sel_border: some View {
		switch list_state.select_mode {
			case .view, .select_albums: EmptyView()
			case .select_songs(let ids_selected):
				if ids_selected.contains(id_song) {
					RectSelected()
				} else { RectUnselected() }
		}
	}
	
	private func tapped() {
		switch list_state.select_mode {
			case .select_albums: return
			case .view: NotificationCenter.default.post(name: Self.confirm_play_id_song, object: id_song)
			case .select_songs(let ids_selected):
				var selected_new = ids_selected
				if ids_selected.contains(id_song) {
					selected_new.remove(id_song)
				} else { selected_new.insert(id_song) }
				list_state.select_mode = .select_songs(selected_new)
		}
	}
	
	private func menu_select(
		_ infoSong: InfoSong__?,
		_ infoAlbum: InfoAlbum?
	) -> some View {
		Menu {
			Section({ () -> String in
				guard let infoSong, let infoAlbum else { return InterfaceText._octothorpe }
				let numbers: String = {
					let f_track: String = {
						guard let track = infoSong._track else { return InterfaceText._octothorpe }
						return String(track)
					}()
					guard infoAlbum._disc_count >= 2 else { return f_track }
					
					let f_disc: String = {
						guard let disc = infoSong._disc else { return InterfaceText._octothorpe }
						return String(disc)
					}()
					return "\(f_disc)\(InterfaceText._interpunct)\(f_track)"
				}()
				return "\(InterfaceText._octothorpe) \(numbers)"
			}()) {
				switch list_state.select_mode {
					case .select_albums, .select_songs: EmptyView()
					case .view:
						Button(InterfaceText.Select, systemImage: "checkmark.circle") {
							withAnimation {
								list_state.select_mode = .select_songs([id_song])
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
			list_state.change_song_range(from: id_song, forward: false)
		}.disabled({
			return (list_state.signal_songs_reordered && false) ||
			apple_lib.is_merging ||
			!list_state.has_song_range(from: id_song, forward: false)
		}())
	}
	private var b_below: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Down: InterfaceText.Select_Down,
			systemImage: is_selected ? "arrowtriangle.down.circle.fill" : "arrowtriangle.down.circle"
		) {
			list_state.change_song_range(from: id_song, forward: true)
		}.disabled({
			return (list_state.signal_songs_reordered && false) ||
			apple_lib.is_merging ||
			!list_state.has_song_range(from: id_song, forward: true)
		}())
	}
	private var is_selected: Bool {
		switch list_state.select_mode {
			case .select_albums, .view: return false
			case .select_songs(let ids_selected): return ids_selected.contains(id_song)
		}
	}
}
