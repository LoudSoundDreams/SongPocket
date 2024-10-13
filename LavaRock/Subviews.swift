// 2022-12-12

import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Album row

@MainActor struct AlbumRow: View {
	let idAlbum: AlbumID
	let listState: AlbumListState
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			AlbumArt(idAlbum: idAlbum, dimLimit: min(listState.viewportSize.width, listState.viewportSize.height))
				.opacity(select_opacity)
				.animation(.default, value: listState.selectMode)
				.overlay { if expansion_labeled {
					Rectangle().foregroundStyle(Material.thin)
				}}
			ZStack { if expansion_labeled {
				AlbumLabel(idAlbum: idAlbum, listState: listState).accessibilitySortPriority(10)
			}}
		}
		.animation(.linear(duration: .oneEighth), value: expansion_labeled)
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { select_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay { select_border } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
	}
	private var expansion_labeled: Bool {
		switch listState.expansion {
			case .collapsed: return true
			case .expanded(let idExpanded): return idAlbum != idExpanded
		}
	}
	
	private var select_opacity: Double {
		switch listState.selectMode {
			case .view: return 1
			case .selectAlbums, .selectSongs: return .oneFourth
		}
	}
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch listState.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let idsSelected): return idsSelected.contains(idAlbum)
		}}()
		if highlighting {
			Color.accentColor.opacity(.oneHalf)
		} else {
			EmptyView()
		}
	}
	@ViewBuilder private var select_border: some View {
		switch listState.selectMode {
			case .view, .selectSongs: EmptyView()
			case .selectAlbums(let idsSelected):
				if idsSelected.contains(idAlbum) {
					RectSelected()
				} else {
					RectUnselected()
				}
		}
	}
	
	private func tapped() {
		switch listState.selectMode {
			case .selectSongs: return
			case .view:
				switch listState.expansion {
					case .collapsed:
						listState.expansion = .expanded(idAlbum)
					case .expanded(let idExpanded):
						if idAlbum == idExpanded {
							listState.expansion = .collapsed
						} else {
							listState.expansion = .expanded(idAlbum)
						}
				}
			case .selectAlbums(let idsSelected):
				var newSelected = idsSelected
				if idsSelected.contains(idAlbum) {
					newSelected.remove(idAlbum)
				} else {
					newSelected.insert(idAlbum)
				}
				listState.selectMode = .selectAlbums(newSelected)
		}
	}
}

// MARK: Album art

@MainActor struct AlbumArt: View {
	let idAlbum: AlbumID
	let dimLimit: CGFloat
	var body: some View {
		ZStack {
#if targetEnvironment(simulator)
			if let sim_album = Sim_MusicLibrary.shared.sim_albums[idAlbum] {
				Image(sim_album.artFileName)
					.resizable()
					.scaledToFit()
					.frame(width: dimLimit, height: dimLimit)
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
				ArtworkImage(artwork, width: dimLimit)
			} else {
				ZStack {
					Color(white: .oneFourth)
						.frame(width: dimLimit, height: dimLimit)
					Image(systemName: "music.note")
						.foregroundStyle(.secondary)
						.font(.title)
				}
			}
#endif
		}
		.animation(nil, value: idAlbum) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works
		.accessibilityLabel(InterfaceText.albumArtwork)
	}
	private var artwork: MusicKit.Artwork? {
		return Librarian.shared.mkSection(albumID: idAlbum)?.artwork
	}
}

// MARK: Album label

@MainActor struct AlbumLabel: View {
	let idAlbum: AlbumID
	let listState: AlbumListState
	var body: some View {
		HStack(alignment: .lastTextBaseline) {
			ImageNowPlaying().hidden()
			textStack // Align with `SongRow`.
			if WorkingOn.selectRange {
				Spacer()
				Menu {
					aboveButton
					belowButton
				} label: {
					switch listState.selectMode {
						case .selectSongs, .view: ImageOverflow()
						case .selectAlbums(let idsSelected):
							if idsSelected.contains(idAlbum) {
								ImageOverflowSelected()
							} else {
								ImageOverflow()
							}
					}
				}
				.disabled({
					switch listState.expansion {
						case .expanded: return true
						case .collapsed: return false
					}}())
				.animation(.default, value: listState.expansion)
			}
		}.padding()
	}
	
	@ViewBuilder private var textStack: some View {
		let infoAlbum: AlbumInfo? = Librarian.shared.mkSectionInfo(albumID: idAlbum)
		let titleAndInputLabel: String = {
			guard let albumTitle = infoAlbum?._title, albumTitle != ""
			else { return InterfaceText.unknownAlbum }
			return albumTitle
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text({
				guard let date = infoAlbum?._releaseDate
				else { return InterfaceText._emDash }
				return date.formatted(date: .numeric, time: .omitted)
			}())
			.foregroundStyle(select_dimmed ? .tertiary : .secondary)
			.font(.caption2)
			.monospacedDigit()
			.accessibilitySortPriority(10)
			Text({
				guard let albumArtist = infoAlbum?._artist, albumArtist != ""
				else { return InterfaceText.unknownArtist }
				return albumArtist
			}())
			.foregroundStyle(select_dimmed ? .tertiary : .secondary)
			.font_caption2Bold()
			.accessibilitySortPriority(20)
			Text(titleAndInputLabel)
				.font_title2Bold()
				.foregroundStyle(select_dimmed ? .secondary : .primary)
				.accessibilitySortPriority(30)
		}
		.animation(.default, value: select_dimmed)
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([titleAndInputLabel])
	}
	private var select_dimmed: Bool {
		switch listState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs: return true
		}
	}
	
	@ViewBuilder private var aboveButton: some View {
		Button(
			isSelected ? InterfaceText.deselectRangeAbove : InterfaceText.selectRangeAbove,
			systemImage: "chevron.up.circle"
		) {
			listState.changeAlbumRange(from: idAlbum, forward: false)
		}.disabled(!listState.hasAlbumRange(from: idAlbum, forward: false))
	}
	@ViewBuilder private var belowButton: some View {
		Button(
			isSelected ? InterfaceText.deselectRangeBelow : InterfaceText.selectRangeBelow,
			systemImage: "chevron.down.circle"
		) {
			listState.changeAlbumRange(from: idAlbum, forward: true)
		}.disabled(!listState.hasAlbumRange(from: idAlbum, forward: true))
	}
	private var isSelected: Bool {
		switch listState.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let idsSelected): return idsSelected.contains(idAlbum)
		}
	}
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirmPlaySongID = Notification.Name("LRSongConfirmPlayWithID")
	let idSong: SongID
	let idAlbum: AlbumID
	let listState: AlbumListState
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			mainStack
			if WorkingOn.selectRange {
				Menu {
					aboveButton
					belowButton
				} label: {
					switch listState.selectMode {
						case .selectAlbums, .view: ImageOverflow()
						case .selectSongs(let idsSelected):
							if idsSelected.contains(idSong) {
								ImageOverflowSelected()
							} else {
								ImageOverflow()
							}
					}
				}
			}
		}
		.padding(.horizontal).padding(.top, .eight * 3/2).padding(.bottom, .eight * (WorkingOn.selectRange ? 7/4 : 2))
		.background { select_highlight }
		.overlay { select_border }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	@ViewBuilder private var mainStack: some View {
		let infoSong: SongInfo__? = {
#if targetEnvironment(simulator)
			guard let sim_song = Sim_MusicLibrary.shared.sim_songs[idSong]
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
		let title: String? = infoSong?._title
		let infoAlbum: AlbumInfo? = librarian.mkSectionInfo(albumID: idAlbum)
		HStack(alignment: .firstTextBaseline) {
			IndicatorNowPlaying(idSong: idSong)
			VStack(alignment: .leading, spacing: .eight * 1/2) { // Align with `AlbumLabel`.
				Text(title ?? InterfaceText._emDash)
				if
					let songArtist = infoSong?._artist,
					songArtist != "",
					songArtist != infoAlbum?._artist
				{
					Text(songArtist)
						.foregroundStyle(.secondary)
						.font_footnote()
				}
			}
			Spacer()
			Text({
				guard let infoSong, let infoAlbum else { return InterfaceText._octothorpe }
				let trackFormatted: String = {
					guard let track = infoSong._track else { return InterfaceText._octothorpe }
					return String(track)
				}()
				if infoAlbum._discCount >= 2 {
					let discFormatted: String = {
						guard let disc = infoSong._disc else { return InterfaceText._octothorpe }
						return String(disc)
					}()
					return "\(discFormatted)\(InterfaceText._interpunct)\(trackFormatted)"
				} else {
					return trackFormatted
				}
			}())
			.foregroundStyle(.secondary)
			.monospacedDigit()
		}
		.accessibilityElement(children: .combine)
		.accessibilityInputLabels([title].compacted())
		.accessibilityAddTraits(.isButton)
		.task {
			mkSong = await librarian.mkSong_fetched(mpID: idSong)
		}
	}
	@State private var mkSong: MKSong? = nil
	private let librarian: Librarian = .shared
	
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch listState.selectMode {
			case .selectAlbums: return false
			case .view(let idActivated): return idActivated == idSong
			case .selectSongs(let idsSelected): return idsSelected.contains(idSong)
		}}()
		Color.accentColor
			.opacity(highlighting ? .oneHalf : .zero)
			.animation( // Animates when entering vanilla mode. Doesn’t animate when entering or staying in select mode, or activating song in view mode.
				{ switch listState.selectMode {
					case .selectAlbums: return nil // Should never run
					case .view(let idActivated): return (idActivated == nil) ? .default : nil
					case .selectSongs: return nil // It’d be nice to animate deselecting after arranging, floating, and sinking, but not manually selecting or deselecting.
				}}(),
				value: listState.selectMode)
	}
	@ViewBuilder private var select_border: some View {
		switch listState.selectMode {
			case .view, .selectAlbums: EmptyView()
			case .selectSongs(let idsSelected):
				if idsSelected.contains(idSong) {
					RectSelected()
				} else {
					RectUnselected()
				}
		}
	}
	
	private func tapped() {
		switch listState.selectMode {
			case .selectAlbums: return
			case .view: NotificationCenter.default.post(name: Self.confirmPlaySongID, object: idSong)
			case .selectSongs(let idsSelected):
				var newSelected = idsSelected
				if idsSelected.contains(idSong) {
					newSelected.remove(idSong)
				} else {
					newSelected.insert(idSong)
				}
				listState.selectMode = .selectSongs(newSelected)
		}
	}
	
	@ViewBuilder private var aboveButton: some View {
		Button(
			isSelected ? InterfaceText.deselectRangeAbove : InterfaceText.selectRangeAbove,
			systemImage: "chevron.up.circle"
		) {
		}
	}
	@ViewBuilder private var belowButton: some View {
		Button(
			isSelected ? InterfaceText.deselectRangeBelow : InterfaceText.selectRangeBelow,
			systemImage: "chevron.down.circle"
		) {
		}
	}
	private var isSelected: Bool {
		switch listState.selectMode {
			case .selectAlbums, .view: return false
			case .selectSongs(let idsSelected): return idsSelected.contains(idSong)
		}
	}
}

// MARK: Now-playing indicator

struct IndicatorNowPlaying: View {
	let idSong: SongID
	var body: some View {
		ZStack {
			ImageNowPlaying().hidden()
			switch status {
				case .notPlaying: EmptyView()
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
			case .notPlaying: return ""
			case .paused: return InterfaceText.paused
			case .playing: return InterfaceText.nowPlaying
		}}())
		.accessibilityHidden({ switch status {
			case .paused, .playing: return false
			case .notPlaying: return true
		}}())
	}
	@MainActor private var status: Status {
#if targetEnvironment(simulator)
		guard idSong == Sim_MusicLibrary.shared.current_sim_song?.songID
		else { return .notPlaying }
		return .playing
#else
		// I could compare MusicKit’s now-playing `Song` to this instance’s Media Player identifier, but haven’t found a simple way. We could request this instance’s MusicKit `Song`, but that requires `await`ing.
		let _ = PlayerState.shared.signal
		let _ = Librarian.shared.isMerging // I think this should be unnecessary, but I’ve seen the indicator get outdated after deleting a recently played song.
		guard
			let state = ApplicationMusicPlayer._shared?.state,
			idSong == MPMusicPlayerController.idSongCurrent
		else { return .notPlaying }
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	private enum Status { case notPlaying, paused, playing }
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
