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

final class AlbumInfoCell__withWholeAlbumButtons: UITableViewCell {
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var albumArtistLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	@IBOutlet var playAlbumButton: UIButton! // TO DO: Add accessibility label
	@IBOutlet var shuffleAlbumButton: UIButton! // TO DO: Add accessibility label
	
	final var album: Album? = nil {
		didSet {
			guard let album = album else {
				playAlbumButton.isEnabled = false
				shuffleAlbumButton.isEnabled = false
				return
			}
			
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
			
			playAlbumButton.isEnabled = true
			shuffleAlbumButton.isEnabled = (album.contents?.count ?? 0) >= 2
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		playAlbumButton.maximumContentSizeCategory = .extraExtraExtraLarge
		shuffleAlbumButton.maximumContentSizeCategory = .extraExtraExtraLarge
		
		accessibilityUserInputLabels = [""]
	}
	
	@IBAction func playAlbum(_ sender: UIButton) {
		guard
			let album = album,
			let player = Player.shared.player
		else { return }
		
		if Enabling.playerScreen {
			SongQueue.set(
				songs: album.songs(sorted: true),
				thenApplyTo: player)
		} else {
			player.setQueue(with: album.songs(sorted: true))
		}
		
		player.repeatMode = .none
		player.shuffleMode = .off
		
		player.play()
	}
	
	@IBAction func shuffleAlbum(_ sender: UIButton) {
		guard
			let album = album,
			let player = Player.shared.player
		else { return }
		
		if Enabling.playerScreen {
			SongQueue.set(
				songs: album.songs(sorted: true)
					.inAnyOtherOrder(),
				thenApplyTo: player)
		} else {
			player.setQueue(
				with: album.songs(sorted: true)
					.inAnyOtherOrder())
		}
		
		player.repeatMode = .none
		player.shuffleMode = .off
		
		player.play()
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
}

final class SongCell:
	TintedSelectedCell,
	CellHavingTransparentBackground
{
	// `NowPlayingIndicating`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		setTransparentBackground()
		
		numberLabel.font = .bodyWithMonospacedDigits(compatibleWith: traitCollection)
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		metadatum: SongMetadatum?,
		albumRepresentative representative: SongMetadatum?
	) {
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
	}
}
extension SongCell: NowPlayingIndicating {}
