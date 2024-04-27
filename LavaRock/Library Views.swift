// 2022-12-12

import SwiftUI
import MusicKit

// MARK: - Album list

struct AlbumRow: View {
	let album: Album
	let maxHeight: CGFloat
	var body: some View {
		VStack(spacing: 0) {
			Rectangle().frame(width: 42, height: 1 * pointsPerPixel).hidden()
			// TO DO: Redraw when artwork changes
			CoverArt(album: album, largerThanOrEqualToSizeInPoints: maxHeight)
				.frame(
					maxWidth: .infinity, // Horizontally centers narrow artwork
					maxHeight: maxHeight) // Prevents artwork from becoming taller than viewport
				.accessibilityLabel(album.titleFormatted())
				.accessibilitySortPriority(10)
		}
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([album.titleFormatted()])
	}
	@Environment(\.pixelLength) private var pointsPerPixel
}
private struct CoverArt: View {
	let album: Album
	let largerThanOrEqualToSizeInPoints: CGFloat
	var body: some View {
		ZStack {
			let uiImageOptional = album.representativeSongInfo()?.coverArt(atLeastInPoints: CGSize(width: largerThanOrEqualToSizeInPoints, height: largerThanOrEqualToSizeInPoints))
			if let uiImage = uiImageOptional {
				Image(uiImage: uiImage)
					.resizable() // Lets 1 image point differ from 1 screen point
					.scaledToFit() // Maintains aspect ratio
					.accessibilityIgnoresInvertColors()
			} else {
				ZStack {
					Color(uiColor: .secondarySystemBackground) // Close to what Apple Music uses
						.aspectRatio(1, contentMode: .fit)
					Image(systemName: "music.note")
						.foregroundStyle(.secondary)
						.font(.title)
				}
				.accessibilityLabel(LRString.albumArtwork)
				.accessibilityIgnoresInvertColors()
			}
			ZStack(alignment: .bottomLeading) {
				Rectangle().foregroundStyle(.regularMaterial)
				ScrollView {
					AlbumHeader(album: album)
				}.aspectRatio(1, contentMode: .fit)
			}
			.opacity(showingInfo ? 1 : .zero)
			.animation(.linear(duration: pow(.oneHalf, 4)), value: showingInfo)
		}
//		.onTapGesture {
//			showingInfo.toggle()
//			if showingInfo {
//				NotificationCenter.default.post(name: .LRShowAlbumDetail, object: album)
//			} else {
//				NotificationCenter.default.post(name: .LRHideAlbumDetail, object: nil)
//			}
//		}
	}
	@State private var showingInfo = false
}

// MARK: - Song list

struct AlbumHeader: View {
	let album: Album
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			AvatarPlayingImage().hidden()
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text(album.titleFormatted())
					.fontTitle2Bold()
					.alignmentGuide_separatorLeading()
				Text({ () -> String in
					guard
						let albumArtist = album.representativeSongInfo()?.albumArtistOnDisk,
						albumArtist != ""
					else { return LRString.unknownArtist }
					return albumArtist
				}())
				.foregroundStyle(.secondary)
				.fontCaption2Bold()
				Text(album.releaseDateEstimateFormatted())
					.foregroundStyle(.secondary)
					.font(.caption2)
			}.padding(.bottom, .eight * 1/4)
			Spacer().alignmentGuide_separatorTrailing()
		}.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
}

struct SongRow: View {
	let song: Song
	let album: Album
	@ObservedObject var tvcStatus: SongsTVCStatus
	var body: some View {
		let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
		let albumRepInfo = album.representativeSongInfo() // Can be `nil` too
		HStack(alignment: .firstTextBaseline) {
			HStack(alignment: .firstTextBaseline) {
				AvatarImage(song: song, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10) // Bigger is sooner
				VStack(alignment: .leading, spacing: .eight * 1/2) {
					Text(song.songInfo()?.titleOnDisk ?? LRString.emDash)
						.alignmentGuide_separatorLeading()
					let albumArtistOptional = albumRepInfo?.albumArtistOnDisk
					if let songArtist = info?.artistOnDisk, songArtist != albumArtistOptional {
						Text(songArtist)
							.foregroundStyle(.secondary)
							.fontFootnote()
					}
				}.padding(.bottom, .eight * 1/4)
				Spacer()
				Text({
					guard let info, let albumRepInfo else { return LRString.octothorpe }
					return albumRepInfo.shouldShowDiscNumber
					? info.discAndTrackFormatted()
					: info.trackFormatted()
				}())
					.foregroundStyle(.secondary)
					.monospacedDigit()
			}
			.accessibilityElement(children: .combine)
			.accessibilityAddTraits(.isButton)
			.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
			Menu { overflowMenuContent } label: { overflowMenuLabel }
				.disabled(tvcStatus.isEditing)
				.onTapGesture { signal_tappedMenu.toggle() }
				.alignmentGuide_separatorTrailing()
		}.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
	private var overflowMenuLabel: some View {
		Image(systemName: "ellipsis.circle.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.symbolRenderingMode(.hierarchical)
	}
	@ViewBuilder private var overflowMenuContent: some View {
		Button {
			Task { await song.play() }
		} label: { Label(LRString.play, systemImage: "play") }
		Divider()
		Button {
			Task { await song.playLast() }
		} label: { Label(LRString.playLast, systemImage: "text.line.last.and.arrowtriangle.forward") }
		
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		Button {
			Task { await song.playRestOfAlbumLast() }
		} label: {
			Label(LRString.playRestOfAlbumLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}.disabled((signal_tappedMenu && false) || song.isAtBottomOfAlbum()) // Hopefully the compiler never optimizes away the dependency on the SwiftUI state property
	}
	@State private var signal_tappedMenu = false // Value doesn’t actually matter
}

struct AvatarImage: View {
	let song: Song
	@ObservedObject var state: MusicPlayer.State
	@ObservedObject var queue: MusicPlayer.Queue
	@ObservedObject private var musicRepo: MusicRepo = .shared // In case the user added or deleted the current song. Currently, even if the view body never actually mentions this, merely including this property refreshes the view at the right times.
	var body: some View {
		ZStack(alignment: .leading) {
			AvatarPlayingImage().hidden()
			switch status {
				case .notPlaying: EmptyView()
				case .paused:
					Image(systemName: "speaker.fill")
						.fontBody_dynamicTypeSizeUpToXxxLarge()
						.imageScale(.small)
				case .playing:
					AvatarPlayingImage()
						.symbolRenderingMode(.hierarchical)
			}
		}
		.foregroundStyle(Color.accentColor)
		.accessibilityElement()
		.accessibilityLabel({ switch status {
			case .notPlaying: return ""
			case .paused: return LRString.paused
			case .playing: return LRString.nowPlaying
		}}())
	}
	private var status: Status {
#if targetEnvironment(simulator)
		guard song.objectID == Sim_Global.currentSong?.objectID else {
			return .notPlaying
		}
		return .playing
#else
		guard song.objectID == song.managedObjectContext?.songInPlayer()?.objectID else {
			return .notPlaying
		}
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	enum Status { case notPlaying, paused, playing }
}
struct AvatarPlayingImage: View {
	var body: some View {
		Image(systemName: "speaker.wave.2.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}
