//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer
import OSLog

final class CoverArtCell: UITableViewCell {
	@IBOutlet private var coverArtView: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		coverArtView.accessibilityIgnoresInvertColors = true
		accessibilityLabel = LRString.albumArtwork
		accessibilityUserInputLabels = nil // No Voice Control label
		accessibilityTraits.formUnion(.image)
	}
	
	func configure(with album: Album) {
		os_signpost(.begin, log: .songsView, name: "Set cover art")
		coverArtView.image = {
			os_signpost(.begin, log: .songsView, name: "Draw cover art")
			defer {
				os_signpost(.end, log: .songsView, name: "Draw cover art")
			}
			let widthAndHeightInPoints = coverArtView.bounds.width
			return album.representativeSongMetadatum()?.coverArt(sizeInPoints: CGSize(
				width: widthAndHeightInPoints,
				height: widthAndHeightInPoints))
		}()
		os_signpost(.end, log: .songsView, name: "Set cover art")
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AlbumTitleCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectionStyle = .none
	}
	
	func configureWith(
		albumTitle: String
	) {
		var content = UIListContentConfiguration.cell()
		content.text = albumTitle
		content.textProperties.font = {
			let font: UIFont = .preferredFont(forTextStyle: .largeTitle)
//			let font: UIFont = .preferredFont(forTextStyle: .title1)
//			let font: UIFont = .preferredFont(forTextStyle: .title2)
			let actualFont: UIFont = .systemFont(ofSize: font.pointSize, weight: .bold)
			
			// Close to what navigation bars use
//			let font: UIFont = .preferredFont(forTextStyle: .largeTitle)
//			let actualFont: UIFont = .systemFont(ofSize: font.pointSize, weight: .bold)
			
			return actualFont
		}()
		contentConfiguration = content
	}
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var mainLabel: UILabel!
	@IBOutlet private var secondaryLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityUserInputLabels = nil // No Voice Control label
	}
	
	func configure(with album: Album) {
		mainLabel.text = { () -> String in
			if let albumArtist = album.representativeAlbumArtistFormattedOptional() {
				return albumArtist
			} else {
				return Album.unknownAlbumArtistPlaceholder
			}
		}()
		secondaryLabel.text = album.releaseDateEstimateFormattedOptional()
		
		if secondaryLabel.text == nil {
			// We couldn’t determine the album’s release date.
			textStack.spacing = 0
		} else {
			textStack.spacing = UIStackView.spacingUseSystem
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading
		separatorInset.right = directionalLayoutMargins.trailing
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

final class SongCell: UITableViewCell {
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var bodyOfAccessibilityLabel: String? = nil
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var dotDotDotButton: ExpandedTargetButton!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		dotDotDotButton.maximumContentSizeCategory = .extraExtraExtraLarge
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		freshenDotDotDotButton()
	}
	
	func configureWith(
		song: Song,
		albumRepresentative representative: SongMetadatum?,
		spacerTrackNumberText: String?,
		songsTVC: Weak<SongsTVC>
	) {
		let metadatum = song.metadatum() // Can be `nil` if the user recently deleted the `SongMetadatum` from their library
		let songDisplayTitle: String = {
			metadatum?.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		}()
		
		titleLabel.text = { () -> String in
			songDisplayTitle
		}()
		artistLabel.text = {
			let albumArtist = representative?.albumArtistOnDisk // Can be `nil`
			if
				let songArtist = metadatum?.artistOnDisk,
				songArtist != albumArtist
			{
				return songArtist
			} else {
				return nil
			}
		}()
		spacerNumberLabel.text = spacerTrackNumberText
		numberLabel.text = { () -> String in
			let result: String? = {
				guard
					let representative = representative,
					let metadatum = metadatum
				else {
					// Metadata not available
					return nil
				}
				if representative.shouldShowDiscNumber {
					// Disc and track number
					return metadatum.discAndTrackNumberFormatted()
				} else {
					// Track number only, which might be blank
					return metadatum.trackNumberFormattedOptional()
				}
			}()
			return result ?? "‒" // Figure dash
		}()
		
		if artistLabel.text == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
		
		bodyOfAccessibilityLabel = [
			numberLabel.text,
			titleLabel.text,
			artistLabel.text,
		].compactedAndFormattedAsNarrowList()
		
		reflectPlayhead(
			containsPlayhead: song.containsPlayhead(),
			bodyOfAccessibilityLabel: bodyOfAccessibilityLabel)
		
		freshenDotDotDotButton()
		
		// For Voice Control, only include the song title.
		// Never include the “unknown title” placeholder, if it’s a dash.
		accessibilityUserInputLabels = [
			metadatum?.titleOnDisk,
		].compacted()
		
		// Set menu, and require creating that menu
		let menu: UIMenu?
		defer {
			dotDotDotButton.menu = menu
		}
		
		guard let mediaItem = song.mpMediaItem() else {
			menu = nil
			return
		}
		
		// Create menu elements
		
		// For actions that start playback:
		// `MPMusicPlayerController.play` might need to fade out other currently-playing audio.
		// That blocks the main thread, so wait until the menu dismisses itself before calling it; for example, by doing the following asynchronously.
		// The UI will still freeze, but at least the menu won’t be onscreen while it happens.
		
		// Repeat
		
		// Repeat song
		let repeatSong = UIAction(
			title: LRString.repeat_verb,
			image: UIImage(systemName: "repeat.1")
		) { _ in
			Task {
//				player.repeatMode = .one // Tries to reflect the repeat mode sooner, because `MPMusicPlayerController.play` is slow. But doesn’t work consistently.
				TapeDeck.shared.player?.playNow(
					[mediaItem],
					new_repeat_mode: .one,
					disable_shuffle: false)
			}
		}
		
		// Repeat song and below
		let repeatSongAndBelow =
		UIDeferredMenuElement.uncached({ useMenuElements in
			// Runs each time the button presents the menu
			
			let menuElements: [UIMenuElement]
			defer {
				useMenuElements(menuElements)
			}
			
			let thisMediaItemAndBelow = songsTVC.referencee?.mediaItemsInFirstGroup(startingAt: mediaItem) ?? []
			let action = UIAction(
				title: LRString.repeatRestOfAlbum,
				image: UIImage(systemName: "repeat")
			) { _ in
				// Runs when the user activates the menu item
				TapeDeck.shared.player?.playNow(
					thisMediaItemAndBelow,
					new_repeat_mode: .all,
					disable_shuffle: false)
			}
			// Disable if appropriate
			// This must be inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
			action.attributes = (
				thisMediaItemAndBelow.count >= 2
				? []
				: .disabled
			)
			
			menuElements = [action]
		})
		
		// Play next
		
		// Play song next
		let playSongNext =
		UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.insert,
				image: UIImage(systemName: "text.insert")
			) { _ in
				TapeDeck.shared.player?.playNext([mediaItem])
			}
			action.attributes = (
				Reel.shouldEnablePlayLast()
				? []
				: .disabled
			)
			useMenuElements([action])
		})
		
		// Play song and below next
		let playSongAndBelowNext =
		UIDeferredMenuElement.uncached({ useMenuElements in
			let menuElements: [UIMenuElement]
			defer {
				useMenuElements(menuElements)
			}
			
			let thisMediaItemAndBelow = songsTVC.referencee?.mediaItemsInFirstGroup(startingAt: mediaItem) ?? []
			let action = UIAction(
				title: LRString.insertRestOfAlbum,
				image: UIImage(systemName: "text.insert")
			) { _ in
				TapeDeck.shared.player?.playNext(thisMediaItemAndBelow)
			}
			action.attributes = (
				Reel.shouldEnablePlayLast() && thisMediaItemAndBelow.count >= 2
				? []
				: .disabled
			)
			
			menuElements = [action]
		})
		
		// Play last
		
		// Play song last
		let playSongLast =
		UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.queue_verb,
				image: UIImage(systemName: "text.append")
			) { _ in
				TapeDeck.shared.player?.playLast([mediaItem])
			}
			useMenuElements([action])
		})
		
		// Play song and below last
		let playSongAndBelowLast =
		UIDeferredMenuElement.uncached({ useMenuElements in
			let menuElements: [UIMenuElement]
			defer {
				useMenuElements(menuElements)
			}
			
			let thisMediaItemAndBelow = songsTVC.referencee?.mediaItemsInFirstGroup(startingAt: mediaItem) ?? []
			let action = UIAction(
				title: LRString.queueRestOfAlbum,
				image: UIImage(systemName: "text.append")
			) { _ in
				TapeDeck.shared.player?.playLast(thisMediaItemAndBelow)
			}
			action.attributes = (
				thisMediaItemAndBelow.count >= 2
				? []
				: .disabled
			)
			
			menuElements = [action]
		})
		
		// —
		
		// Create menu
		menu = UIMenu(
			title: "",
			presentsUpward: false,
			groupedElements: [
				[
					repeatSong,
					repeatSongAndBelow,
				],
				[
					playSongNext,
					playSongAndBelowNext,
				],
				[
					playSongLast,
					playSongAndBelowLast,
				],
			]
		)
	}
	
	private func freshenDotDotDotButton() {
		dotDotDotButton.isEnabled = !isEditing
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = 0
		+ contentView.frame.minX // Cell’s leading edge → content view’s leading edge
		+ textStack.frame.minX // Content view’s leading edge → text stack’s leading edge
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension SongCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
