// 2022-12-12

import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Album row

@MainActor struct AlbumRow: View {
	static let activateAlbum = Notification.Name("LRActivateAlbum")
	let album: Album
	let viewportWidth: CGFloat
	let viewportHeight: CGFloat
	let albumListState: AlbumListState
	var body: some View {
		VStack(spacing: .zero) {
			Rectangle().frame(width: 42, height: 1 * pointsPerPixel).hidden()
			art
		}
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport
		.opacity(foregroundOpacity)
		.background {
			// TO DO: Animate removing, like for song rows
			Color.accentColor
				.opacity({
					switch albumListState.current {
						case .view: return .zero
						case .edit(let selected):
							guard selected.contains(album.albumPersistentID) else { return .zero }
							return .oneHalf
					}
				}())
		}
		.overlay(alignment: .bottomLeading) { selectionOverlay }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityAddTraits(.isButton)
		.accessibilityLabel(musicKitAlbums[MusicItemID(String(album.albumPersistentID))]?.title ?? InterfaceText.unknownAlbum)
		.accessibilityInputLabels([musicKitAlbums[MusicItemID(String(album.albumPersistentID))]?.title ?? InterfaceText.unknownAlbum])
	}
	@ViewBuilder private var art: some View {
#if targetEnvironment(simulator)
		if
			let fileName = (album.songs(sorted: true).first?.songInfo() as? Sim_SongInfo)?.coverArtFileName,
			let uiImage = UIImage(named: fileName)
		{
			Image(uiImage: uiImage)
				.resizable()
				.scaledToFit()
				.frame(width: maxSideLength, height: maxSideLength)
		} else {
			Color.red
		}
#else
		if let artwork = musicKitAlbums[MusicItemID(String(album.albumPersistentID))]?.artwork {
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
	private var maxSideLength: CGFloat { min(viewportWidth, viewportHeight) }
	private var musicKitAlbums: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] { MusicRepo.shared.musicKitAlbums }
	@Environment(\.pixelLength) private var pointsPerPixel
	private var foregroundOpacity: Double {
		switch albumListState.current {
			case .view: return 1
			case .edit: return pow(.oneHalf, 2)
		}
	}
	@ViewBuilder private var selectionOverlay: some View {
		switch albumListState.current {
			case .view: EmptyView()
			case .edit(let selected):
				if selected.contains(album.albumPersistentID) {
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
		switch albumListState.current {
			case .view: NotificationCenter.default.post(name: Self.activateAlbum, object: album)
			case .edit(let selected):
				var newSelected = selected
				let albumID = album.albumPersistentID
				if selected.contains(albumID) {
					newSelected.remove(albumID)
				} else {
					newSelected.insert(albumID)
				}
				albumListState.current = .edit(newSelected)
		}
	}
}

// MARK: - Album header

@MainActor struct AlbumHeader: View {
	let albumPersistentID: Int64
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			NowPlayingImage().hidden()
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text({
#if targetEnvironment(simulator)
					return Sim_SongInfo.current?.albumTitleOnDisk ?? InterfaceText.unknownAlbum
#else
					return musicKitAlbums[MusicItemID(String(albumPersistentID))]?.title ?? InterfaceText.unknownAlbum
#endif
				}())
				.fontTitle2Bold()
				.alignmentGuide_separatorLeading()
				Text({
#if targetEnvironment(simulator)
					return Sim_SongInfo.current?.albumArtistOnDisk ?? InterfaceText.unknownArtist
#else
					guard
						let albumArtist = musicKitAlbums[MusicItemID(String(albumPersistentID))]?.artistName,
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
					guard let date = musicKitAlbums[MusicItemID(String(albumPersistentID))]?.releaseDate else {
						return InterfaceText.emDash
					}
#endif
					return date.formatted(date: .numeric, time: .omitted)
				}())
				.foregroundStyle(.secondary)
				.font(.caption2)
				.monospacedDigit()
			}
			.padding(.bottom, .eight * 1/4)
			.animation(.default, value: musicKitAlbums)
			Spacer().alignmentGuide_separatorTrailing()
		}.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
	private var musicKitAlbums: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] { MusicRepo.shared.musicKitAlbums }
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let activateIndex = Notification.Name("LRActivateSongIndex")
	let song: Song
	let albumPersistentID: Int64
	var songListState: SongListState
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			songInfoStack
			Menu { overflowMenuContent } label: {
				Image(systemName: "ellipsis.circle.fill")
					.fontBody_dynamicTypeSizeUpToXxxLarge()
					.symbolRenderingMode(.hierarchical)
			}
			.disabled({ switch songListState.current {
				case .view: return false
				case .edit: return true
			}}())
			.onTapGesture { signal_tappedMenu.toggle() }
			.alignmentGuide_separatorTrailing()
		}
		.padding(.horizontal).padding(.vertical, .eight * 3/2)
		.background {
			Color.accentColor
				.opacity(shouldHighlight ? .oneHalf : .zero)
				.animation(shouldHighlight ? nil : .default, value: shouldHighlight) // Animates for deselecting, whether by user or programmatically. Never animates for selecting.
		}
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	@ViewBuilder private var selectionIndicator: some View {
		switch songListState.current {
			case .view: EmptyView()
			case .edit(let selected):
				if selected.contains(song.index) {
					Image(systemName: "checkmark.circle.fill")
						.symbolRenderingMode(.palette)
						.foregroundStyle(.white, Color.accentColor)
						.padding(.trailing)
				} else {
					Image(systemName: "circle")
						.foregroundStyle(.secondary)
						.padding(.trailing)
				}
		}
	}
	@ViewBuilder private var songInfoStack: some View {
		let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
		HStack(alignment: .firstTextBaseline) {
			selectionIndicator // TO DO: Animate inserting and removing
			NowPlayingIndicator(song: song, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10) // Bigger is sooner
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text(song.songInfo()?.titleOnDisk ?? InterfaceText.emDash)
					.alignmentGuide_separatorLeading()
				let albumArtistOptional = musicKitAlbums[MusicItemID(String(albumPersistentID))]?.artistName
				if let songArtist = info?.artistOnDisk, songArtist != albumArtistOptional {
					Text(songArtist)
						.foregroundStyle(.secondary)
						.fontFootnote()
				}
			}.padding(.bottom, .eight * 1/4)
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
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
	}
	private var shouldHighlight: Bool {
		switch songListState.current {
			case .view(let activated): return activated == song.index
			case .edit(let selected): return selected.contains(song.index)
		}
	}
	private func tapped() {
		switch songListState.current {
			case .view: NotificationCenter.default.post(name: Self.activateIndex, object: song.index)
			case .edit(let selected):
				var newSelected = selected
				let index = song.index
				if selected.contains(index) {
					newSelected.remove(index)
				} else {
					newSelected.insert(index)
				}
				songListState.current = .edit(newSelected)
		}
	}
	@ViewBuilder private var overflowMenuContent: some View {
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
	private var musicKitAlbums: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] { MusicRepo.shared.musicKitAlbums }
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
