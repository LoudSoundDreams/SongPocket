//
//  OptionsTVC - Views.swift
//  LavaRock
//
//  Created by h on 2021-10-09.
//

import UIKit
import StoreKit

final class AppearanceCell: UITableViewCell {
	@IBOutlet private var segmentedControl: UISegmentedControl!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		selectionStyle = .none
		
		(0 ..< segmentedControl.numberOfSegments).forEach { indexOfSegment in
			let appearance = Appearance(indexInDisplayOrder: indexOfSegment)
			segmentedControl.setImage(appearance.image(), forSegmentAt: indexOfSegment)
		}
		
		segmentedControl.addTarget(
			self,
			action: #selector(saveAndSetAppearance),
			for: .valueChanged)
		
		segmentedControl.selectedSegmentIndex = Appearance.savedPreference().indexInDisplayOrder()
	}
	
	@objc private func saveAndSetAppearance() {
		let selected = Appearance(
			indexInDisplayOrder: segmentedControl.selectedSegmentIndex)
		selected.saveAsPreference()
		window?.overrideUserInterfaceStyle = selected.uiUserInterfaceStyle()
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
		
		if accentColor == AccentColor.savedPreference() { // Don't use `self.tintColor`, because if Increase Contrast is enabled, it won't match any `AccentColor.uiColor`.
			accessoryType = .checkmark
		} else {
			accessoryType = .none
		}
		
		refreshSelectedBackgroundView()
	}
	
	// Similar to counterpart in `TintedSelectedCell`.
	private func refreshSelectedBackgroundView() {
		let colorView = UIView()
		colorView.backgroundColor = accentColor?.uiColor.resolvedColor(with: traitCollection).translucent() // For some reason, you must use `resolvedColor` here, or this won't reflect the "Increase Contrast" setting, even though the text does reflect the setting without it.
		selectedBackgroundView = colorView
	}
	
	// UIKit also calls this when the "Increase Contrast" setting changes.
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		configure()
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReloadCell: TintedSelectedCell {
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
extension TipReloadCell: ButtonCell {
	static let buttonText = LocalizedString.reload
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class TipReadyCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
		guard
			let tipProduct = PurchaseManager.shared.tipProduct,
			let tipPriceFormatter = PurchaseManager.shared.tipPriceFormatter
		else {
			contentConfiguration = defaultContentConfiguration()
			return
		}
		
		var configuration = UIListContentConfiguration.valueCell()
		configuration.text = tipProduct.localizedTitle
		configuration.textProperties.color = .tintColor_()
		configuration.secondaryText = tipPriceFormatter.string(from: tipProduct.price)
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) {
		} else {
			configure()
		}
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
