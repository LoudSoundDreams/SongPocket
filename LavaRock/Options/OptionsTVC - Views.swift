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
	final var accentColor: AccentColor? = nil {
		didSet {
			configure()
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(userDidChangeAccentColor),
			name: .LRUserChangedAccentColor,
			object: nil)
	}
	@objc private func userDidChangeAccentColor() {
		// Don’t do this during `tintColorDidChange`, because that can break the animation when the table view deselects the row.
		configure()
	}
	
	private func configure() {
		guard let accentColor = accentColor else {
			contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = accentColor.displayName
		configuration.textProperties.color = accentColor.uiColor
		contentConfiguration = configuration
		
		// Don’t compare `self.tintColor`, because if “Increase Contrast” is enabled, it won’t match any `AccentColor.uiColor`.
		if accentColor == AccentColor.savedPreference() {
			accessoryType = .checkmark
		} else {
			accessoryType = .none
		}
		
	// Freshen `selectedBackgroundView`
	// Similar to in `CellTintingWhenSelected`, except we need to do this manually to reflect “Increase Contrast”.
		let colorView = UIView()
		// For some reason, to get this to respect “Increase Contrast”, you must use `resolvedColor`, even though you don’t need to for the text.
		colorView.backgroundColor = accentColor.uiColor.resolvedColor(with: traitCollection).translucent()
		selectedBackgroundView = colorView
	}
	
	private lazy var previousAccessibilityContrast = traitCollection.accessibilityContrast
	// UIKit does call this when “Increase Contrast” changes.
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if previousAccessibilityContrast != traitCollection.accessibilityContrast {
			previousAccessibilityContrast = traitCollection.accessibilityContrast
			configure()
		}
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
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.loadingEllipsis
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
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
	static let buttonText = LocalizedString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		accessibilityTraits.formUnion(.button)
		
		var configuration = UIListContentConfiguration.valueCell()
		configuration.text = PurchaseManager.shared.tipTitle
		configuration.textProperties.color = .tintColor
		configuration.secondaryText = PurchaseManager.shared.tipPrice
		contentConfiguration = configuration
	}
}
extension TipReadyCell: CellTintingWhenSelected {}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipConfirmingCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		disableWithAccessibilityTrait()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.confirmingEllipsis
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
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
		var configuration = UIListContentConfiguration.cell()
		let heartEmoji = AccentColor.savedPreference().heartEmoji
		let thankYouMessage = heartEmoji + LocalizedString.tipThankYouMessageWithPaddingSpaces + heartEmoji
		configuration.text = thankYouMessage
		configuration.textProperties.color = .secondaryLabel
		configuration.textProperties.alignment = .center
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}
