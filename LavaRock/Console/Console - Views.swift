//
//  Console - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

// Similar to `AlbumCell` and `SongCell`.
final class QueueCell: UITableViewCell {
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var secondaryLabel: UILabel!
	
	override func awakeFromNib() {
		selectedBackgroundView_add_tint()
		
		backgroundColor_set_to_clear()
	}
	
	func configure(with metadatum: SongMetadatum) {
		coverArtView.image = metadatum.coverArt(largerThanOrEqualToSizeInPoints: CGSize(
			width: coverArtView.frame.width,
			height: coverArtView.frame.height))
		
		titleLabel.text = metadatum.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		secondaryLabel.text = { () -> String in
			if let songArtist = metadatum.artistOnDisk {
				return songArtist
			} else {
				return LRString.unknownArtist
			}
		}()
	}
}
