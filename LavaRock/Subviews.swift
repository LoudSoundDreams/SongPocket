// 2022-12-12

import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Album row

@MainActor struct AlbumRow: View {
	let albumID: AlbumID
	let albumListState: AlbumListState
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			AlbumArt(albumID: albumID, maxSideLength: min(albumListState.viewportSize.width, albumListState.viewportSize.height))
				.opacity(select_opacity)
				.animation(.default, value: albumListState.selectMode)
				.overlay { if expansion_labeled {
					Rectangle().foregroundStyle(.thinMaterial)
				}}
			ZStack { if expansion_labeled {
				AlbumLabel(albumID: albumID, albumListState: albumListState).accessibilitySortPriority(10)
			}}
		}
		.animation(.linear(duration: .oneEighth), value: expansion_labeled)
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { select_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay(alignment: .topLeading) { select_indicator.padding() } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
	}
	private var expansion_labeled: Bool {
		switch albumListState.expansion {
			case .collapsed: return true
			case .expanded(let expandedAlbumID): return albumID != expandedAlbumID
		}
	}
	
	private var select_opacity: Double {
		switch albumListState.selectMode {
			case .view: return 1
			case .selectAlbums, .selectSongs: return .oneFourth
		}
	}
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch albumListState.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let selectedIDs): return selectedIDs.contains(albumID)
		}}()
		Color.accentColor.opacity(highlighting ? .oneHalf : .zero)
	}
	@ViewBuilder private var select_indicator: some View {
		switch albumListState.selectMode {
			case .view, .selectSongs: EmptyView()
			case .selectAlbums(let selectedIDs):
				if selectedIDs.contains(albumID) {
					SelectedIndicator()
				} else {
					UnselectedIndicator()
				}
		}
	}
	
	private func tapped() {
		switch albumListState.selectMode {
			case .selectSongs: return
			case .view:
				switch albumListState.expansion {
					case .collapsed:
						albumListState.expansion = .expanded(albumID)
					case .expanded(let expandedID):
						if albumID == expandedID {
							albumListState.expansion = .collapsed
						} else {
							albumListState.expansion = .expanded(albumID)
						}
				}
			case .selectAlbums(let selectedIDs):
				var newSelected = selectedIDs
				if selectedIDs.contains(albumID) {
					newSelected.remove(albumID)
				} else {
					newSelected.insert(albumID)
				}
				albumListState.selectMode = .selectAlbums(newSelected)
		}
	}
}

// MARK: Album art

@MainActor struct AlbumArt: View {
	let albumID: AlbumID
	let maxSideLength: CGFloat
	var body: some View {
		ZStack {
#if targetEnvironment(simulator)
			if let sim_album = Sim_MusicLibrary.shared.sim_albums[albumID] {
				Image(sim_album.artFileName)
					.resizable()
					.scaledToFit()
					.frame(width: maxSideLength, height: maxSideLength)
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
				ArtworkImage(artwork, width: maxSideLength)
			} else {
				ZStack {
					Color(white: .oneFourth)
						.frame(width: maxSideLength, height: maxSideLength)
					Image(systemName: "music.note")
						.foregroundStyle(.secondary)
						.font(.title)
				}
			}
#endif
		}
		.animation(nil, value: albumID) /* Maybe cell reuse causes laggy scrolling, and maybe this prevents that. */ .animation(.default, value: artwork) // Still works
		.accessibilityLabel(InterfaceText.albumArtwork)
	}
	private var artwork: MusicKit.Artwork? {
		return Librarian.shared.mkSection(albumID: albumID)?.artwork
	}
}

// MARK: Album label

@MainActor struct AlbumLabel: View {
	let albumID: AlbumID
	let albumListState: AlbumListState
	var body: some View {
		HStack(alignment: .lastTextBaseline) {
			NowPlayingImage().hidden()
			textStack // Align with `SongRow`.
//			Spacer()
//			Menu {
//				Button(InterfaceText.select, systemImage: "checkmark.circle") {
//					switch albumListState.selectMode {
//						case .selectSongs: return
//						case .view:
//							withAnimation(nil) {
//								albumListState.selectMode = .selectAlbums([albumID])
//							}
//						case .selectAlbums(let idsSelected):
//							let newSelected = idsSelected.union([albumID])
//							albumListState.selectMode = .selectAlbums(newSelected)
//					}
//				}
//			} label: { OverflowImage() }
//				.disabled({
//					switch albumListState.expansion {
//						case .expanded: return true
//						case .collapsed: return false
//					}}())
//				.animation(.default, value: albumListState.expansion)
		}.padding()
	}
	
	@ViewBuilder private var textStack: some View {
		let albumInfo: AlbumInfo? = Librarian.shared.mkSectionInfo(albumID: albumID)
		let titleAndInputLabel: String = {
			guard let albumTitle = albumInfo?._title, albumTitle != ""
			else { return InterfaceText.unknownAlbum }
			return albumTitle
		}()
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text({
				guard let date = albumInfo?._releaseDate
				else { return InterfaceText.emDash }
				return date.formatted(date: .numeric, time: .omitted)
			}())
			.foregroundStyle(select_dimmed ? .tertiary : .secondary)
			.font(.caption2)
			.monospacedDigit()
			.accessibilitySortPriority(10)
			Text({
				guard let albumArtist = albumInfo?._artist, albumArtist != ""
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
		switch albumListState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs: return true
		}
	}
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirmPlaySongID = Notification.Name("LRSongConfirmPlayWithID")
	let songID: SongID
	let albumID: AlbumID
	let albumListState: AlbumListState
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			mainStack
//			Menu {
//				Button(InterfaceText.select, systemImage: "checkmark.circle") {
//					switch albumListState.selectMode {
//						case .selectAlbums: return
//						case .view:
//							albumListState.selectMode = .selectSongs([songID])
//						case .selectSongs(let idsSelected):
//							let newSelected = idsSelected.union([songID])
//							albumListState.selectMode = .selectSongs(newSelected)
//					}
//				}
//			} label: { OverflowImage() }
		}
		.padding(.horizontal).padding(.top, .eight * 3/2).padding(.bottom, .eight * 2)
		.background { select_highlight }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	@ViewBuilder private var mainStack: some View {
		let songInfo: SongInfo__? = {
#if targetEnvironment(simulator)
			guard let sim_song = Sim_MusicLibrary.shared.sim_songs[songID]
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
		let title: String? = songInfo?._title
		let albumInfo: AlbumInfo? = librarian.mkSectionInfo(albumID: albumID)
		HStack(alignment: .firstTextBaseline) {
			select_indicator
			NowPlayingIndicator(songID: songID)
			VStack(alignment: .leading, spacing: .eight * 1/2) { // Align with `AlbumLabel`.
				Text(title ?? InterfaceText.emDash)
				if
					let songArtist = songInfo?._artist,
					songArtist != "",
					songArtist != albumInfo?._artist
				{
					Text(songArtist)
						.foregroundStyle(.secondary)
						.font_footnote()
				}
			}
			Spacer()
			Text({
				guard let songInfo, let albumInfo else { return InterfaceText.octothorpe }
				let trackFormatted: String = {
					guard let track = songInfo._track else { return InterfaceText.octothorpe }
					return String(track)
				}()
				if albumInfo._discCount >= 2 {
					let discFormatted: String = {
						guard let disc = songInfo._disc else { return InterfaceText.octothorpe }
						return String(disc)
					}()
					return "\(discFormatted)\(InterfaceText.interpunct)\(trackFormatted)"
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
			mkSong = await librarian.mkSong_fetched(mpID: songID)
		}
	}
	@State private var mkSong: MKSong? = nil
	private let librarian: Librarian = .shared
	
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch albumListState.selectMode {
			case .selectAlbums: return false
			case .view(let activatedSongID): return activatedSongID == songID
			case .selectSongs(let selectedIDs): return selectedIDs.contains(songID)
		}}()
		Color.accentColor
			.opacity(highlighting ? .oneHalf : .zero)
			.animation( // Animates when entering vanilla mode. Doesn’t animate when entering or staying in select mode, or activating song in view mode.
				{ switch albumListState.selectMode {
					case .selectAlbums: return nil // Should never run
					case .view(let activatedSongID): return (activatedSongID == nil) ? .default : nil
					case .selectSongs: return nil // It’d be nice to animate deselecting after arranging, floating, and sinking, but not manually selecting or deselecting.
				}}(),
				value: albumListState.selectMode)
	}
	private var select_indicator: some View {
		ZStack {
			switch albumListState.selectMode {
				case .view, .selectAlbums: EmptyView()
				case .selectSongs(let selectedIDs):
					ZStack {
						UnselectedIndicator()
						if selectedIDs.contains(songID) {
							SelectedIndicator().transition(.identity) // Prevents animation when selecting or deselecting (but not when inserting or removing entire stack)
						}
					}.padding(.trailing)
			}
		}.animation(.default, value: albumListState.selectMode)
	}
	
	private func tapped() {
		switch albumListState.selectMode {
			case .selectAlbums: return
			case .view: NotificationCenter.default.post(name: Self.confirmPlaySongID, object: songID)
			case .selectSongs(let selectedIDs):
				var newSelected = selectedIDs
				if selectedIDs.contains(songID) {
					newSelected.remove(songID)
				} else {
					newSelected.insert(songID)
				}
				albumListState.selectMode = .selectSongs(newSelected)
		}
	}
}

// MARK: Now-playing indicator

struct NowPlayingIndicator: View {
	let songID: SongID
	var body: some View {
		ZStack {
			NowPlayingImage().hidden()
			switch status {
				case .notPlaying: EmptyView()
				case .paused:
					NowPlayingImage()
						.foregroundStyle(.tint)
						.disabled(true)
				case .playing:
					NowPlayingImage()
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
		guard songID == Sim_MusicLibrary.shared.current_sim_song?.songID
		else { return .notPlaying }
		return .playing
#else
		// I could compare MusicKit’s now-playing `Song` to this instance’s Media Player identifier, but haven’t found a simple way. We could request this instance’s MusicKit `Song`, but that requires `await`ing.
		let _ = PlayerState.shared.signal
		let _ = Librarian.shared.isMerging // I think this should be unnecessary, but I’ve seen the indicator get outdated after deleting a recently played song.
		guard
			let state = ApplicationMusicPlayer._shared?.state,
			songID == MPMusicPlayerController.nowPlayingID
		else { return .notPlaying }
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	private enum Status { case notPlaying, paused, playing }
}

// MARK: - Multipurpose

struct SelectedIndicator: View {
	var body: some View {
		Image(systemName: "checkmark.circle.fill")
			.symbolRenderingMode(.palette)
			.foregroundStyle(.white, .tint)
	}
}
struct UnselectedIndicator: View {
	var body: some View {
		Image(systemName: "circle")
			.foregroundStyle(.secondary)
	}
}

struct OverflowImage: View {
	var body: some View {
		Image(systemName: "ellipsis.circle.fill")
			.font_body_dynamicTypeSizeUpToXxxLarge()
			.symbolRenderingMode(.hierarchical)
	}
}

struct NowPlayingImage: View {
	var body: some View {
		Image(systemName: "waveform")
			.font_body_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}
