//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import SwiftUI
import UIKit
import MediaPlayer

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
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	var body: some View {
		
		HStack(alignment: .firstTextBaseline) {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * 5/4 // Between track number and title
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
			
			AvatarImage(libraryItem: song).accessibilitySortPriority(10)
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
				Image(systemName: "ellipsis")
					.tint(Color.primary)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
			}
			.disabled(listStatus.editing)
		}
		.padding(.top, .eight * -1/4)
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
		
		if Self.usesSwiftUI__ { return }
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		overflowButton.maximumContentSizeCategory = .extraExtraExtraLarge
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if Self.usesSwiftUI__ { return }
		
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
		
		if Self.usesSwiftUI__ {
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
			reflectStatus__(song.avatarStatus__())
			
			freshenOverflowButton()
			overflowButton.menu = {
				guard let mediaItem = song.mpMediaItem() else {
					return nil
				}
				return newOverflowMenu(mediaItem: mediaItem, songsTVC: songsTVC)
			}()
			
			accessibilityUserInputLabels = [info?.titleOnDisk].compacted()
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI__ { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX // Cell’s leading edge → content view’s leading edge
		+ textStack.frame.minX // Content view’s leading edge → text stack’s leading edge
		separatorInset.right = directionalLayoutMargins.trailing
	}
	
	private func freshenOverflowButton() {
		overflowButton.isEnabled = !isEditing
	}
	private func newOverflowMenu(
		mediaItem: MPMediaItem,
		songsTVC: Weak<SongsTVC>
	) -> UIMenu {
		// For actions that start playback:
		// `MPMusicPlayerController.play` might need to fade out other currently-playing audio.
		// That blocks the main thread, so wait until the menu dismisses itself before calling it; for example, by doing the following asynchronously.
		// The UI will still freeze, but at least the menu won’t be onscreen while it happens.
		let player = TapeDeck.shared.player
		
		let play = UIAction(
			title: LRString.play,
			image: UIImage(systemName: "play")
		) { _ in
			player?.playNow([mediaItem], numberToSkip: 0)
		}
		
		// Disable “prepend” intelligently: when “append” would do the same thing.
		// Specifically, only enable “prepend” if there’s at least 1 song queued after the current one.
		// Err toward leaving “prepend” enabled.
		
		// `MPMusicPlayerController` doesn’t expose how many songs are up next.
		// So, in order to intelligently disable prepending, we need to…
		// 1. Keep track of that number ourselves, and…
		// 2. Always know when that number changes.
		// We can't do that with `systemMusicPlayer`.
		
		let playLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.playLast,
				image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				player?.playLast([mediaItem])
			}
			useMenuElements([action])
		})
		
		// Disable multiple-song commands intelligently: when a single-song command would do the same thing.
		let playRestOfAlbumLast = UIDeferredMenuElement.uncached({ useMenuElements in
			let mediaItems = songsTVC.referencee?.mediaItems(startingAt: mediaItem) ?? []
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
		
		let submenus: [UIMenu] = [
			UIMenu(options: .displayInline, children: [
				play,
			]),
			UIMenu(options: .displayInline, children: [
				playLast,
				playRestOfAlbumLast,
			]),
		]
		return UIMenu(children: submenus)
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
