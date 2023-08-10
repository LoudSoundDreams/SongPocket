//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import SwiftUI
import MediaPlayer

// MARK: - Album info

struct AlbumInfoRow: View {
	let albumTitle: String
	let albumArtist: String
	let releaseDateStringOptional: String? // `nil` hides line
	
	var body: some View {
		HStack {
			VStack(
				alignment: .leading,
				spacing: .eight * 5/8
			) {
				// “Rubber Soul”
				Text(albumTitle)
					.font(.title2).bold() // As of iOS 16.6, Apple Music uses this for “Recently Added”.
				
				// “The Beatles”
				Text(albumArtist)
					.font(.footnote)
					.bold()
					.foregroundStyle(.secondary)
				
				if let releaseDate = releaseDateStringOptional {
					// “Dec 3, 1965”
					Text(releaseDate)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
		}
		.padding(.bottom, .eight * 5/8)
	}
}

// MARK: - Song

struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let song_title: String?
	let artist_if_different_from_album_artist: String?
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	var body: some View {
		
		HStack {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * (1 + 1/2) // 12
			) {
				Text(trackDisplay)
					.monospacedDigit()
					.foregroundStyle(.secondary)
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2 // 4
				) {
					Text(song_title ?? SongInfoPlaceholder.unknownTitle)
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.font(.caption)
							.foregroundStyle(.secondary)
							.padding(.bottom, .eight * 1/4) // 2
					}
				}
				.alignmentGuide_separatorLeading()
			}
			
			Spacer()
			
			AvatarImage(libraryItem: song)
				.accessibilitySortPriority(10)
			
			Button {
			} label: {
				Image(systemName: "ellipsis")
					.font(.body)
					.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
					.foregroundStyle(.primary)
			}
		}
		.padding(.top, .eight * -1/4) // -2
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels(
			[
				song_title, // Excludes the “unknown title” placeholder, which is currently a dash.
			].compacted()
		)
		
	}
}

final class ExpandedTargetButton: UIButton {
	override func point(
		inside point: CGPoint,
		with event: UIEvent?
	) -> Bool {
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
private extension UIFont {
	static func monospacedDigitSystemFont(
		forTextStyle style: TextStyle
	) -> UIFont {
		return .monospacedDigitSystemFont(
			ofSize: UIFont.preferredFont(forTextStyle: style).pointSize,
			weight: .regular)
	}
}
extension SongsTVC {
	// Time complexity: O(n), where “n” is the number of media items in the group.
	fileprivate func mediaItemsInFirstGroup(
		startingAt startingMediaItem: MPMediaItem
	) -> [MPMediaItem] {
		let result = mediaItems().drop(while: { mediaItem in
			mediaItem.persistentID != startingMediaItem.persistentID
		})
		return Array(result)
	}
}
final class SongCell: UITableViewCell {
	static let usesSwiftUI__ = 10 == 1
	
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
		
		backgroundColor = .clear
		
		if Self.usesSwiftUI__ { return }
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		overflowButton.maximumContentSizeCategory = .extraExtraExtraLarge
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		freshenOverflowButton()
	}
	
	func configureWith(
		song: Song,
		albumRepresentative representative: SongInfo?,
		spacerTrackNumberText: String,
		songsTVC: Weak<SongsTVC>
	) {
		let info = song.songInfo() // Can be `nil` if the user recently deleted the `SongInfo` from their library
		
		let trackDisplay: String = {
			let result: String? = {
				guard
					let representative,
					let info
				else {
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
		let song_title: String? = info?.titleOnDisk
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
		
		if Self.usesSwiftUI__ {
			contentConfiguration = UIHostingConfiguration {
				SongRow(
					song: song,
					trackDisplay: trackDisplay,
					song_title: song_title,
					artist_if_different_from_album_artist: artistDisplayOptional
				)
				.alignmentGuide_separatorTrailing()
			}
		} else {
			spacerNumberLabel.text = spacerTrackNumberText
			numberLabel.text = trackDisplay
			titleLabel.text = { () -> String in
				song_title ?? SongInfoPlaceholder.unknownTitle
			}()
			artistLabel.text = artistDisplayOptional
			
			if artistLabel.text == nil {
				textStack.spacing = 0
			} else {
				textStack.spacing = 4
			}
			
			rowContentAccessibilityLabel__ = [
				numberLabel.text,
				titleLabel.text,
				artistLabel.text,
			].compactedAndFormattedAsNarrowList()
			indicateAvatarStatus__(
				song.avatarStatus__()
			)
			
			freshenOverflowButton()
			
			accessibilityUserInputLabels = [
				song_title, // Excludes the “unknown title” placeholder, which is currently a dash.
			].compacted()
		}
		
		// Set menu, and require creating that menu
		let menu: UIMenu?
		defer {
			overflowButton.menu = menu
		}
		
		guard let mediaItem = song.mpMediaItem() else {
			menu = nil
			return
		}
		
		// For actions that start playback:
		// `MPMusicPlayerController.play` might need to fade out other currently-playing audio.
		// That blocks the main thread, so wait until the menu dismisses itself before calling it; for example, by doing the following asynchronously.
		// The UI will still freeze, but at least the menu won’t be onscreen while it happens.
		let player = TapeDeck.shared.player
		
		// Create menu elements
		
		let play = UIAction(
			title: LRString.play,
			image: UIImage(systemName: "play")
		) { _ in
			player?.playNow([mediaItem], skipping: 0)
		}
		
		// Disable “prepend” intelligently: when “append” would do the same thing.
		// Specifically, only enable “prepend” if there’s at least 1 song queued after the current one.
		// Err toward leaving “prepend” enabled.
		
		// `MPMusicPlayerController` doesn’t expose how many songs are up next.
		// So, in order to intelligently disable prepending, we need to…
		// 1. Keep track of that number ourselves, and…
		// 2. Always know when that number changes.
		// We can't do that with `systemMusicPlayer`.
		
		let playNext = UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.playNext,
				image: UIImage(systemName: "text.line.first.and.arrowtriangle.forward")
			) { _ in
				player?.playNext([mediaItem])
			}
			useMenuElements([action])
		})
		
		let playLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.playLast,
				image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				player?.playLast([mediaItem])
			}
			useMenuElements([action])
		})
		
		// —
		
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		
		let playToBottomNext = UIDeferredMenuElement.uncached({ useMenuElements in
			let mediaItems = songsTVC.referencee?.mediaItemsInFirstGroup(startingAt: mediaItem) ?? []
			let action = UIAction(
				title: LRString.playRestOfAlbumNext,
				image: UIImage(systemName: "text.line.first.and.arrowtriangle.forward")
			) { _ in
				player?.playNext(mediaItems)
			}
			if mediaItems.count <= 1 {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		})
		
		let playToBottomLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let mediaItems = songsTVC.referencee?.mediaItemsInFirstGroup(startingAt: mediaItem) ?? []
			let action = UIAction(
				title: LRString.playRestOfAlbumLast,
				image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				player?.playLast(mediaItems)
			}
			if mediaItems.count <= 1 {
				action.attributes.formUnion(.disabled)
			}
			useMenuElements([action])
		})
		
		// Create menu
		let submenus: [UIMenu] = [
			UIMenu(
				options: .displayInline,
				children: [
					play,
					playNext,
					playLast,
				]
			),
			UIMenu(
				options: .displayInline,
				children: [
					playToBottomNext,
					playToBottomLast,
				]
			),
		]
		menu = UIMenu(children: submenus)
	}
	
	private func freshenOverflowButton() {
		overflowButton.isEnabled = !isEditing
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI__ { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX // Cell’s leading edge → content view’s leading edge
		+ textStack.frame.minX // Content view’s leading edge → text stack’s leading edge
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
