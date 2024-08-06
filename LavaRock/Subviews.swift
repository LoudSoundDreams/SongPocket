// 2022-12-12

import SwiftUI
import MusicKit
import MediaPlayer

// MARK: - Album row

@MainActor struct AlbumRow: View {
	static let expandAlbumID = Notification.Name("LRAlbumExpandWithID")
	static let collapse = Notification.Name("LRAlbumCollapse")
	let albumID: AlbumID
	let albumListState: AlbumListState
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			AlbumArt(albumID: albumID, maxSideLength: min(albumListState.viewportSize.width, albumListState.viewportSize.height))
				.opacity(select_opacity)
				.animation(.default, value: albumListState.selectMode) // TO DO: Is this slow?
				.overlay { if expansion_labeled {
					Rectangle().foregroundStyle(.thinMaterial)
				}}
			ZStack { if expansion_labeled {
				AlbumLabel(albumID: albumID, albumListState: albumListState)
			}}
		}
		.animation(.linear(duration: .oneEighth), value: expansion_labeled) // TO DO: Is this slow?
		.frame(maxWidth: .infinity) // Horizontally centers artwork in wide viewport.
		.background { select_highlight } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.overlay(alignment: .topLeading) { select_indicator } // `withAnimation` animates this when toggling select mode, but not when selecting or deselecting.
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
		.accessibilityLabel(InterfaceText.albumArtwork) // TO DO: Accessibility label “Selected”
		.accessibilityInputLabels([Text(crate.musicKitSection(albumID)?.title ?? InterfaceText.unknownAlbum)])
		.accessibilityAddTraits(.isButton)
	}
	private var expansion_labeled: Bool {
		switch albumListState.expansion {
			case .collapsed: return true
			case .expanded(let expandedAlbumID): return albumID != expandedAlbumID
		}
	}
	private let crate: Crate = .shared
	
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
					Image(systemName: "checkmark.circle.fill")
						.symbolRenderingMode(.palette)
						.foregroundStyle(.white, .tint)
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
			case .selectSongs: return
			case .view:
				switch albumListState.expansion {
					case .collapsed:
						NotificationCenter.default.post(name: Self.expandAlbumID, object: albumID)
					case .expanded(let expandedID):
						if albumID == expandedID {
							NotificationCenter.default.post(name: Self.collapse, object: nil)
						} else {
							NotificationCenter.default.post(name: Self.expandAlbumID, object: albumID)
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

// MARK: - Album art

@MainActor struct AlbumArt: View {
	let albumID: AlbumID
	let maxSideLength: CGFloat
	var body: some View {
		ZStack {
#if targetEnvironment(simulator)
			Image(Sim_MusicLibrary.shared.albumInfos[albumID]!.artFileName)
				.resizable()
				.scaledToFit()
				.frame(width: maxSideLength, height: maxSideLength)
#else
			if let artwork = crate.musicKitSection(albumID)?.artwork {
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
			}
#endif
		}.animation(.default, value: crate.musicKitSections) // TO DO: Is this slow?
	}
	private let crate: Crate = .shared
}

// MARK: - Album label

@MainActor struct AlbumLabel: View {
	let albumID: AlbumID
	let albumListState: AlbumListState
	var body: some View {
		HStack(alignment: .lastTextBaseline) {
			NowPlayingImage().hidden()
			textStack // Align with `SongRow`
			if Self.workingOnOverflowAlbum {
				Spacer()
				Menu { albumMenu } label: { OverflowImage() }
					.onTapGesture {}
					.disabled({ switch albumListState.selectMode { // We should also disable this when any album is expanded.
						case .view: return false
						case .selectAlbums, .selectSongs: return true
					}}())
			}
		}.padding()
	}
	private static let workingOnOverflowAlbum = 10 == 1
	
	private var textStack: some View {
		VStack(alignment: .leading, spacing: .eight * 1/2) {
			Text({
#if targetEnvironment(simulator)
				guard let date = Sim_MusicLibrary.shared.albumInfos[albumID]?._releaseDate else { return InterfaceText.emDash }
#else
				guard let date = crate.musicKitSection(albumID)?.releaseDate else { return InterfaceText.emDash }
#endif
				return date.formatted(date: .numeric, time: .omitted)
			}())
			.foregroundStyle(select_dimmed ? .tertiary : .secondary)
			.font(.caption2)
			.monospacedDigit()
			Text({
#if targetEnvironment(simulator)
				return Sim_MusicLibrary.shared.albumInfos[albumID]?._artist ?? InterfaceText.unknownArtist
#else
				guard
					let albumArtist = crate.musicKitSection(albumID)?.artistName,
					albumArtist != ""
				else { return InterfaceText.unknownArtist }
				return albumArtist
#endif
			}())
			.foregroundStyle(select_dimmed ? .tertiary : .secondary)
			.font_caption2Bold()
			Text({
#if targetEnvironment(simulator)
				return Sim_MusicLibrary.shared.albumInfos[albumID]?._title ?? InterfaceText.unknownAlbum
#else
				return crate.musicKitSection(albumID)?.title ?? InterfaceText.unknownAlbum
#endif
			}())
			.font_title2Bold()
			.foregroundStyle(select_dimmed ? .secondary : .primary)
		}
		.animation(.default, value: select_dimmed) // TO DO: Is this slow?
		.accessibilityInputLabels([Text("")])
	}
	private var select_dimmed: Bool {
		switch albumListState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs: return true
		}
	}
	private let crate: Crate = .shared
	
	@ViewBuilder private var albumMenu: some View {
		Button {
		} label: { Label(InterfaceText.play, systemImage: "play") }
		Button {
		} label: { Label(InterfaceText.playLater, systemImage: "text.line.last.and.arrowtriangle.forward") }
		if Self.workingOnShuffleAlbum {
			Button {
				SystemMusicPlayer._shared?.shuffleNow(albumID)
			} label: { Label(InterfaceText.shuffle, systemImage: "shuffle") }
		}
	}
	private static let workingOnShuffleAlbum = 10 == 1
}

// MARK: - Song row

@MainActor struct SongRow: View {
	static let confirmPlaySongID = Notification.Name("LRSongConfirmPlayWithID")
	let song: Song
	let albumID: AlbumID
	let albumListState: AlbumListState
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			select_indicator.accessibilityHidden(true) // TO DO: Accessibility label “Selected”
			infoStack
				.accessibilityElement(children: .combine)
				.accessibilityAddTraits(.isButton)
			songOverflow
		}
		.padding(.horizontal).padding(.top, .eight * 3/2).padding(.bottom, .eight * 2)
		.background { select_highlight }
		.contentShape(Rectangle())
		.onTapGesture { tapped() }
	}
	private var infoStack: some View {
		HStack(alignment: .firstTextBaseline) {
			NowPlayingIndicator(songID: song.persistentID, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue)
			let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
			VStack(alignment: .leading, spacing: .eight * 1/2) { // Align with `AlbumLabel`
				Text(info?.titleOnDisk ?? InterfaceText.emDash)
				let albumArtistOptional = crate.musicKitSection(albumID)?.artistName
				if let songArtist = info?.artistOnDisk, songArtist != albumArtistOptional {
					Text(songArtist)
						.foregroundStyle(.secondary)
						.font_footnote()
				}
			}
			Spacer()
			Text(info?.discAndTrackFormatted() ?? InterfaceText.octothorpe)
				.foregroundStyle(.secondary)
				.monospacedDigit()
		}
	}
	private let crate: Crate = .shared
	private var songOverflow: some View {
		Menu { songMenu } label: { OverflowImage() }
			.onTapGesture { signal_tappedMenu.toggle() }
			.disabled({ switch albumListState.selectMode { // It’d be nice to animate this, but SwiftUI unnecessarily moves the button if the text stack resizes.
					// When the menu is open, it’s actually `albumListState.selectMode` that disables or enables “Play Rest of Album Last”. We should change that to a sensical dependency.
				case .selectAlbums: return false
				case .view: return false
				case .selectSongs: return true
			}}())
	}
	@ViewBuilder private var songMenu: some View {
		Button {
			Task {
				guard let musicKitSong = await song.musicKitSong() else { return }
				SystemMusicPlayer._shared?.playNow([musicKitSong])
			}
		} label: { Label(InterfaceText.play, systemImage: "play") }
		Divider()
		Button {
			Task {
				guard let musicKitSong = await song.musicKitSong() else { return }
				SystemMusicPlayer._shared?.playLater([musicKitSong])
			}
		} label: { Label(InterfaceText.playLater, systemImage: "text.line.last.and.arrowtriangle.forward") }
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		Button {
			Task { await song.playRestOfAlbumLater() }
		} label: {
			Label(InterfaceText.playRestOfAlbumLater, systemImage: "text.line.last.and.arrowtriangle.forward")
		}.disabled((signal_tappedMenu && false) || song.isAtBottom()) // Hopefully the compiler never optimizes away the dependency on the SwiftUI state property
	}
	@State private var signal_tappedMenu = false // Value doesn’t actually matter
	
	@ViewBuilder private var select_highlight: some View {
		let highlighting: Bool = { switch albumListState.selectMode {
			case .selectAlbums: return false
			case .view(let activatedSongID): return activatedSongID == song.persistentID
			case .selectSongs(let selectedIDs): return selectedIDs.contains(song.persistentID)
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
	@ViewBuilder private var select_indicator: some View {
		ZStack {
			switch albumListState.selectMode {
				case .view, .selectAlbums: EmptyView()
				case .selectSongs(let selectedIDs):
					ZStack {
						Image(systemName: "circle")
							.foregroundStyle(.secondary)
							.padding(.trailing)
						if selectedIDs.contains(song.persistentID) {
							Image(systemName: "checkmark.circle.fill")
								.symbolRenderingMode(.palette)
								.foregroundStyle(.white, .tint)
								.padding(.trailing)
								.transition(.identity) // Prevents animation when selecting or deselecting (but not when inserting or removing entire stack)
						}
					}
			}
		}.animation(.default, value: albumListState.selectMode)
	}
	
	private func tapped() {
		switch albumListState.selectMode {
			case .selectAlbums: return
			case .view: NotificationCenter.default.post(name: Self.confirmPlaySongID, object: song.persistentID)
			case .selectSongs(let selectedIDs):
				let songID = song.persistentID
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

// MARK: - Now-playing indicator

struct NowPlayingIndicator: View {
	let songID: SongID
	@ObservedObject var state: SystemMusicPlayer.State
	@ObservedObject var queue: SystemMusicPlayer.Queue
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
		guard songID == Sim_MusicLibrary.shared.currentSongInfo?.songID else { return .notPlaying }
		return .playing
#else
		// I could compare MusicKit’s now-playing `Song` to this instance’s Media Player identifier, but haven’t found a simple way. We could request this instance’s MusicKit `Song`, but that requires `await`ing.
		guard songID == MPMusicPlayerController._system?.nowPlayingItem?.songID else { return .notPlaying }
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	private enum Status { case notPlaying, paused, playing }
}

// MARK: - Multipurpose

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
