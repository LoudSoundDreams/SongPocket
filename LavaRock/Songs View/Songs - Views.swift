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
				Text(album.albumArtistFormatted()) // “The Beatles”
					.foregroundStyle(.secondary)
					.fontCaption2_bold()
				Text(album.titleFormatted()) // “Rubber Soul”
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
			// Text
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * 5/4
			) {
				TrackNumberLabel(text: trackDisplay, spacerText: trackNumberSpacer)
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
				.padding(.bottom, .eight * 1/4)
				.alignmentGuide_separatorLeading()
			}
			
			Spacer()
			
			AvatarImage(
				libraryItem: song,
				state: SystemMusicPlayer.sharedIfAuthorized!.state, // !
				queue: SystemMusicPlayer.sharedIfAuthorized!.queue // !
			).accessibilitySortPriority(10)
			Menu {
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
			} label: {
				ZStack {
					Circle()
						.frame(width: 44, height: 44)
						.hidden()
					Image(systemName: "ellipsis")
						.tint(Color.primary)
						.fontBody_dynamicTypeSizeUpToXxxLarge()
				}
			}
			.disabled(listStatus.editing)
		}
		.padding(.horizontal)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
		
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
			return result ?? "‒" // Figure dash
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
					.alignmentGuide_separatorTrailing()
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
				musicItemID: MusicItemID(String(song.persistentID)),
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
		musicItemID: MusicItemID,
		songsTVC: Weak<SongsTVC>,
		songPersistentIDForBottomOfAlbum: Int64
	) -> UIMenu? {
		guard
			let player = SystemMusicPlayer.sharedIfAuthorized,
			let tvc = songsTVC.referencee
		else { return nil }
		
		let play = UIAction(
			title: LRString.play, image: UIImage(systemName: "play")
		) { _ in
			// For actions that start playback, `MPMusicPlayerController.play` might need to fade out other currently-playing audio.
			// That blocks the main thread, so wait until the menu dismisses itself before calling it; for example, by doing the following asynchronously.
			// The UI will still freeze, but at least the menu won’t be onscreen while it happens.
			Task {
				guard let rowMusicItem = await MusicLibraryRequest.song(with: musicItemID) else { return }
				
				player.queue = SystemMusicPlayer.Queue(for: [rowMusicItem])
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
					guard let rowMusicItem = await MusicLibraryRequest.song(with: musicItemID) else { return }
					
					try await player.queue.insert([rowMusicItem], position: .tail)
					
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
					guard let rowItem = await MusicLibraryRequest.song(with: musicItemID) else { return }
					
					let musicItems: [MusicKit.Song] = await {
						var allItems: [MusicKit.Song] = []
						let ids = restOfSongs.map { MusicItemID(String($0.persistentID)) }
						for id in ids {
							guard let musicItem = await MusicLibraryRequest.song(with: id) else { continue }
							allItems.append(musicItem)
						}
						let result = allItems.drop(while: { $0.id != rowItem.id })
						return Array(result)
					}()
					// As of iOS 15.4, when using `MPMusicPlayerController.systemMusicPlayer` and the queue is empty, this does nothing, but I can’t find a workaround.
					try await player.queue.insert(musicItems, position: .tail)
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurredTwice()
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
