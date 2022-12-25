//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer
import SwiftUI
import OSLog

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class CoverArtCell: UITableViewCell {
	var albumRepresentative: SongMetadatum? = nil
	
	func configureArtwork(
		maxHeight: CGFloat
	) {
		os_signpost(.begin, log: .songsView, name: "Configure cover art")
		contentConfiguration = UIHostingConfiguration {
			CoverArtView(
				albumRepresentative: albumRepresentative,
				maxHeight: maxHeight)
			.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
				viewDimensions[.leading]
			}
			.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
				viewDimensions[.trailing]
			}
		}
		.margins(.all, .zero)
		os_signpost(.end, log: .songsView, name: "Configure cover art")
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
	private static let usesSwiftUI__ = 10 == 1
	
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	static let usesUIKitAccessibility__ = !usesSwiftUI__
	var rowContentAccessibilityLabel__: String? = nil
	
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
		
		if !Self.usesSwiftUI__ {
			accessibilityTraits.formUnion(.button)
		}
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
		
		let trackDisplay: String = {
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
		let songTitleDisplay: String = {
			return metadatum?.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		}()
		let artistDisplayOptional: String? = {
			let albumArtistOptional = representative?.albumArtistOnDisk
			if
				let songArtist = metadatum?.artistOnDisk,
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
					trackDisplay: trackDisplay,
					songTitleDisplay: songTitleDisplay,
					artistDisplayOptional: artistDisplayOptional,
					songID: song.persistentID)
			}
			
		} else {
			
			spacerNumberLabel.text = spacerTrackNumberText
			numberLabel.text = { () -> String in
				trackDisplay
			}()
			titleLabel.text = { () -> String in
				songTitleDisplay
			}()
			artistLabel.text = { () -> String? in
				artistDisplayOptional
			}()
			
			if artistLabel.text == nil {
				textStack.spacing = 0
			} else {
				textStack.spacing = 4
			}
			
		}
		
		rowContentAccessibilityLabel__ = [
			numberLabel.text,
			titleLabel.text,
			artistLabel.text,
		].compactedAndFormattedAsNarrowList()
		
		reflectPlayhead(
			containsPlayhead: song.containsPlayhead(),
			rowContentAccessibilityLabel__: rowContentAccessibilityLabel__)
		
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
		
		// Play next
		
		// Play song next
		let playSongNext =
		UIDeferredMenuElement.uncached({ useMenuElements in
			let action = UIAction(
				title: LRString.insertSong,
				image: UIImage(systemName: "text.line.first.and.arrowtriangle.forward")
			) { _ in
				if let player = TapeDeck.shared.player {
					player.playNext([mediaItem])
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
				}
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
				image: UIImage(systemName: "text.line.first.and.arrowtriangle.forward")
			) { _ in
				if let player = TapeDeck.shared.player {
					player.playNext(thisMediaItemAndBelow)
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurredTwice()
				}
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
				title: LRString.queueSong,
				image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				if let player = TapeDeck.shared.player {
					player.playLast([mediaItem])
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
				}
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
				image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")
			) { _ in
				if let player = TapeDeck.shared.player {
					player.playLast(thisMediaItemAndBelow)
					
					UIImpactFeedbackGenerator(style: .heavy).impactOccurredTwice()
				}
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
			menuElementGroups: [
				[
					playSongAndBelowNext,
					playSongNext,
				],
				[
					playSongAndBelowLast,
					playSongLast,
				],
			]
		)
	}
	
	private func freshenDotDotDotButton() {
		dotDotDotButton.isEnabled = !isEditing
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI__ {
		} else {
			separatorInset.left = 0
			+ contentView.frame.minX // Cell’s leading edge → content view’s leading edge
			+ textStack.frame.minX // Content view’s leading edge → text stack’s leading edge
			separatorInset.right = directionalLayoutMargins.trailing
		}
	}
}
extension SongCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
