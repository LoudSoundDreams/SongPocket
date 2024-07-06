// 2022-12-12

import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Album row

@MainActor struct AlbumRow: View {
	static let openAlbumID = Notification.Name("LROpenAlbumID")
	let albumID: AlbumID
	let viewportWidth: CGFloat
	let viewportHeight: CGFloat
	let albumListState: AlbumListState
	var body: some View {
		VStack(spacing: .zero) {
			Rectangle().frame(width: 42, height: 1 * pointsPerPixel).hidden()
			art.opacity(select_opacity) // `withAnimation` animates this when toggling select mode.
		}
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { select_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay(alignment: .bottomLeading) { select_overlay } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityAddTraits(.isButton)
		.accessibilityLabel(musicKitAlbums[MusicItemID(String(albumID))]?.title ?? InterfaceText.unknownAlbum)
		.accessibilityInputLabels([musicKitAlbums[MusicItemID(String(albumID))]?.title ?? InterfaceText.unknownAlbum])
	}
	private var select_opacity: Double {
		switch albumListState.selectMode {
			case .view: return 1
			case .selectAlbums: return pow(.oneHalf, 2)
		}
	}
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch albumListState.selectMode {
			case .view: return false
			case .selectAlbums(let selectedAlbumIDs): return selectedAlbumIDs.contains(albumID)
		}}()
		Color.accentColor
			.opacity(highlighting ? .oneHalf : .zero)
	}
	@ViewBuilder private var select_overlay: some View {
		switch albumListState.selectMode {
			case .view: EmptyView()
			case .selectAlbums(let selectedAlbumIDs):
				if selectedAlbumIDs.contains(albumID) {
					Image(systemName: "checkmark.circle.fill")
						.symbolRenderingMode(.palette)
						.foregroundStyle(.white, Color.accentColor)
						.padding()
				} else {
					Image(systemName: "circle")
						.foregroundStyle(.secondary)
						.padding()
				}
		}
	}
	private func tapped() {
		switch albumListState.selectMode {
			case .view: NotificationCenter.default.post(name: Self.openAlbumID, object: albumID)
			case .selectAlbums(let selectedAlbumIDs):
				var newSelected = selectedAlbumIDs
				if selectedAlbumIDs.contains(albumID) {
					newSelected.remove(albumID)
				} else {
					newSelected.insert(albumID)
				}
				albumListState.selectMode = .selectAlbums(newSelected)
		}
	}
	@Environment(\.pixelLength) private var pointsPerPixel
	
	@ViewBuilder private var art: some View {
		let maxSideLength = min(viewportWidth, viewportHeight)
#if targetEnvironment(simulator)
		let songInfo = Sim_SongInfo.everyInfo.values.sorted { $0.songID < $1.songID }.first(where: {
			albumID == $0.albumID
		})!
		Image(songInfo.coverArtFileName)
			.resizable()
			.scaledToFit()
			.frame(width: maxSideLength, height: maxSideLength)
#else
		if let artwork = musicKitAlbums[MusicItemID(String(albumID))]?.artwork {
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
				Color(uiColor: .secondarySystemBackground) // Close to what Apple Music uses
					.frame(width: maxSideLength, height: maxSideLength)
				Image(systemName: "music.note")
					.foregroundStyle(.secondary)
					.font(.title)
			}
			.accessibilityLabel(InterfaceText.albumArtwork)
			.accessibilityIgnoresInvertColors()
		}
#endif
	}
	
	private var musicKitAlbums: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] { MusicRepo.shared.musicKitAlbums }
}

// MARK: - Album header

@MainActor struct AlbumHeader: View {
	let albumID: AlbumID
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			NowPlayingImage().hidden()
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text({
#if targetEnvironment(simulator)
					return Sim_SongInfo.current?.albumTitleOnDisk ?? InterfaceText.unknownAlbum
#else
					return musicKitAlbums[MusicItemID(String(albumID))]?.title ?? InterfaceText.unknownAlbum
#endif
				}())
				.fontTitle2Bold()
				Text({
#if targetEnvironment(simulator)
					return Sim_SongInfo.current?.albumArtistOnDisk ?? InterfaceText.unknownArtist
#else
					guard
						let albumArtist = musicKitAlbums[MusicItemID(String(albumID))]?.artistName,
						albumArtist != ""
					else { return InterfaceText.unknownArtist }
					return albumArtist
#endif
				}())
				.foregroundStyle(.secondary)
				.fontCaption2Bold()
				Text({
#if targetEnvironment(simulator)
					guard let date = Sim_SongInfo.current?.releaseDateOnDisk else {
						return InterfaceText.emDash
					}
#else
					guard let date = musicKitAlbums[MusicItemID(String(albumID))]?.releaseDate else {
						return InterfaceText.emDash
					}
#endif
					return date.formatted(date: .numeric, time: .omitted)
				}())
				.foregroundStyle(.secondary)
				.font(.caption2)
				.monospacedDigit()
			}
			.animation(.default, value: musicKitAlbums) // TO DO: Distracting when loading for the first time
		}.padding()
	}
	private var musicKitAlbums: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] { MusicRepo.shared.musicKitAlbums }
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirmPlaySongID = Notification.Name("LRConfirmPlaySongID")
	let song: Song
	let albumID: AlbumID
	let songListState: SongListState
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			mainStack
				.accessibilityElement(children: .combine)
				.accessibilityAddTraits(.isButton)
				.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
			overflowMenu
		}
		.padding(.horizontal).padding(.top, .eight * 3/2).padding(.bottom, .eight * 2)
		.background { select_highlight }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch songListState.selectMode {
			case .view(let activatedSongID): return activatedSongID == song.persistentID
			case .select(let selected): return selected.contains(song.index)
		}}()
		Color.accentColor
			.opacity(highlighting ? .oneHalf : .zero)
			.animation( // Animates when entering vanilla mode. Doesn’t animate when entering or staying in select mode, or activating song in view mode.
				{ switch songListState.selectMode {
					case .view(let activatedSongID): return (activatedSongID == nil) ? .default: nil
					case .select: return nil
				}}(),
				value: songListState.selectMode)
	}
	private func tapped() {
		switch songListState.selectMode {
			case .view: NotificationCenter.default.post(name: Self.confirmPlaySongID, object: song.persistentID)
			case .select(let selected):
				var newSelected = selected
				let index = song.index
				if selected.contains(index) {
					newSelected.remove(index)
				} else {
					newSelected.insert(index)
				}
				songListState.selectMode = .select(newSelected)
		}
	}
	
	@ViewBuilder private var mainStack: some View {
		let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
		HStack(alignment: .firstTextBaseline) {
			select_indicator
			NowPlayingIndicator(song: song, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10) // Bigger is sooner
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text(song.songInfo()?.titleOnDisk ?? InterfaceText.emDash)
				let albumArtistOptional = musicKitAlbums[MusicItemID(String(albumID))]?.artistName
				if let songArtist = info?.artistOnDisk, songArtist != albumArtistOptional {
					Text(songArtist)
						.foregroundStyle(.secondary)
						.fontFootnote()
				}
			}
			Spacer()
			Text({
				guard let info else { return InterfaceText.octothorpe }
				return (
					info.shouldShowDiscNumber
					? info.discAndTrackFormatted()
					: info.trackFormatted()
				)
			}())
			.foregroundStyle(.secondary)
			.monospacedDigit()
		}
	}
	@ViewBuilder private var select_indicator: some View {
		ZStack {
			switch songListState.selectMode {
				case .view: EmptyView()
				case .select(let selected):
					ZStack {
						Image(systemName: "circle")
							.foregroundStyle(.secondary)
							.padding(.trailing)
						if selected.contains(song.index) {
							Image(systemName: "checkmark.circle.fill")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.white, Color.accentColor)
								.padding(.trailing)
								.transition(.identity) // Prevents animation when selecting or deselecting (but not when inserting or removing entire stack)
						}
					}
			}
		}.animation(.default, value: songListState.selectMode)
	}
	private var musicKitAlbums: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] { MusicRepo.shared.musicKitAlbums }
	
	private var overflowMenu: some View {
		Menu { menuContent } label: {
			Image(systemName: "ellipsis.circle.fill")
				.fontBody_dynamicTypeSizeUpToXxxLarge()
				.symbolRenderingMode(.hierarchical)
		}
		.onTapGesture { signal_tappedMenu.toggle() }
		.disabled({ switch songListState.selectMode { // It’d be nice to animate this, but SwiftUI unnecessarily moves the button if the text stack resizes.
			case .view: return false
			case .select: return true
		}}())
	}
	@ViewBuilder private var menuContent: some View {
		Button {
			Task { await song.play() }
		} label: { Label(InterfaceText.play, systemImage: "play") }
		
		Divider()
		Button {
			Task { await song.playLast() }
		} label: { Label(InterfaceText.playLast, systemImage: "text.line.last.and.arrowtriangle.forward") }
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		Button {
			Task { await song.playRestOfAlbumLast() }
		} label: {
			Label(InterfaceText.playRestOfAlbumLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}.disabled((signal_tappedMenu && false) || song.isAtBottomOfAlbum()) // Hopefully the compiler never optimizes away the dependency on the SwiftUI state property
	}
	@State private var signal_tappedMenu = false // Value doesn’t actually matter
}

// MARK: - Now-playing indicator

struct NowPlayingIndicator: View {
	let song: Song
	@ObservedObject var state: SystemMusicPlayer.State
	@ObservedObject var queue: SystemMusicPlayer.Queue
	var body: some View {
		ZStack(alignment: .leading) {
			NowPlayingImage().hidden()
			switch status {
				case .notPlaying: EmptyView()
				case .paused:
					Image(systemName: "speaker.fill")
						.fontBody_dynamicTypeSizeUpToXxxLarge()
						.imageScale(.small)
				case .playing:
					NowPlayingImage()
						.symbolRenderingMode(.hierarchical)
			}
		}
		.foregroundStyle(Color.accentColor)
		.accessibilityElement()
		.accessibilityLabel({ switch status {
			case .notPlaying: return ""
			case .paused: return InterfaceText.paused
			case .playing: return InterfaceText.nowPlaying
		}}())
	}
	private var status: Status {
#if targetEnvironment(simulator)
		let sim_info = song.songInfo() as! Sim_SongInfo
		guard sim_info == Sim_SongInfo.current else { return .notPlaying }
		return .playing
#else
		// I could compare MusicKit’s now-playing `Song` to this instance’s Media Player identifier, but haven’t found a simple way. We could request this instance’s MusicKit `Song`, but that requires `await`ing.
		guard song.persistentID == MPMusicPlayerController._system?.nowPlayingItem?.songID else { return .notPlaying }
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	private enum Status { case notPlaying, paused, playing }
}
struct NowPlayingImage: View {
	var body: some View {
		Image(systemName: "speaker.wave.2.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}
