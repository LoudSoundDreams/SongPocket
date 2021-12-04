//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import CoreData

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: LRTableCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		reflectAccentColor()
	}
}
extension AllowAccessCell: ButtonCell {
	static let buttonText = LocalizedString.allowAccessToMusic
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class LoadingCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.loadingEllipsis
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
		
		isUserInteractionEnabled = false
		let spinnerView = UIActivityIndicatorView()
		spinnerView.startAnimating()
		spinnerView.sizeToFit() // Without this line of code, UIKit centers the UIActivityIndicatorView at the top-left corner of the cell.
		accessoryView = spinnerView
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class NoCollectionsPlaceholderCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.emptyDatabasePlaceholder
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
		
		isUserInteractionEnabled = false
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class OpenMusicCell: LRTableCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		reflectAccentColor()
	}
	
	final func didSelect() {
		URL.music?.open()
	}
}
extension OpenMusicCell: ButtonCell {
	static let buttonText = LocalizedString.openMusic
}

final class CreateCollectionCell: LRTableCell {
	@IBOutlet private var newCollectionLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
		newCollectionLabel.textColor = .tintColor_()
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) {
		} else {
			configure()
		}
	}
}

final class CollectionCell: LRTableCell {
	enum Mode {
		case normal
		case modal
		case modalTinted
		
		
		case modalDisabled
	}
	
	/*
	private static let defaultBackgroundView: UIView = {
		let view = UIView()
		view.backgroundColor = .systemBackground
//		view.alpha = 0.01
		var float1: CGFloat = 0
		var float2: CGFloat = 0
		var float3: CGFloat = 0
		var float4: CGFloat = 0
		if view.backgroundColor!.getHue(&float1, saturation: &float2, brightness: &float3, alpha: &float4) {
			print(float1)
			print(float2)
			print(float3)
			print(float4)
		}
		print("defaultBackgroundView has alpha: \(view.alpha)")
		return view
	}()
	*/
	
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final func configure(
		with collection: Collection,
		mode: Mode,
		renameFocusedCollectionAction: UIAccessibilityCustomAction
	) {
		// Title
		let collectionTitle = collection.title
		
		titleLabel.text = collectionTitle
		
		switch mode {
		case .normal:
			accessibilityCustomActions = [renameFocusedCollectionAction]
			/*
			backgroundView = Self.defaultBackgroundView
			backgroundView?.alpha = 0.01
			var float1: CGFloat = 0
			var float2: CGFloat = 0
			var float3: CGFloat = 0
			var float4: CGFloat = 0
			print("")
			if backgroundView!.backgroundColor!.getHue(&float1, saturation: &float2, brightness: &float3, alpha: &float4) {
				print(float1)
				print(float2)
				print(float3)
				print(float4)
			}
			print("_defaultBackgroundView has alpha: \(backgroundView?.alpha)")
			if
				let contentBackgroundColor = contentView.backgroundColor,
				contentBackgroundColor.getHue(&float1, saturation: &float2, brightness: &float3, alpha: &float4)
			{
				print(float1)
				print(float2)
				print(float3)
				print(float4)
			}
			*/
			backgroundView = nil // Use this to reset `backgroundColor`, not `backgroundColor = nil`, because that makes the cell transparent.
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modal:
			accessibilityCustomActions = []
//			backgroundView = Self.defaultBackgroundView
//			backgroundView?.alpha = 0.01
			backgroundView = nil
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modalTinted:
			accessibilityCustomActions = []
			backgroundColor = .tintColor_().translucentFaint()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
			
			
		case .modalDisabled:
			accessibilityCustomActions = []
//			backgroundView = Self.defaultBackgroundView
//			backgroundView?.alpha = 0.01
			backgroundView = nil
			
			titleLabel.textColor = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
			disableWithAccessibilityTrait()
		}
	}
}

extension CollectionCell: NowPlayingIndicating {
}
