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
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		coverArtView.accessibilityIgnoresInvertColors = true
		accessibilityLabel = LocalizedString.albumArtwork
		accessibilityUserInputLabels = nil // No Voice Control label
		accessibilityTraits.formUnion(.image)
	}
	
	final func configure(with album: Album) {
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

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var mainLabel: UILabel!
	@IBOutlet private var secondaryLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityUserInputLabels = nil // No Voice Control label
	}
	
	final func configure(with album: Album) {
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
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class ExpandedTargetButton: UIButton {
	final override func point(
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
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		accessibilityTraits.formUnion(.button)
	}
	
	final override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		freshenDotDotDotButton()
	}
	
	final func configureWith<
		AlertPresenter: CanPresentOpenMusicAlert
	>(
		song: Song,
		albumRepresentative representative: SongMetadatum?,
		spacerTrackNumberText: String?,
		alertPresenter: Weak<AlertPresenter>
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
		
		let menu: UIMenu?
		defer {
			dotDotDotButton.menu = menu
		}
		
		guard let mediaItem = song.mpMediaItem() else {
			menu = nil
			return
		}
		menu = UIMenu(
			presentsUpward: false,
			groupedElements: [
				[
					UIAction(
						title: LocalizedString.play,
						image: UIImage(systemName: "play")
					) { [weak self] _ in
						self?.player?.playNow([mediaItem])
					},
				],
				[
					UIAction(
						title: LocalizedString.playNext,
						image: UIImage(systemName: "text.insert")
					) { [weak self] _ in
						self?.player?.playNext([mediaItem])
						alertPresenter.referencee?.maybeAlertOpenMusic(
							willPlayNextAsOpposedToLast: true,
							havingVerbedSongCount: 1,
							firstSongTitle: songDisplayTitle)
					},
					UIAction(
						title: LocalizedString.playLast,
						image: UIImage(systemName: "text.append")
					) { [weak self] _ in
						self?.player?.playLast([mediaItem])
						alertPresenter.referencee?.maybeAlertOpenMusic(
							willPlayNextAsOpposedToLast: false,
							havingVerbedSongCount: 1,
							firstSongTitle: songDisplayTitle)
					},
				],
			])
	}
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	private func freshenDotDotDotButton() {
		dotDotDotButton.isEnabled = !isEditing
	}
	
	final override func layoutSubviews() {
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
