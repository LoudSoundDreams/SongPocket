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
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	static let usesUIKitAccessibility__ = true
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var secondaryLabel: UILabel!
	
	@IBOutlet private var textStackTopToCoverArtTop: NSLayoutConstraint!
	
	override func awakeFromNib() {
		tintSelectedBackgroundView()
		
		removeBackground()
		
		coverArtView.layer.cornerCurve = .continuous
		coverArtView.layer.cornerRadius = 3
	}
	
	func configure(with metadatum: SongMetadatum) {
		coverArtView.image = metadatum.coverArt(largerThanOrEqualToSizeInPoints: CGSize(
			width: coverArtView.frame.width,
			height: coverArtView.frame.height))
		
		// Don’t let these be `nil`.
		titleLabel.text = { () -> String in
			return metadatum.titleOnDisk ?? SongMetadatumPlaceholder.unknownTitle
		}()
		secondaryLabel.text = { () -> String in
			if let songArtist = metadatum.artistOnDisk {
				return songArtist
			} else {
				return LRString.unknownArtist
			}
		}()
		
		rowContentAccessibilityLabel__ = [
			titleLabel.text,
			secondaryLabel.text,
		].compactedAndFormattedAsNarrowList()
		
		if let font = titleLabel.font {
			// A `UIFont`’s `lineHeight` equals its `ascender` plus its `descender`.
			textStackTopToCoverArtTop.constant = -(font.ascender - font.capHeight)
		}
		
		if secondaryLabel.text == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = textStack.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension QueueCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
