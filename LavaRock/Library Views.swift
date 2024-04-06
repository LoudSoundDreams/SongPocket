// 2022-12-12

import SwiftUI
import MusicKit

struct Chevron: View {
	var body: some View {
		// Similar to what Apple Music uses for search results
		Image(systemName: "chevron.forward")
			.foregroundStyle(.secondary)
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}

struct AvatarImage: View {
	let libraryItem: LibraryItem
	@ObservedObject var state: MusicPlayer.State
	@ObservedObject var queue: MusicPlayer.Queue
	
	private var status: Status {
		guard libraryItem.containsPlayhead() else { return .notPlaying }
#if targetEnvironment(simulator)
		return .playing
#else
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	enum Status {
		case notPlaying, paused, playing
	}
	@ObservedObject private var musicRepo: MusicRepo = .shared // In case the user added or deleted the current song. Currently, even if the view body never actually mentions this, merely including this property refreshes the view at the right times.
	
	var body: some View {
		ZStack(alignment: .leading) {
			AvatarPlayingImage().hidden()
			foregroundView
		}
		.accessibilityElement()
		.accessibilityLabel({
			switch status {
				case .notPlaying: return ""
				case .paused: return LRString.paused
				case .playing: return LRString.nowPlaying
			}
		}())
	}
	@ViewBuilder private var foregroundView: some View {
		switch status {
			case .notPlaying: EmptyView()
			case .paused:
				Image(systemName: "speaker.fill")
					.foregroundStyle(Color.accentColor)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
					.imageScale(.small)
			case .playing:
				AvatarPlayingImage()
					.foregroundStyle(Color.accentColor)
					.symbolRenderingMode(.hierarchical)
		}
	}
}
struct AvatarPlayingImage: View {
	var body: some View {
		Image(systemName: "speaker.wave.2.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}

// MARK: - Album list

struct AlbumRow: View {
	let album: Album
	let maxHeight: CGFloat
	
	@Environment(\.pixelLength) private var pointsPerPixel
	private static let borderWidthInPixels: CGFloat = 2
	var body: some View {
		VStack(spacing: 0) {
			Rectangle().frame(height: 1/2 * Self.borderWidthInPixels * pointsPerPixel).hidden()
			// TO DO: Redraw when artwork changes
			CoverArt(
				albumRepresentative: album.representativeSongInfo(),
				largerThanOrEqualToSizeInPoints: maxHeight)
			.background( // Use `border` instead?
				Rectangle()
					.stroke(
						Color(uiColor: .separator), // As of iOS 16.6, only this is correct in dark mode, not `opaqueSeparator`.
						lineWidth: {
							// Add a grey border exactly 1 pixel wide, like list separators.
							// Draw outside the artwork; don’t overlap it.
							// The artwork itself will obscure half the stroke width.
							// SwiftUI interprets our return value in points, not pixels.
							return Self.borderWidthInPixels * pointsPerPixel
						}()
					)
			)
			.frame(
				maxWidth: .infinity, // Horizontally centers narrow artwork
				maxHeight: maxHeight) // Prevents artwork from becoming taller than viewport
			.accessibilityLabel(album.titleFormatted())
			.accessibilitySortPriority(10)
			
			AlbumLabel(album: album)
				.padding(.top, .eight * 3/2)
				.padding(.horizontal)
				.padding(.bottom, .eight * 4)
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([album.titleFormatted()])
	}
}
private struct CoverArt: View {
	let albumRepresentative: (any SongInfo)?
	let largerThanOrEqualToSizeInPoints: CGFloat
	
	var body: some View {
		let uiImageOptional = albumRepresentative?.coverArt(atLeastInPoints: CGSize(
			width: largerThanOrEqualToSizeInPoints,
			height: largerThanOrEqualToSizeInPoints))
		if let uiImage = uiImageOptional {
			Image(uiImage: uiImage)
				.resizable() // Lets 1 image point differ from 1 screen point
				.scaledToFit() // Maintains aspect ratio
				.accessibilityIgnoresInvertColors()
		} else {
			ZStack {
				Color(uiColor: .secondarySystemBackground) // Close to what Apple Music uses
					.aspectRatio(1, contentMode: .fit)
				Image(systemName: "opticaldisc")
					.foregroundStyle(.secondary)
					.font(.system(size: .eight * 4))
			}
			.accessibilityLabel(LRString.albumArtwork)
			.accessibilityIgnoresInvertColors()
		}
	}
}
private struct AlbumLabel: View {
	let album: Album
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			ZStack(alignment: .leading) {
				Chevron().hidden()
				AvatarImage(libraryItem: album, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10) // Bigger is sooner
			}
			Text(album.releaseDateEstimateFormatted())
				.foregroundStyle(.secondary)
				.fontFootnote()
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
			ZStack(alignment: .trailing) {
				AvatarPlayingImage().hidden()
				Chevron()
			}
		}
		.accessibilityElement(children: .combine)
	}
}

// MARK: - Song list

struct AlbumHeader: View {
	let album: Album
	
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			AvatarPlayingImage().hidden()
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text({ () -> String in
					guard
						let representative = album.representativeSongInfo(),
						let albumArtist = representative.albumArtistOnDisk,
						albumArtist != ""
					else { return LRString.unknownArtist }
					return albumArtist
				}())
				.foregroundStyle(.secondary)
				.fontCaption2_bold()
				Text(album.titleFormatted())
					.fontTitle2_bold()
					.alignmentGuide_separatorLeading()
			}
			Spacer().alignmentGuide_separatorTrailing()
		}
		.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
}

struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let artist_if_different_from_album_artist: String?
	@ObservedObject var listStatus: SongsListStatus
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			HStack(alignment: .firstTextBaseline) {
				AvatarImage(libraryItem: song, state: SystemMusicPlayer._shared!.state, queue: SystemMusicPlayer._shared!.queue).accessibilitySortPriority(10)
				VStack(alignment: .leading, spacing: .eight * 1/2) {
					Text(song.songInfo()?.titleOnDisk ?? LRString.emDash)
						.alignmentGuide_separatorLeading()
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.foregroundStyle(.secondary)
							.fontFootnote()
					}
				}
				.padding(.bottom, .eight * 1/4)
				Spacer()
				Text(trackDisplay)
					.foregroundStyle(.secondary)
					.monospacedDigit()
			}
			.accessibilityElement(children: .combine)
			.accessibilityAddTraits(.isButton)
			.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
			Menu { overflowMenuContent() } label: { overflowMenuLabel() }
				.disabled(listStatus.editing)
				.onTapGesture { signal_tappedMenu.toggle() }
				.alignmentGuide_separatorTrailing()
		}
		.padding(.horizontal).padding(.vertical, .eight * 3/2)
	}
	private func overflowMenuLabel() -> some View {
		Image(systemName: "ellipsis.circle.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.symbolRenderingMode(.hierarchical)
	}
	@ViewBuilder private func overflowMenuContent() -> some View {
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
		}
		.disabled((signal_tappedMenu && false) || song.isAtBottomOfAlbum()) // Hopefully the compiler never optimizes away the dependency on the SwiftUI state property
	}
	@State private var signal_tappedMenu = false // Value doesn’t actually matter
}
