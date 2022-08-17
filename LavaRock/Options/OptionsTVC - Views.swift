//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

final class LightingCell: UITableViewCell {
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class AvatarCell: UITableViewCell {
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class LightingChooser: UISegmentedControl {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		Lighting.allCases.forEach { lighting in
			insertSegment(
				action: UIAction(
					image: {
						let image = lighting.uiImage
						image.accessibilityLabel = lighting.name
						return image
					}()
				) { _ in
					Task { await MainActor.run {
						Theme.shared.lighting = lighting
					}}
				},
				at: numberOfSegments,
				animated: false)
		}
		selectedSegmentIndex = Lighting.savedPreference().indexInDisplayOrder
	}
}

final class AvatarChooser: UISegmentedControl {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		Avatar.all.forEach { avatar in
			insertSegment(
				action: UIAction(
					image: {
						let image = UIImage(systemName: avatar.playingImageName)
						image?.accessibilityLabel = nil // TO DO
						return image
					}()
				) { _ in
					Avatar.current = avatar
					// TO DO: Save
					NotificationCenter.default.post(
						name: .userChangedAvatar,
						object: nil)
				},
				at: numberOfSegments,
				animated: false)
		}
		selectedSegmentIndex = 0 // TO DO: Load
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	var representee: AccentColor? = nil {
		didSet {
			freshen_contentConfiguration()
			freshen_accessoryType_and_selectedBackgroundView()
		}
	}
	
	private func freshen_contentConfiguration() {
		let new_contentConfiguration: UIContentConfiguration
		defer {
			contentConfiguration = new_contentConfiguration
		}
		
		guard let representee = representee else {
			new_contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var content = UIListContentConfiguration.cell()
		// Text
		content.text = representee.displayName
		// Text color
		content.textProperties.color = representee.uiColor
		new_contentConfiguration = content
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
	
	private func freshen_accessoryType_and_selectedBackgroundView() {
		let new_accessoryType: AccessoryType
		let new_selectedBackgroundView: UIView?
		defer {
			accessoryType = new_accessoryType
			selectedBackgroundView = new_selectedBackgroundView
		}
		
		// Checkmark
		// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
		if representee == AccentColor.savedPreference() {
			new_accessoryType = .checkmark
		} else {
			new_accessoryType = .none
		}
		
		// `selectedBackgroundView`
		// Similar to in `CellTintingWhenSelected`, except we need to do this manually to reflect “Increase Contrast”.
		let colorView = UIView()
		// For some reason, to get this to respect “Increase Contrast”, you must use `resolvedColor`, even though you don’t need to for the text.
		colorView.backgroundColor = representee?.uiColor
			.resolvedColor(with: traitCollection)
			.translucent()
		new_selectedBackgroundView = colorView
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		freshen_accessoryType_and_selectedBackgroundView()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading // We shouldn’t have to do this, but as of build 482, without this, if you close Options then open it again, something sets the left inset to 0.
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipLoadingCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var content = UIListContentConfiguration.cell()
		content.text = LRString.loadingEllipsis
		content.textProperties.color = .secondaryLabel
		contentConfiguration = content
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
}
extension TipReloadCell: CellTintingWhenSelected {}
extension TipReloadCell: CellConfigurableAsButton {
	static let buttonText = LRString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		accessibilityTraits.formUnion(.button)
		
		var content = UIListContentConfiguration.valueCell()
		content.text = PurchaseManager.shared.tipTitle
		content.textProperties.color = .tintColor
		content.secondaryText = PurchaseManager.shared.tipPrice
		contentConfiguration = content
	}
}
extension TipReadyCell: CellTintingWhenSelected {}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipConfirmingCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var content = UIListContentConfiguration.cell()
		content.text = LRString.confirmingEllipsis
		content.textProperties.color = .secondaryLabel
		contentConfiguration = content
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipThankYouCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		isUserInteractionEnabled = false
		
		configure()
	}
	
	private func configure() {
		var content = UIListContentConfiguration.cell()
		content.text = AccentColor.savedPreference().thankYouMessage()
		content.textProperties.color = .secondaryLabel
		content.textProperties.alignment = .center
		contentConfiguration = content
	}
	
	override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}
