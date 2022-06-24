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
			let maxWidthAndHeight = coverArtView.bounds.width
			return album.coverArt(at: CGSize(
				width: maxWidthAndHeight,
				height: maxWidthAndHeight))
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
			if let albumArtist = album.albumArtistFormattedOptional() {
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
		
		if Enabling.songDotDotDot {
		} else {
			dotDotDotButton.removeFromSuperview()
			NSLayoutConstraint.activate([
				spacerSpeakerImageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
			])
		}
		
		accessibilityTraits.formUnion(.button)
	}
	
	final override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		freshenDotDotDotButton()
	}
	
	final func configureWith(
		song: Song,
		albumRepresentative representative: SongMetadatum?,
		spacerTrackNumberText: String?
	) {
		let metadatum = song.metadatum() // Can be `nil` if the user recently deleted the `SongMetadatum` from their library
		titleLabel.text = { () -> String in
			if let songTitle = metadatum?.titleOnDisk {
				return songTitle
			} else {
				return SongMetadatumPlaceholder.unknownTitle
			}
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
			let text: String? = {
				guard
					let metadatum = metadatum,
					let representative = representative
				else {
					return nil
				}
				if representative.shouldShowDiscNumber {
					return metadatum.discAndTrackNumberFormatted()
				} else {
					return metadatum.trackNumberFormattedOptional()
				}
			}()
			if let text = text {
				return text
			} else {
				return "‒" // Figure dash
			}
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
		
		guard Enabling.songDotDotDot else { return }
		
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
					) { _ in
						// ARC2DO
						self.player?.playNow([mediaItem])
					},
				],
				[
					UIAction(
						title: LocalizedString.playNext,
						image: UIImage(systemName: "text.insert")
					) { _ in
						// ARC2DO
						self.player?.playNext([mediaItem])
					},
					UIAction(
						title: LocalizedString.playLast,
						image: UIImage(systemName: "text.append")
					) { _ in
						// ARC2DO
						self.player?.playLast([mediaItem])
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
