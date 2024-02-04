//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import SwiftUI
import UIKit
import MusicKit

// MARK: - SwiftUI

struct AlbumHeader: View {
	let album: Album
	let trackNumberSpacer: String
	
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			TrackNumberLabel(text: trackNumberSpacer, spacerText: trackNumberSpacer)
				.hidden()
			
			VStack(
				alignment: .leading,
				spacing: .eight * 1/2
			) {
				Text({ () -> String in
					let representative = album.representativeSongInfo()
					guard
						let albumArtist = representative?.albumArtistOnDisk,
						albumArtist != ""
					else {
						return LRString.unknownArtist
					}
					return albumArtist
				}())
				.foregroundStyle(.secondary)
				.fontCaption2_bold()
				Text(album.titleFormatted())
					.fontTitle2_bold()
			}
			.alignmentGuide_separatorLeading()
			
			Spacer()
		}
		.alignmentGuide_separatorTrailing()
	}
}

struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let trackNumberSpacer: String
	let artist_if_different_from_album_artist: String?
	@ObservedObject var listStatus: SongsListStatus
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			HStack(alignment: .firstTextBaseline) {
				ZStack(alignment: .leading) {
					overflowMenuLabel().hidden()
					AvatarImage(
						libraryItem: song,
						state: SystemMusicPlayer._shared!.state,
						queue: SystemMusicPlayer._shared!.queue
					).accessibilitySortPriority(10)
				}
				TrackNumberLabel(text: trackDisplay, spacerText: "")
			}
			
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * 5/4
			) {
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2
				) {
					Text(song.songInfo()?.titleOnDisk ?? LRString.emDash)
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.foregroundStyle(.secondary)
							.fontFootnote()
					}
				}
				.frame(maxWidth: .infinity)
				.padding(.bottom, .eight * 1/4)
				.alignmentGuide_separatorLeading()
			}
			
			HStack(alignment: .firstTextBaseline) {
				ZStack(alignment: .trailing) {
					AvatarPlayingImage().hidden()
					Menu {
						overflowMenuContent()
					} label: {
						overflowMenuLabel()
					}
					.disabled(listStatus.editing)
				}
			}
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.padding(.horizontal)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
	}
	private func overflowMenuLabel() -> some View {
		Image(systemName: "ellipsis.circle")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
	}
	@ViewBuilder private func overflowMenuContent() -> some View {
		Button {
		} label: {
			Label(LRString.play, systemImage: "play")
		}
		
		Divider()
		
		Button {
		} label: {
			Label(LRString.playLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}
		Button {
		} label: {
			Label(LRString.playRestOfAlbumLast, systemImage: "text.line.last.and.arrowtriangle.forward")
		}
	}
}
struct TrackNumberLabel: View {
	let text: String
	let spacerText: String
	
	var body: some View {
		ZStack(alignment: .trailing) {
			Text(spacerText).hidden()
			Text(text).foregroundStyle(.secondary)
		}
		.monospacedDigit()
	}
}

// MARK: - UIKit

final class SongCell: UITableViewCell {
	static let usesSwiftUI = 10 == 1
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var overflowButton: ExpandedTargetButton!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if Self.usesSwiftUI { return }
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(
			ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
			weight: .regular)
		numberLabel.font = spacerNumberLabel.font
		
		overflowButton.maximumContentSizeCategory = .extraExtraExtraLarge
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if Self.usesSwiftUI { return }
		
		freshenOverflowButton()
	}
	
	func configureWith(
		song: Song,
		albumRepresentative representative: SongInfo?,
		spacerTrackNumberText: String,
		songsTVC: Weak<SongsTVC>,
		forBottomOfAlbum: Bool
	) {
		let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
		
		let trackDisplay: String = {
			let result: String? = {
				guard let representative, let info else {
					// `SongInfo` not available
					return nil
				}
				if representative.shouldShowDiscNumber {
					// Disc and track number
					return info.discAndTrackNumberFormatted()
				} else {
					// Track number only, which might be blank
					return info.trackNumberFormattedOptional()
				}
			}()
			return result ?? "#"
		}()
		let artistDisplayOptional: String? = {
			let albumArtistOptional = representative?.albumArtistOnDisk
			if
				let songArtist = info?.artistOnDisk,
				songArtist != albumArtistOptional
			{
				return songArtist
			} else {
				return nil
			}
		}()
		
		if Self.usesSwiftUI {
			contentConfiguration = UIHostingConfiguration {
				if let referencee = songsTVC.referencee {
					SongRow(
						song: song,
						trackDisplay: trackDisplay,
						trackNumberSpacer: spacerTrackNumberText,
						artist_if_different_from_album_artist: artistDisplayOptional,
						listStatus: referencee.status
					)
				}
			}
			.margins(.all, .zero)
		} else {
			spacerNumberLabel.text = spacerTrackNumberText
			numberLabel.text = trackDisplay
			titleLabel.text = { () -> String in
				info?.titleOnDisk ?? LRString.emDash
			}()
			artistLabel.text = artistDisplayOptional
			
			if artistLabel.text == nil {
				textStack.spacing = 0
			} else {
				textStack.spacing = .eight * 1/2
			}
			
			rowContentAccessibilityLabel__ = [
				numberLabel.text,
				titleLabel.text,
				artistLabel.text,
			].compactedAndFormattedAsNarrowList()
			reflectAvatarStatus(song.avatarStatus__())
			
			freshenOverflowButton()
			overflowButton.menu = newOverflowMenu(
				song: song,
				songsTVC: songsTVC,
				songPersistentIDForBottomOfAlbum: song.persistentID)
			
			accessibilityUserInputLabels = [info?.titleOnDisk].compacted()
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX // Cell’s leading edge → content view’s leading edge
		+ textStack.frame.minX // Content view’s leading edge → text stack’s leading edge
		separatorInset.right = directionalLayoutMargins.trailing
	}
	
	private func freshenOverflowButton() {
		overflowButton.isEnabled = !isEditing
	}
	private func newOverflowMenu(
		song: Song,
		songsTVC: Weak<SongsTVC>,
		songPersistentIDForBottomOfAlbum: Int64
	) -> UIMenu? {
		guard
			let player = SystemMusicPlayer._shared,
			let tvc = songsTVC.referencee
		else { return nil }
		
		let play = UIAction(
			title: LRString.play, image: UIImage(systemName: "play")
		) { _ in
			// For actions that start playback, `MPMusicPlayerController.play` might need to fade out other currently-playing audio.
			// That blocks the main thread, so wait until the menu dismisses itself before calling it; for example, by doing the following asynchronously.
			// The UI will still freeze, but at least the menu won’t be onscreen while it happens.
			Task {
				guard let musicItem = await song.musicKitSong() else { return }
				
				player.queue = SystemMusicPlayer.Queue(for: [musicItem])
				try? await player.play()
				
				player.state.repeatMode = MusicPlayer.RepeatMode.none
				player.state.shuffleMode = .off
			}
		}
		
		let playLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.playLast, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				Task {
					guard let musicItem = await song.musicKitSong() else { return }
					
					try await player.queue.insert([musicItem], position: .tail)
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
				}
			}
			useMenuElements([action])
		})
		
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		let playRestOfAlbumLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let restOfSongs = tvc.viewModel.libraryGroup().items.map { $0 as! Song }
			let action = UIAction(
				title: LRString.playRestOfAlbumLast, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				Task {
					guard let rowItem = await song.musicKitSong() else { return }
					
					let toAppend: [MusicKit.Song] = await {
						var musicItems: [MusicKit.Song] = []
						for song in restOfSongs {
							guard let musicItem = await song.musicKitSong() else { continue }
							musicItems.append(musicItem)
						}
						let result = musicItems.drop(while: { $0.id != rowItem.id })
						return Array(result)
					}()
					// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
					try await player.queue.insert(toAppend, position: .tail)
					
					let impactor = UIImpactFeedbackGenerator(style: .heavy)
					impactor.impactOccurred()
					try await Task.sleep(nanoseconds: 0_200_000_000)
					
					impactor.impactOccurred()
				}
			}
			if songPersistentIDForBottomOfAlbum == restOfSongs.last?.persistentID {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		})
		
		return UIMenu(
			children: [
				UIMenu(options: .displayInline, children: [play]),
				UIMenu(options: .displayInline, children: [playLast, playRestOfAlbumLast]),
			]
		)
	}
}
final class ExpandedTargetButton: UIButton {
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let tappableWidth = max(bounds.width, 44)
		let tappableHeight = max(bounds.height, 55)
		let tappableRect = CGRect(
			x: bounds.midX - tappableWidth/2,
			y: bounds.midY - tappableHeight/2,
			width: tappableWidth,
			height: tappableHeight)
		return tappableRect.contains(point)
	}
}
