//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

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
		
		freshenSelectedBackgroundView()
	}
	
	// Similar to counterpart in `TintedSelectedCell`, except we need to call this manually to reflect “Increase Contrast”.
	private func freshenSelectedBackgroundView() {
		let colorView = UIView()
		// For some reason, to get this to respect “Increase Contrast”, you must use `resolvedColor`, even though you don’t need to for the text.
		colorView.backgroundColor = accentColor?.uiColor.resolvedColor(with: traitCollection).translucent()
		selectedBackgroundView = colorView
	}
	
	// UIKit does call this when “Increase Contrast” changes.
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
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
final class TipReloadCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configureAsButton()
	}
}
extension TipReloadCell: CellConfiguredAsButton {
	static let buttonText = LocalizedString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		var configuration = UIListContentConfiguration.valueCell()
		configuration.text = PurchaseManager.shared.tipTitle
		configuration.textProperties.color = .tintColor
		configuration.secondaryText = PurchaseManager.shared.tipPrice
		contentConfiguration = configuration
	}
}

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
