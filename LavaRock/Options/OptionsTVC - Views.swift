//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

final class LightingCell: UITableViewCell {
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class LightingChooser: UISegmentedControl {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		Lighting.allCases.forEach { lighting in
			insertSegment(
				action: UIAction(
					image: {
						let image = lighting.uiImage
						image.accessibilityLabel = lighting.name
						return image
					}()) { _ in
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

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AccentColorCell: UITableViewCell {
	final var representee: AccentColor? = nil {
		didSet {
			let new_contentConfiguration: UIContentConfiguration
			defer {
				contentConfiguration = new_contentConfiguration
			}
			
			guard let representee = representee else {
				new_contentConfiguration = defaultContentConfiguration()
				return
			}
			
			var content = UIListContentConfiguration.cell()
			content.text = representee.displayName // Freshen text
			content.textProperties.color = representee.uiColor // Freshen color
			new_contentConfiguration = content
			
			reflectTintColor()
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
	
	private func reflectTintColor() {
		let new_accessoryType: AccessoryType
		let new_selectedBackgroundView: UIView?
		defer {
			accessoryType = new_accessoryType
			selectedBackgroundView = new_selectedBackgroundView
		}
		
		// Freshen checkmark
		// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
		if representee == AccentColor.savedPreference() {
			new_accessoryType = .checkmark
		} else {
			new_accessoryType = .none
		}
		
		// Freshen `selectedBackgroundView`
		// Similar to in `CellTintingWhenSelected`, except we need to do this manually to reflect “Increase Contrast”.
		let colorView = UIView()
		// For some reason, to get this to respect “Increase Contrast”, you must use `resolvedColor`, even though you don’t need to for the text.
		colorView.backgroundColor = representee?.uiColor.resolvedColor(with: traitCollection).translucent()
		new_selectedBackgroundView = colorView
	}
	
	private lazy var previousAccessibilityContrast = traitCollection.accessibilityContrast
	// UIKit does call this when “Increase Contrast” changes.
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		reflectTintColor()
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading // We shouldn’t have to do this, but as of build 482, without this, if you close Options then open it again, something sets the left inset to 0.
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipLoadingCell: UITableViewCell {
	final override func awakeFromNib() {
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
	final override func awakeFromNib() {
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
	final override func awakeFromNib() {
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
	final override func awakeFromNib() {
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
	final override func awakeFromNib() {
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
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}
