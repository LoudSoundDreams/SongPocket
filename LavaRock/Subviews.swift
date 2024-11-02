// 2022-12-12

import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Album row

@MainActor struct AlbumRow: View {
	let id_album: AlbumID
	let list_state: AlbumListState
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			AlbumArt(id_album: id_album, dim_limit: min(list_state.viewportSize.width, list_state.viewportSize.height))
				.opacity(sel_opacity)
				.animation(.default, value: list_state.selectMode)
				.overlay { if exp_labeled {
					Rectangle().foregroundStyle(Material.thin)
				}}
			ZStack { if exp_labeled {
				AlbumLabel(id_album: id_album, list_state: list_state).accessibilitySortPriority(10)
			}}
		}
		.animation(.linear(duration: .oneEighth), value: exp_labeled)
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { sel_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay { sel_border.accessibilitySortPriority(20) } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
	}
	private var exp_labeled: Bool {
		switch list_state.expansion {
			case .collapsed: return true
			case .expanded(let id_expanded): return id_album != id_expanded
		}
	}
	
	private var sel_opacity: Double {
		switch list_state.selectMode {
			case .view: return 1
			case .selectAlbums, .selectSongs: return .oneFourth
		}
	}
	@ViewBuilder private var sel_highlight: some View {
		let highlighting: Bool = { switch list_state.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let ids_selected): return ids_selected.contains(id_album)
		}}()
		if highlighting {
			Color.accentColor.opacity(.oneHalf)
		} else {
			EmptyView()
		}
	}
	@ViewBuilder private var sel_border: some View {
		switch list_state.selectMode {
			case .view, .selectSongs: EmptyView()
			case .selectAlbums(let ids_selected):
				if ids_selected.contains(id_album) {
					RectSelected().accessibilityLabel(Text(InterfaceText.Selected))
				} else {
					RectUnselected()
				}
		}
	}
	
	private func tapped() {
		switch list_state.selectMode {
			case .selectSongs: return
			case .view:
				switch list_state.expansion {
					case .collapsed:
						list_state.expansion = .expanded(id_album)
					case .expanded(let id_expanded):
						if id_album == id_expanded {
							list_state.expansion = .collapsed
						} else {
							list_state.expansion = .expanded(id_album)
						}
				}
			case .selectAlbums(let ids_selected):
				var selected_new = ids_selected
				if ids_selected.contains(id_album) {
					selected_new.remove(id_album)
				} else {
					selected_new.insert(id_album)
				}
				list_state.selectMode = .selectAlbums(selected_new)
		}
	}
}

// MARK: Album art

@MainActor struct AlbumArt: View {
	let id_album: AlbumID
	let dim_limit: CGFloat
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
					Color(white: .oneFourth)
						.frame(width: dim_limit, height: dim_limit)
					Image(systemName: "music.note")
						.foregroundStyle(.secondary)
						.font(.title)
				}
			}
#endif
		}
		.animation(nil, value: id_album) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works
		.accessibilityLabel(InterfaceText.Album_artwork)
	}
	private var artwork: MusicKit.Artwork? {
		return Librarian.shared.mkSection(albumID: id_album)?.artwork
	}
}

// MARK: Album label

@MainActor struct AlbumLabel: View {
	let id_album: AlbumID
	let list_state: AlbumListState
	var body: some View {
		HStack(alignment: .lastTextBaseline) {
			ImageNowPlaying().hidden()
			stack_text // Align with `SongRow`.
			if WorkingOn.select_range {
				Spacer()
				Menu {
					b_above
					b_below
				} label: {
					switch list_state.selectMode {
						case .selectSongs, .view: ImageOverflow()
						case .selectAlbums(let idsSelected):
							if idsSelected.contains(id_album) {
								ImageOverflowSelected()
							} else {
								ImageOverflow()
							}
					}
				}
				.disabled({
					switch list_state.expansion {
						case .expanded: return true
						case .collapsed: return false
					}}())
				.animation(.default, value: list_state.expansion)
			}
		}.padding()
	}
	
	@ViewBuilder private var stack_text: some View {
		let info_album: AlbumInfo? = Librarian.shared.mkSectionInfo(albumID: id_album)
		let title_and_input_label: String = {
			guard let title_album = info_album?._title, title_album != ""
			else { return InterfaceText.Unknown_Album }
			return title_album
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text({
				guard let date = info_album?._release_date
				else { return InterfaceText._em_dash }
				return date.formatted(date: .numeric, time: .omitted)
			}())
			.foregroundStyle(sel_dimmed ? .tertiary : .secondary)
			.font(.caption2)
			.monospacedDigit()
			.accessibilitySortPriority(10)
			Text({
				guard let artist_album = info_album?._artist, artist_album != ""
				else { return InterfaceText.Unknown_Artist }
				return artist_album
			}())
			.foregroundStyle(sel_dimmed ? .tertiary : .secondary)
			.font_caption2Bold()
			.accessibilitySortPriority(20)
			Text(title_and_input_label)
				.font_title2Bold()
				.foregroundStyle(sel_dimmed ? .secondary : .primary)
				.accessibilitySortPriority(30) // Higher means sooner.
		}
		.animation(.default, value: sel_dimmed)
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title_and_input_label])
	}
	private var sel_dimmed: Bool {
		switch list_state.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs: return true
		}
	}
	
	@ViewBuilder private var b_above: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Range_Above : InterfaceText.Select_Range_Above,
			systemImage: "chevron.up.circle"
		) {
			list_state.change_album_range(from: id_album, forward: false)
		}.disabled(!list_state.hasAlbumRange(from: id_album, forward: false))
	}
	@ViewBuilder private var b_below: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Range_Below : InterfaceText.Select_Range_Below,
			systemImage: "chevron.down.circle"
		) {
			list_state.change_album_range(from: id_album, forward: true)
		}.disabled(!list_state.hasAlbumRange(from: id_album, forward: true))
	}
	private var is_selected: Bool {
		switch list_state.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let ids_selected): return ids_selected.contains(id_album)
		}
	}
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirm_play_id_song = Notification.Name("LRSongConfirmPlayWithID")
	let id_song: SongID
	let id_album: AlbumID
	let list_state: AlbumListState
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			stack_main
			if WorkingOn.select_range {
				Menu {
					b_above
					b_below
				} label: {
					switch list_state.selectMode {
						case .selectAlbums, .view: ImageOverflow()
						case .selectSongs(let ids_selected):
							if ids_selected.contains(id_song) {
								ImageOverflowSelected().accessibilityLabel(InterfaceText.Selected)
							} else {
								ImageOverflow()
							}
					}
				}
			}
		}
		.padding(.horizontal).padding(.top, .eight * 3/2).padding(.bottom, .eight * (WorkingOn.select_range ? 7/4 : 2))
		.background { sel_highlight }
		.overlay { sel_border }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	@ViewBuilder private var stack_main: some View {
		let info_song: SongInfo__? = {
#if targetEnvironment(simulator)
			guard let sim_song = Sim_MusicLibrary.shared.sim_songs[id_song]
			else { return nil }
			return SongInfo__(
				_title: sim_song.titleOnDisk ?? "",
				_artist: "",
				_disc: 1,
				_track: sim_song.trackNumberOnDisk)
#else
			guard let mkSong
			else { return nil }
			return SongInfo__(
				_title: mkSong.title,
				_artist: mkSong.artistName,
				_disc: mkSong.discNumber,
				_track: mkSong.trackNumber)
#endif
		}()
		let title: String? = info_song?._title
		let info_album: AlbumInfo? = librarian.mkSectionInfo(albumID: id_album)
		HStack(alignment: .firstTextBaseline) {
			IndicatorNowPlaying(id_song: id_song)
			VStack(alignment: .leading, spacing: .eight * 1/2) { // Align with `AlbumLabel`.
				Text(title ?? InterfaceText._em_dash)
				if
					let artist_song = info_song?._artist,
					let artist_album = info_album?._artist,
					artist_song != "", artist_album != "",
					artist_song != artist_album
				{
					Text(artist_song)
						.foregroundStyle(.secondary)
						.font_footnote()
				}
			}
			Spacer()
			Text({
				guard let info_song, let info_album else { return InterfaceText._octothorpe }
				let f_track: String = {
					guard let track = info_song._track else { return InterfaceText._octothorpe }
					return String(track)
				}()
				if info_album._disc_count >= 2 {
					let f_disc: String = {
						guard let disc = info_song._disc else { return InterfaceText._octothorpe }
						return String(disc)
					}()
					return "\(f_disc)\(InterfaceText._interpunct)\(f_track)"
				} else {
					return f_track
				}
			}())
			.foregroundStyle(.secondary)
			.monospacedDigit()
		}
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title].compacted())
		.accessibilityAddTraits(.isButton)
		.task {
			mkSong = await librarian.mkSong_fetched(mpID: id_song)
		}
	}
	@State private var mkSong: MKSong? = nil
	private let librarian: Librarian = .shared
	
	@ViewBuilder private var sel_highlight: some View {
		let highlighting: Bool = { switch list_state.selectMode {
			case .selectAlbums: return false
			case .view(let id_activated): return id_activated == id_song
			case .selectSongs(let ids_selected): return ids_selected.contains(id_song)
		}}()
		Color.accentColor
			.opacity(highlighting ? .oneHalf : .zero)
			.animation( // Animates when entering vanilla mode. Doesn’t animate when entering or staying in select mode, or activating song in view mode.
				{ switch list_state.selectMode {
					case .selectAlbums: return nil // Should never run
					case .view(let id_activated): return (id_activated == nil) ? .default : nil
					case .selectSongs: return nil // It’d be nice to animate deselecting after arranging, floating, and sinking, but not manually selecting or deselecting.
				}}(),
				value: list_state.selectMode)
	}
	@ViewBuilder private var sel_border: some View {
		switch list_state.selectMode {
			case .view, .selectAlbums: EmptyView()
			case .selectSongs(let ids_selected):
				if ids_selected.contains(id_song) {
					RectSelected()
				} else {
					RectUnselected()
				}
		}
	}
	
	private func tapped() {
		switch list_state.selectMode {
			case .selectAlbums: return
			case .view: NotificationCenter.default.post(name: Self.confirm_play_id_song, object: id_song)
			case .selectSongs(let ids_selected):
				var selected_new = ids_selected
				if ids_selected.contains(id_song) {
					selected_new.remove(id_song)
				} else {
					selected_new.insert(id_song)
				}
				list_state.selectMode = .selectSongs(selected_new)
		}
	}
	
	@ViewBuilder private var b_above: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Range_Above : InterfaceText.Select_Range_Above,
			systemImage: "chevron.up.circle"
		) {
			list_state.change_song_range(from: id_song, forward: false)
		}.disabled(!list_state.hasSongRange(from: id_song, forward: false))
	}
	@ViewBuilder private var b_below: some View {
		Button(
			is_selected ? InterfaceText.Deselect_Range_Below : InterfaceText.Select_Range_Below,
			systemImage: "chevron.down.circle"
		) {
			list_state.change_song_range(from: id_song, forward: true)
		}.disabled(!list_state.hasSongRange(from: id_song, forward: true))
	}
	private var is_selected: Bool {
		switch list_state.selectMode {
			case .selectAlbums, .view: return false
			case .selectSongs(let ids_selected): return ids_selected.contains(id_song)
		}
	}
}

// MARK: Now-playing indicator

struct IndicatorNowPlaying: View {
	let id_song: SongID
	var body: some View {
		ZStack {
			ImageNowPlaying().hidden()
			switch status {
				case .not_playing: EmptyView()
				case .paused:
					ImageNowPlaying()
						.foregroundStyle(.tint)
						.disabled(true)
				case .playing:
					ImageNowPlaying()
						.foregroundStyle(.tint)
			}
		}
		.accessibilityElement()
		.accessibilityLabel({ switch status {
			case .not_playing: return ""
			case .paused: return InterfaceText.Paused
			case .playing: return InterfaceText.Now_Playing
		}}())
		.accessibilityHidden({ switch status {
			case .paused, .playing: return false
			case .not_playing: return true
		}}())
	}
	@MainActor private var status: Status {
#if targetEnvironment(simulator)
		guard id_song == Sim_MusicLibrary.shared.current_sim_song?.songID
		else { return .not_playing }
		return .playing
#else
		// I could compare MusicKit’s now-playing `Song` to this instance’s Media Player identifier, but haven’t found a simple way. We could request this instance’s MusicKit `Song`, but that requires `await`ing.
		let _ = PlayerState.shared.signal
		let _ = Librarian.shared.isMerging // I think this should be unnecessary, but I’ve seen the indicator get outdated after deleting a recently played song.
		guard
			let state = ApplicationMusicPlayer._shared?.state,
			id_song == MPMusicPlayerController.idSongCurrent
		else { return .not_playing }
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	private enum Status { case not_playing, paused, playing }
}

// MARK: - Multipurpose

struct RectSelected: View {
	var body: some View {
		Rectangle()
			.strokeBorder(lineWidth: .eight)
			.foregroundStyle(.tint.opacity(.oneHalf))
	}
}
struct RectUnselected: View {
	var body: some View {
		Rectangle()
			.strokeBorder(lineWidth: .eight)
			.foregroundStyle(Material.ultraThin)
	}
}

struct ImageOverflowSelected: View {
	var body: some View {
		Image(systemName: "ellipsis.circle.fill")
			.font_body_dynamicTypeSizeUpToXxxLarge()
	}
}
struct ImageOverflow: View {
	var body: some View {
		Image(systemName: "ellipsis.circle.fill")
			.font_body_dynamicTypeSizeUpToXxxLarge()
			.symbolRenderingMode(.hierarchical)
	}
}

struct ImageNowPlaying: View {
	var body: some View {
		Image(systemName: "waveform")
			.font_body_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}
