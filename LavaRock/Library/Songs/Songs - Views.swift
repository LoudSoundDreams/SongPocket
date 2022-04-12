//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer
import OSLog

final class AlbumArtworkCell: UITableViewCell {
	@IBOutlet private var artworkImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
		accessibilityLabel = LocalizedString.albumArtwork
		accessibilityUserInputLabels = [""]
		accessibilityTraits.formUnion(.image)
	}
	
	final func configure(with album: Album) {
		// Artwork
		os_signpost(.begin, log: .songsView, name: "Draw artwork image")
		let artworkImage = album.artworkImage(
			at: CGSize(
				width: UIScreen.main.bounds.width,
				height: UIScreen.main.bounds.width))
		os_signpost(.end, log: .songsView, name: "Draw artwork image")
		
		os_signpost(.begin, log: .songsView, name: "Set artwork image")
		artworkImageView.image = artworkImage
		os_signpost(.end, log: .songsView, name: "Set artwork image")
	}
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var albumArtistLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityUserInputLabels = [""]
	}
	
	final func configure(with album: Album) {
		albumArtistLabel.text = { () -> String in // Don’t let this be `nil`.
			return album.albumArtistFormattedOrPlaceholder()
		}()
		releaseDateLabel.text = album.releaseDateEstimateFormatted() // Can be `nil`
		
		if releaseDateLabel.text == nil {
			// We couldn’t determine the album’s release date.
			textStack.spacing = 0
		} else {
			textStack.spacing = UIStackView.spacingUseSystem
		}
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = {
			return directionalLayoutMargins.leading
		}()
		separatorInset.right = {
			return directionalLayoutMargins.trailing
		}()
	}
}

final class SongCell: UITableViewCell {
	// `NowPlayingIndicating`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var dotDotDotButton: UIButton!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		if Enabling.songDotDotDot {
		} else {
			dotDotDotButton.removeFromSuperview()
			NSLayoutConstraint.activate([
				spacerSpeakerImageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
			])
		}
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		song: Song?,
		albumRepresentative representative: SongMetadatum?
	) {
		let metadatum = song?.metadatum()
		titleLabel.text = metadatum?.titleOnDisk ?? SongMetadatumExtras.unknownTitlePlaceholder
		artistLabel.text = {
			let albumArtist = representative?.albumArtistOnDisk // Can be `nil`
			if
				let songArtist = metadatum?.artistOnDisk,
				songArtist != albumArtist
			{
				return songArtist
			} else {
				return nil
			}}()
		numberLabel.text = { () -> String in // Don’t let this be `nil`.
			guard
				let metadatum = metadatum,
				let representative = representative
			else {
				return SongMetadatumExtras.unknownTrackNumberPlaceholder
			}
			
			let discNumber = representative.discNumberOnDisk
			let discCount = representative.discCountOnDisk
			// Show disc numbers if the disc count is more than 1, or if the disc count isn’t more than 1 but the disc number is.
			let shouldShowDiscNumber = (discCount > 1) ? true : (discNumber > 1)
			
			if shouldShowDiscNumber {
				return metadatum.discAndTrackNumberFormatted()
			} else {
				return metadatum.trackNumberFormatted()
			}}()
		
		if artistLabel.text == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
		
		accessibilityUserInputLabels = [metadatum?.titleOnDisk].compactMap { $0 }
		
		guard Enabling.songDotDotDot else { return }
		guard let song = song else {
			// TO DO: Prevent the button from highlighting itself when you touch it
			dotDotDotButton.tintColor = .placeholderText
			dotDotDotButton.menu = nil
			return
		}
		dotDotDotButton.tintColor = .label
		dotDotDotButton.menu = UIMenu(
			presentsUpward: false,
			groupedElements: [
				[
					// TO DO: Disable these if there are no songs below.
					UIAction(
						title: LocalizedString.playSongAndBelowNext,
						image: UIImage(systemName: "text.insert")
					) { _ in
						// ARC2DO
						PlayerWatcher.shared.player?.playNext([song]) // TO DO
					},
					UIAction(
						title: LocalizedString.playSongAndBelowLater,
						image: UIImage(systemName: "text.append")
					) { _ in
						// ARC2DO
						PlayerWatcher.shared.player?.playLast([song]) // TO DO
					},
				],
				[
					UIAction(
						title: LocalizedString.play,
						image: UIImage(systemName: "play") // TO DO: Reconsider
					) { _ in
						// ARC2DO
						PlayerWatcher.shared.player?.playNow([song])
					},
					UIAction(
						title: LocalizedString.playNext,
						image: UIImage(systemName: "arrow.turn.up.right")
					) { _ in
						// ARC2DO
						PlayerWatcher.shared.player?.playNext([song])
					},
					UIAction(
						title: LocalizedString.playLater,
						image: UIImage(systemName: "arrow.turn.down.right")
					) { _ in
						// ARC2DO
						PlayerWatcher.shared.player?.playLast([song])
					},
				],
			])
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = {
			return 0
			+ contentView.frame.minX
			+ textStack.frame.minX
		}()
		separatorInset.right = {
			if isEditing {
				return 0
			} else {
				return 0
				+ contentView.directionalLayoutMargins.trailing // Non-editing mode: 16. Editing mode: 8.
				+ frame.maxX - contentView.frame.maxX
			}
		}()
	}
}
extension SongCell:
	NowPlayingIndicating,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
